"""v1.69 offline structural regression checks. Run: python tests/validate_v169.py <project-root>."""
from __future__ import annotations
import json, re, sys, hashlib
from pathlib import Path
from PIL import Image

root=Path(sys.argv[1]) if len(sys.argv)>1 else Path(__file__).resolve().parents[1]
assert (root/'scripts/player.gd').exists()
animations=json.loads((root/'resources/ghost_extra_animations.json').read_text())
names=[e.get('name') for e in animations]
checks=[]

def check(condition,msg):
    assert condition, msg
    checks.append(msg)

for sty in ('dagger','spear'):
    for mode in ('idle','walk','light','heavy'):
        for face in ('front','back','left','right'):
            key=f'{sty}_{mode}_{face}' if mode in ('idle','walk') else f'attack_{sty}_{mode}_{face}'
            check(key in names, 'animation '+key)
            entry=next(e for e in animations if e.get('name')==key)
            check(entry.get('frame_count')==8, 'eight frames '+key)
            target=root/entry['atlas']
            check(target.exists(), 'atlas '+entry['atlas'])
    for t in ('locomotion','combat'):
        with Image.open(root/f'assets/equipment/weapons_v169/{sty}_{t}_2048x1760.png') as im:
            check(im.size==(2048,1760),sty+' '+t+' atlas size')
            check('A' in im.mode,sty+' '+t+' alpha')
            check(im.getchannel('A').getbbox() is not None,sty+' '+t+' nonempty')
    check((root/f'items/{"roseglass_dagger_v169" if sty=="dagger" else "moonwarden_spear_v169"}.tres').exists(),sty+' resource')
    check((root/f'assets/ui/weapons_v169/{sty}.png').exists(),sty+' icon')

source=(root/'scripts/player.gd').read_text()
check('"dagger"' in source and '"spear"' in source,'new melee styles wired')
check('"dagger":\n\t\t\treach' in source and '"spear":\n\t\t\treach' in source,'reach tuned')
check('"dagger":\n\t\t\tattack_duration' in source and '"spear":\n\t\t\tattack_duration' in source,'attack timing tuned')
check('"dagger", "spear"' in source,'new animation family selected')
check('DODGE_DURATION: float = 0.33' in source,'dodge unaffected')
check('const BOW_FULL_DRAW_TIME: float = 0.46' in source,'bow charge unaffected')

fx=(root/'scripts/weapon_prestige_fx.gd').read_text()
check('new_weapon_axes_by_animation' in fx,'new axes routing')
check('center + normal * 5.0' in fx,'string glow moved behind limb')
check('draw_line(string_a, string_b' in fx,'continuous string highlight')
check('var start: Vector2 = grip.lerp(tip, 0.10) + normal * 5.0' in fx,'mythic string offset')
check('bow_string_colors: Array[Color]' in fx,'independent seeded string colors preserved')

bow=(root/'scripts/bow_palette_overlay_v139.gd').read_text()
check('get_node_or_null("BowCarryV166")' in bow,'v1.68.1 missing-node hotfix retained')
check('return false\n\nfunc _carry_transform_for_animation' in bow,'no left-side overlay mirroring')
check('var carrying: bool = false' in bow,'no double bow art on locomotion')
for sty in ('thornrose','moonveil'):
    for family in ('bows_v126','bows_v139'):
        basename=f'{sty}_locomotion_2048x1760.png' if family=='bows_v126' else f'{sty}_locomotion_mask_2048x1760.png'
        with Image.open(root/f'assets/ghost/{family}/{basename}') as im:
            check(im.size==(2048,1760),'left atlas '+family+' '+sty)
            check(im.crop((0,2*220,256,3*220)).getbbox() is not None,'left idle '+sty+' '+family)

axes=json.loads((root/'resources/new_weapon_axes_v169.json').read_text())
for sty in ('dagger','spear'):
    check(len([k for k in axes if k.startswith(sty+'_') or k.startswith('attack_'+sty+'_')])==16,sty+' axis groups')
    for key,points in axes.items():
        check(len(points)==8 and all(len(p)==4 for p in points),key+' guides')

for file in ('roseglass_dagger_v169.tres','moonwarden_spear_v169.tres'):
    item=(root/'items'/file).read_text()
    check('equip_slot = "sword"' in item,'equippable '+file)
    for asset in re.findall(r'path="res://([^\"]+)"',item):
        check((root/asset).exists(),'resource resolved '+asset)

lib=(root/'scripts/game.gd').read_text()
check('preload("res://items/roseglass_dagger_v169.tres")' in lib,'dagger in drop table')
check('preload("res://items/moonwarden_spear_v169.tres")' in lib,'spear in drop table')

print(f'v1.69 passed {len(checks)} offline checks')
