"""v1.30 enemy texture atlases + spell/hook reliquaries. Static validation.
Run Godot's parser and gameplay separately before calling a release playtested.
"""
from pathlib import Path
from PIL import Image
import json, re, hashlib
R=Path(__file__).resolve().parents[1]
BASE=R.parent/'GhostGirl_v129_work'
issues=[]
def check(cond,message):
    if not cond: issues.append(message)
def read(rel):
    path=R/rel
    check(path.is_file(),'missing '+rel)
    return path.read_text('utf-8') if path.is_file() else ''

scene=read('scenes/rooms/hollow_veil_moor.tscn')
script=read('scripts/triune_reliquary_v130.gd')
enemy=read('scripts/moor_creature_v129.gd')
moonfall=read('scripts/moonfall_blizzard.gd')
grasping=read('scripts/grasping_roses_v127.gd')
hook=read('scripts/rose_hook.gd')
game=read('scripts/game.gd')

for family in ('hush_moth','gloom_lantern'):
    path=R/'assets/enemies'/f'{family}_v130_4frames.png'
    check(path.exists(), 'missing animated enemy artwork '+family)
    if path.exists():
        with Image.open(path) as atlas:
            check(atlas.size==(1024,256), family+' wrong atlas geometry')
            check(atlas.mode=='RGBA',family+' missing alpha')
            for i in range(4):
                cell=atlas.crop((i*256,0,(i+1)*256,256))
                check(cell.getchannel('A').getbbox() is not None, f'{family} frame {i} blank')
for token in ('const MOTH_ATLAS:', 'const LANTERN_ATLAS:', 'draw_texture_rect_region(atlas, sprite_rect,', 'if slow_left > 0.0:', 'if windup > 0.0:'):
    check(token in enemy, 'enemy animation / feedback token missing '+token)
for token in ('func hit(', 'func apply_frost_slow(', 'func on_hook_yank('):
    check(token in enemy, 'enemy interaction removed '+token)
check(enemy.count('girl.call("receive_damage",') == 1,'enemy damage path duplicated')

ex=re.findall(r'^\[ext_resource[^\]]+path="res://([^"]+)"[^\]]*id="([^"]+)"\]',scene,re.M)
subs=re.findall(r'^\[sub_resource[^\]]*id="([^"]+)"\]',scene,re.M)
load=re.search(r'^\[gd_scene load_steps=(\d+)',scene,re.M)
check(load is not None, 'invalid .tscn header')
if load: check(int(load.group(1)) == len(ex)+len(subs)+1, 'scene load_steps not exact')
check(len(set(e[1] for e in ex))==len(ex), 'duplicate ext ids')
for rel,ref in ex: check((R/rel).exists(),f'missing ext resource {ref}: {rel}')
check(not re.search(r'^\s*#',scene,re.M), '# comments are invalid in .tscn')

for suffix in ('West','East'):
    relay=f'V130{suffix}Triune';gate=relay+'Gate';chest=relay+'Chest';way=relay+'Waystone'
    for name in (relay,gate,chest,way):
        check(f'name="{name}"' in scene, f'missing room node {name}')
    check(f'gate_path = NodePath("../../{gate}")' in scene,f'{relay} gate link invalid')
    check(f'chest_path = NodePath("../TreasureChests/{chest}")' in scene,f'{gate} chest link invalid')
    check(f'position = Vector2(4100, 2200)' in scene if suffix=='West' else f'position = Vector2(8700, 4550)' in scene, f'{relay} outside intended optional route')
    check(f'"v130_{suffix.lower()}_triune_chest"' in scene, f'{chest} persistence ID missing')
check(scene.count('script = ExtResource("v130_triune")')==2,'expected two triune relays')
check(scene.count('script = ExtResource("v117_gate")')>=4,'existing gates lost')
check('script = ExtResource("v130_triune")' in scene and 'id="v130_triune"' in scene,'new script not linked')

for token in ('add_to_group("hook_switch")','add_to_group("rose_bloom_relay")','add_to_group("v130_triune_relay")','func on_hook_latched()', 'func on_grasping_roses()', 'func on_moonfall()', 'func restore_secret(', 'discovery_id + "_" + suffix','inventory.call("save_game")', 'gate.call("set_open", activated)'):
    check(token in script, 'three-stage persistence/interaction missing '+token)
check('"Gameplay/HookAnchors"' in game and 'restore_secret' in game,'room will not restore triune progress')
check('get_nodes_in_group("rose_bloom_relay")' in grasping,'T spell cannot activate triune mechanism')
check('get_nodes_in_group("hook_switch")' in hook, 'F hook cannot target triune mechanism')
check('get_nodes_in_group("v130_triune_relay")' in moonfall and 'relay.call("on_moonfall")' in moonfall, 'Z spell cannot freeze triune mechanism')
check(moonfall.count('enemy.call("hit", damage_per_pulse, 0.45)') == 1, 'Moonfall damage path changed')
check('user://ghost_girl_treasures_v2.json' in read('scripts/inventory.gd'), 'existing save path changed')
for rel in ['resources/ghost_extra_animations.json','resources/weapon_layer_manifest.json','scripts/player.gd','scripts/bow_arrow_v126.gd','assets/world/hollow_veil_moor_v118.jpg']:
    if (BASE/rel).is_file():
        check(hashlib.sha256((BASE/rel).read_bytes()).digest()==hashlib.sha256((R/rel).read_bytes()).digest(),'unexpected approved source change '+rel)

report={'version':'1.30','status':'PASS' if not issues else 'FAIL','new_animated_enemy_families':2,'enemy_frames':8,'optional_triune_reliquaries':2,'placed_moor_enemies':len(re.findall(r'^\[node name="[^"]+" parent="Gameplay/Enemies" instance=',scene,re.M)), 'runtime_godot_tested':False,'issues':issues}
print(json.dumps(report,indent=2))
if issues: raise SystemExit(1)
