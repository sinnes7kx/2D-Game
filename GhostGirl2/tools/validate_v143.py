from pathlib import Path
from PIL import Image
import re, json
root=Path(__file__).resolve().parents[1]
refs=0; missing=[]
for file in list(root.glob('scenes/**/*.tscn'))+list(root.glob('resources/**/*.tres'))+list(root.glob('scripts/**/*.gd')):
    src=file.read_text(errors='ignore')
    for name in set(re.findall(r'res://([\w./()\- ]+\.(?:gdshader|tscn|tres|png|wav|jpg|ogg|mp3|json|webp|shader|gd))',src)):
        refs+=1
        if not (root/name).exists():missing.append((file.relative_to(root),name))
assert not missing,missing[:15]
extra=json.loads((root/'resources/ghost_extra_animations.json').read_text())
assert len(set(x['name'] for x in extra))==len(extra)
assert len(extra)>=54
names={x['name'] for x in extra}
for kind in ['attack_sword_light','attack_sword_heavy','attack_unarmed_light','attack_unarmed_heavy','sword_idle','sword_walk']:
    for dir in ['front','back','left','right']:
        name=f'{kind}_{dir}'
        assert name in names,name
        record=next(x for x in extra if x['name']==name)
        assert len(record['textures'])==8,(name,len(record['textures']))
        for p in record['textures']:
            tex=root/p
            assert tex.exists(),tex
            im=Image.open(tex)
            assert im.size==(256,220),(tex,im.size)
            assert im.mode=='RGBA',p
for p in (root/'art_sources/combat_v143').glob('*.png'):
    assert Image.open(p).size==(2048,1760),p
for s in ['hud.gd','inventory.gd','inventory_grid.gd','inventory_panel.gd','game.gd','world_drop.gd']:
    assert (root/'scripts'/s).exists()
assert 'ghost_girl_treasures_v2.json' in (root/'scripts/inventory.gd').read_text()
assert 'ghost_girl_ground_loot_v1.json' in (root/'scripts/game.gd').read_text()
assert (root/'scenes/hud.tscn').read_text().count('[node name="HeldTreasure"')==1
assert (root/'scenes/inventory_panel.tscn').read_text().count('[node name="DropSelected"')==1
print('PASS: references:',refs,'missing:',len(missing),'extra tracks:',len(extra),'atlas dimensions OK')
print('NOTE: Godot GDScript parsing and gameplay require the Godot editor.')
