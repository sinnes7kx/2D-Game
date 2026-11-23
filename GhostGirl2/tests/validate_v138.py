"""Ghost Girl v1.38 offline integration checks; DOES NOT substitute for F5."""
from pathlib import Path
from PIL import Image
import json, re, sys
R = Path(__file__).resolve().parents[1]
errors=[]
def check(cond,msg):
    if not cond: errors.append(msg)
def read(rel):
    p=R/rel
    check(p.is_file(),f'file missing: {rel}')
    return p.read_text(encoding='utf-8') if p.is_file() else ''

lib=read('scripts/bow_imprints_v138.gd')
item=read('scripts/item_instance.gd')
inv=read('scripts/inventory.gd')
gen=read('scripts/item_generator.gd')
arrow=read('scripts/bow_arrow_v126.gd')
player=read('scripts/player.gd')
game=read('scripts/game.gd')
scene=read('scenes/rooms/hollow_veil_moor.tscn')
crypt=read('scenes/rooms/moonwake_crypt.tscn')
for val in ('Emberfire','Frostglass','Luminous','Triune Echo','glow','detail','trail'):
    check(val in lib, f'imprint library missing {val}')
for field in ('bow_element_index','bow_formation_index','bow_glow_index','bow_trail_index','bow_detail_index'):
    check(('var '+field+': int') in item, f'missing item property {field}')
    check(('"'+field+'": item.'+field) in inv, f'not saving {field}')
    check(('saved.get("'+field+'", item.'+field+')') in inv, f'not migrating {field}')
    check(('item.'+field+' = ') in gen, f'not rolling new item {field}')
check('func bow_rolls()' in item and 'func bow_effect_description()' in item,'item bow UI methods missing')
check('arrow.set("element_index"' in player and 'arrow.set("formation_index"' in player,'player not forwarding bow layers')
check('func _check_elemental_targets' in arrow and 'on_elemental_arrow_hit' in arrow,'arrow puzzle ray missing')
check('element_index == 2' in arrow and 'apply_frost_slow' in arrow,'ice arrows missing slow')
check(arrow.count('target.call("hit", damage,') == 1,'unexpected arrow damage paths')
check('formation_index == 1' in arrow and 'func _draw_arrow_shaft' in arrow,'cosmetic triple shaft missing')
check('_check_elemental_targets(start, end)' in arrow and 'var end: Vector2 = wall.get(' in arrow,'target should use wall-limited segment')
check('on_elemental_arrow_hit' in read('scripts/elemental_bow_target_v138.gd'), 'no puzzle callback')
check('restore_from_inventory' in read('scripts/elemental_bow_vault_v138.gd'), 'bow vault restore missing')
check('Gameplay/V138BowRiddles' in game and 'Gameplay/V138FletcherShowcase' in game, 'room not restoring additions')
for flag in ('v138_ember_ignited','v138_frost_illuminated','v138_light_awakened','v138_threefold_answer'):
    check(flag in scene,f'moor rune {flag} missing')
check(scene.count('required_arrow = ')==4,'must have four placed runes')
check(scene.count('script = ExtResource("v138_vault")')==2,'missing two reward seals')
check(scene.count('chest_id = "v138_')==2,'missing two reward chests')
check(crypt.count('parent="Gameplay/V138FletcherShowcase"')==4,'missing test bows')
# Simulate seed arithmetic used by script; test samples guarantee each ability.
seeds={'fire':(138204,'rare'),'ice':(138205,'rare'),'light':(138210,'rare'),'triple':(138203,'unique')}
for kind,(seed,quality) in seeds.items():
    elem=(seed*17+138041)%4
    form=1 if (seed*29+138053)%3==0 else 0
    check((elem=={'fire':1,'ice':2,'light':3}.get(kind,elem)) if kind!='triple' else form==1,f'wrong sample bow seed: {kind}')
# Every referenced scene resource resolves to a file.
for fn,text in [('hollow_veil_moor.tscn',scene),('moonwake_crypt.tscn',crypt)]:
    for res in re.findall(r'\[ext_resource[^\n]*path="(res://[^"]+)"',text):
        check((R/res.removeprefix('res://')).is_file(),f'broken resource {fn}: {res}')
    defined=set(re.findall(r'\[ext_resource[^\n]*id="([^"]+)"',text))
    for ref in re.findall(r'ExtResource\("([^"]+)"\)',text):
        check(ref in defined,f'undefined ext resource {ref} in {fn}')
    node_names=[]
    for name,parent in re.findall(r'\[node name="([^"]+)"[^\n]*parent="([^"]+)"',text):
        if parent!='.':
            check(parent in node_names or parent.startswith('..'),f'unknown parent {parent} for {name} in {fn}')
            node_names.append(parent+'/'+name if not parent.startswith('..') else name)
        else:node_names.append(name)
    for line in text.splitlines():
        check(not line.lstrip().startswith('#'),'invalid # comment in tscn')
# 2 new atlases, 16 new attack refs, and untouched locomotion frame ordering.
manifest=json.loads(read('resources/bow_animations_v126.json'))
attack=[e for e in manifest if e['name'].startswith('attack_')]
locomotion=[e for e in manifest if not e['name'].startswith('attack_')]
check(len(attack)==16 and len(locomotion)==16,'expected 16 attack and 16 locomotion tracks')
check(all('bows_v138' in e['atlas'] for e in attack),'not all attack tracks use polished atlas')
check(all('bows_v126' in e['atlas'] for e in locomotion),'locomotion frames unexpectedly changed')
count=0
for style in ('thornrose','moonveil'):
    p=R/f'assets/ghost/bows_v138/{style}_combat_2048x1760.png'
    check(p.is_file(), f'missing {p.name}')
    if p.is_file():
        with Image.open(p) as im:
            check(im.size==(2048,1760),f'invalid {p.name} size')
            rgba=im.convert('RGBA')
            for row in range(8):
                for col in range(8):
                    fr=rgba.crop((col*256,row*220,(col+1)*256,(row+1)*220))
                    check(fr.getbbox() is not None, f'empty frame {style}/{row}/{col}')
                    count+=1
# Existing named saves / damage model must not be replaced.
check('user://ghost_girl_treasures_v2.json' in inv, 'save file path changed')
check('1.65 if charged else 1.0' in player,'charged bow damage altered')
result={'version':'v1.38','status':'PASS' if not errors else 'FAIL','bow_combat_frames':count,'rune_targets':4,'puzzle_vaults':2,'errors':errors}
print(json.dumps(result,indent=2))
if errors:sys.exit(1)
