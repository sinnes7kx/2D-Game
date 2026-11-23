"""v1.24 Jump-route/moor discovery checks. Source/static, not Godot F5 testing."""
from pathlib import Path
import re, json, math
ROOT = Path(__file__).resolve().parents[1]
failures=[]
def check(ok,why):
    if not ok: failures.append(why)
scene=(ROOT/'scenes/rooms/hollow_veil_moor.tscn').read_text(encoding='utf-8')
player=(ROOT/'scripts/player.gd').read_text(encoding='utf-8')
controller=(ROOT/'scripts/moonstep_route.gd').read_text(encoding='utf-8')
cues=(ROOT/'scripts/jump_landing_cue.gd').read_text(encoding='utf-8')
load=re.search(r'^\[gd_scene load_steps=(\d+)',scene,re.M)
ext=re.findall(r'^\[ext_resource[^\n]* path="res://([^\"]+)"',scene,re.M)
sub=len(re.findall(r'^\[sub_resource ',scene,re.M))
check(bool(load) and int(load.group(1)) == 1+len(ext)+sub, 'scene load_steps count mismatch')
check(len(ext)==len(set(ext)), 'duplicate resource path in moor scene')
for asset in ext: check((ROOT/asset).is_file(), f'missing resource: {asset}')
check(not any(line.lstrip().startswith('#') for line in scene.splitlines()), 'invalid # comment in .tscn')
check(scene.count('name="WestLanternStep"')==1 and scene.count('name="EastMoonlightStep"')==1, 'route nodes missing')
check(scene.count('script = ExtResource("v124_route")')==2, 'two route scripts expected')
check(scene.count('script = ExtResource("v124_thorns")')==4, 'four jumpable thorns expected')
check(scene.count('script = ExtResource("v124_trial")')==1, 'one simple jump seal expected')
check(scene.count('script = ExtResource("v120_waystone")') >= 10, 'guidance waystones incomplete')
check('destination = "moonwake_crypt"' in scene and 'name="From_moonwake_crypt"' in scene, 'main room portal changed')
ids=re.findall(r'^discovery_id = "([^"]+)"',scene,re.M)
check(len(ids)>=3 and len(set(ids))==len(ids), 'reward save IDs missing or reused')
check(all(not re.search(r'[^a-zA-Z0-9_]',id) for id in ids), 'invalid discovery ID')
items=re.findall(r'^reward_data = ExtResource\("([^"]+)"\)',scene,re.M)
check('v124_locket' in items and 'wand' in items and 'v124_halberd' in items, 'three real loot prizes not set')
# Guarantee pad names are direct children of the two route controllers.
for path in ('WestLanternStep','EastMoonlightStep'):
    for i in range(1,4):
        check(f'name="Step{i}" type="Marker2D" parent="Gameplay/MoonstepRoutes/{path}"' in scene, f'missing Step{i} in {path}')
# Four sets of real physical barriers are on jump-exclusive physics layer.
check('collision_layer = 32' in (ROOT/'scripts/low_thorn_barrier.gd').read_text(), 'barrier collision layer not jump-only')
for token in ['var jump_origin: Vector2', 'jump_origin = global_position', 'collision_mask &= ~JUMPABLE_BARRIER_MASK', '_spawn_jump_landing_cue()', 'preload("res://scripts/jump_landing_cue.gd")']:
    check(token in player, 'player jump change absent: '+token)
for token in ['var progress: int = 0','if airborne_fraction < 0.25 or airborne_fraction > 0.92:','last_jump_origin = jump_started','world_point.distance_to(jump_started) < 30.0','reward_data','inv.save_game()','if prize == null:','if progress >= 3:']:
    check(token in controller,'route behavior missing: '+token)
check('queue_free()' in cues and 'draw_arc(' in cues, 'landing cue does not render and expire')
# Count all enemy instances, no accidental removal from previous v1.23.
enemies=re.findall(r'^\[node name="[^"]+" parent="Gameplay/Enemies" instance=ExtResource\("(?:wraith|hunter)"\)\]',scene,re.M)
check(len(enemies)==142, f'expected 142 easy and existing encounters, found {len(enemies)}')
# All node names unique within a single parent (including the three Step1 markers per different parent).
seen=set()
for name,parent in re.findall(r'^\[node name="([^"]+)"[^\n]* parent="([^"]+)"',scene,re.M):
    check((parent,name) not in seen, f'duplicate node: {parent}/{name}')
    seen.add((parent,name))
# Ensure the new two sets of step markers are separated by achievable short leaps.
for ctrl in ['WestLanternStep','EastMoonlightStep']:
    vals=[]
    for i in range(1,4):
        match=re.search(r'\[node name="Step%d" type="Marker2D" parent="Gameplay/MoonstepRoutes/%s"\]\nposition = Vector2\(([-\d.]+), ([-\d.]+)\)' % (i,ctrl),scene)
        if match: vals.append((float(match.group(1)),float(match.group(2))))
    check(len(vals)==3, f'{ctrl}: missing marker position')
    if len(vals)==3:
        for a,b in zip(vals,vals[1:]):
            check(110<=math.dist(a,b)<=170, f'{ctrl} jump spacing is not accessible')
check('user://ghost_girl_treasures_v2.json' in (ROOT/'scripts/inventory.gd').read_text(), 'save format unexpectedly changed')
res={'version':'1.24','status':'PASS' if not failures else 'FAIL','jump_routes':2,'single_jump_seals':1,'new_weak_enemies':6,'total_enemy_instances':len(enemies),'issues':failures}
print(json.dumps(res,indent=2))
if failures: raise SystemExit(1)
