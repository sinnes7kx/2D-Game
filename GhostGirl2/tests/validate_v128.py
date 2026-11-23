"""v1.28 environmental spells + airborne archery. Offline/source only."""
from pathlib import Path
import re, json, hashlib, posixpath
ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT.parent / 'GhostGirl_v127_work'
errors = []
def require(test, what):
    if not test: errors.append(what)
def read(path):
    full=ROOT/path
    require(full.is_file(), f'missing {path}')
    return full.read_text(encoding='utf-8') if full.is_file() else ''

scene=read('scenes/rooms/hollow_veil_moor.tscn')
resource_entries=re.findall(r'^\[ext_resource[^\]]*path="res://([^"]+)"[^\]]*id="([^"]+)"\]$',scene,re.M)
subids=re.findall(r'^\[sub_resource[^\]]*id="([^"]+)"\]$',scene,re.M)
require(len(set(x[1] for x in resource_entries)) == len(resource_entries), 'duplicate external resource IDs')
require(int(re.search(r'\[gd_scene load_steps=(\d+)',scene).group(1)) == len(resource_entries)+len(subids)+1, 'invalid load_steps')
for pathname,_id in resource_entries:
    require((ROOT/pathname).is_file(),f'missing scene external path {pathname}')
require(not re.search(r'^\s*#',scene,re.M),'invalid # comments in tscn')

# Parse node paths and validate all new relative gate/chest links.
nodes={}
for match in re.finditer(r'^\[node name="([^"]+)"[^\]]*parent="([^"]+)"[^\]]*\]\n(.*?)(?=^\[node |\Z)',scene,re.M|re.S):
    name, parent, body=match.groups()
    path=(parent+'/'+name) if parent != '.' else name
    require(path not in nodes, 'duplicate node '+path)
    nodes[path]=body
for group, count in [('Gameplay/V128BloomRelays',2),('Gameplay/V128BowTargets',2)]:
    require(group in nodes, f'missing container {group}')
    count_found=sum(1 for p in nodes if p.startswith(group+'/') and p.count('/')==group.count('/')+1)
    require(count_found==count,f'{group} expected {count} children, found {count_found}')
for p,body in nodes.items():
    if not (p.startswith('Gameplay/V128') and ('Bloom' in p or 'Archery' in p or 'MoonTarget' in p)):
        continue
    for token in ('gate_path','chest_path'):
        m=re.search(r'^'+token+r' = NodePath\("([^"]+)"\)$',body,re.M)
        if m:
            target=posixpath.normpath(p+'/'+m.group(1))
            require(target in nodes, f'{p}: missing node {token}={target}')

for name in ('V128WesternBloomChest','V128EasternBloomChest','V128WestArcheryChest','V128EastArcheryChest'):
    require(f'Gameplay/TreasureChests/{name}' in nodes,'missing reward chest '+name)
for name in ('V128WestMoonTarget','V128EastMoonTarget'):
    require(f'Gameplay/V128BowTargets/{name}' in nodes,'missing moon target '+name)
for name in ('V128WesternBloom','V128EasternBloom'):
    require(f'Gameplay/V128BloomRelays/{name}' in nodes,'missing bloom relay '+name)

water=read('scripts/water_body.gd')
for token in ('func freeze_near(', 'func movement_multiplier_at(', 'Geometry2D.is_point_in_polygon', 'ice_patches', 'ice_patches.remove_at(i)'):
    require(token in water, 'water missing '+token)
moon=read('scripts/moonfall_blizzard.gd')
require('water_checked: bool = false' in moon and '_freeze_nearby_water()' in moon,'Moonfall water interaction absent')
require(moon.count('enemy.call("hit",')==1,'Moonfall damage modified')
roses=read('scripts/grasping_roses_v127.gd')
for token in ('relays_checked: bool = false', 'func _awaken_bloom_relays(', '"rose_bloom_relay"','"on_grasping_roses"', 'ray.collision_mask = 2'):
    require(token in roses,'Grasping Roses interaction missing '+token)
require(roses.count('enemy.call("hit",')==1,'Roses damage modified')

player=read('scripts/player.gd')
require('"movement_multiplier_at"' in player and 'desired_speed *= float(' in player,'water speed effect disconnected')
require('arrow.set("launched_in_air", jump_time_left > 0.0)' in player,'jump shooting flag missing')
arrow=read('scripts/bow_arrow_v126.gd')
for token in ('var launched_in_air: bool = false', 'func _check_moon_targets(', 'if not (charged and launched_in_air):', '_check_moon_targets(start, end)','target.call("on_bow_hit", charged, launched_in_air)'):
    require(token in arrow,'arrow interaction missing '+token)
require(arrow.count('target.call("hit", damage,')==1, 'arrow damage duplicated')
relay=read('scripts/rose_bloom_relay_v128.gd')
target=read('scripts/moon_archery_target_v128.gd')
for name,body in [('relay',relay),('target',target)]:
    for token in ('func restore_secret(', 'has_collected(discovery_id)', 'saved' if name=='target' else 'collected', 'save_game', 'set_open'):
        require(token in body,f'{name} save/gate missing {token}')
require('if Engine.is_editor_hint() or activated or not (charged and airborne):' in target,'bow target does not require airborne charge')
game=read('scripts/game.gd')
require('"Gameplay/V128BloomRelays", "Gameplay/V128BowTargets"' in game,'room restoration not wired')
require('user://ghost_girl_treasures_v2.json' in read('scripts/inventory.gd'),'save path altered')

# Approved art and prior v1.27 unlock scene must not change in this patch.
for relative in ('assets/world/hollow_veil_moor_v118.jpg', 'resources/ghost_extra_animations.json', 'scenes/rooms/moonwake_crypt.tscn'):
    if (BASE/relative).exists():
        require(hashlib.sha256((BASE/relative).read_bytes()).digest()==hashlib.sha256((ROOT/relative).read_bytes()).digest(),'unexpected artwork/scene change '+relative)

print(json.dumps({'version':'1.28','status':'PASS' if not errors else 'FAIL',
                  'bloom_relays':2,'jump_bow_targets':2,'new_chests':4,
                  'water_regions':3,'runtime_tested':False,'errors':errors},indent=2))
if errors: raise SystemExit(1)
