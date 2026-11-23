#!/usr/bin/env python3
"""v1.45 source and scene dependency checks. No engine F5 certification."""
from pathlib import Path
from collections import Counter
import json, re
ROOT=Path(__file__).resolve().parents[1]
errors=[]
warnings=[]
def check(condition, message):
    if not condition: errors.append(message)
def read(path):
    p=ROOT/path
    check(p.exists(),f'Missing file {path}')
    return p.read_text(encoding='utf-8') if p.exists() else ''
scene=read('scenes/rooms/hollow_veil_moor.tscn')
game=read('scripts/game.gd')
response=read('scripts/moor_world_response_v145.gd')
listener=read('scripts/moor_aftershock_memory_v145.gd')
for filename in ('scripts/moonroot_lattice_v144.gd','scripts/collapse_support_v135.gd','scripts/breakable_cover_v136.gd'):
    check('get_tree().call_group("v145_world_response", "report_world_change"' in read(filename),f'Physical event not emitted by {filename}')
for filename in ('scripts/moor_creature_v129.gd','scripts/gothic_hunter.gd','scripts/rose_wraith.gd'):
    source=read(filename)
    check('func on_world_disturbance(world_point: Vector2, seconds: float) -> void:' in source, f'Missing hearing callback: {filename}')
    check('disturbance_left = maxf(0.0, disturbance_left - delta)' in source, f'Missing decay: {filename}')
    check('if health <= 0.0' in source or 'if hp <= 0.0' in source, f'Dead enemy receives disturbance: {filename}')
check('add_to_group("v145_world_response")' in response,'Responder not registered')
check('add_to_group("v145_aftershock_memory")' in listener,'Aftershock memory not registered')
check('on_world_disturbance' in response,'Responder cannot notify enemies')
check('on_world_change' in response and 'on_world_change' in listener,'Events not routed to discoveries')
check('prior_completed_keys' in listener and 'inventory.has_collected(completed_key)' in listener,'Earlier saves cannot retroactively reveal reward')
check('if awakened and not bool(chest.get("opened")):' in listener,'Reward chest visibility/access not correctly gated')
check('Gameplay/V145LivingMoor' in game and 'restore_from_inventory' in game,'Room loader lacks v145 restoration')
for token in ('V145LivingMoor','WorldResponse','WestAftershock','EastAftershock','V145WestAftershockChest', 'V145EastAftershockChest','V145WestWaystone','V145EastWaystone'):
    check(token in scene,f'Missing scene node: {token}')
check(scene.count('script = ExtResource("v145_aftershock")')==2,'Expected two aftershock memories')
check(scene.count('script = ExtResource("v145_reaction")')==1,'Expected one event coordinator')
check('v144_west_moonroot_01' in scene and 'v144_east_frost_joint' in scene,'Legacy save compatibility IDs absent')
for name in ('v145_west_aftershock','v145_east_aftershock'):
    check(scene.count('discovery_id = "'+name+'"')==1,f'Nonunique discovery ID {name}')
check(not re.search(r'^\s*#',scene,re.M),'Invalid scene comments: use ; not #')
# All external resources are checked, including previous patch dependencies.
exts=re.findall(r'^\[ext_resource\s+[^\]]*path="res://([^\"]+)"[^\]]*id="([^\"]+)"\]',scene,re.M)
check(len(exts)>70,'Scene external resource entries unexpectedly missing')
ids=[ident for _,ident in exts]
check(len(ids)==len(set(ids)),'Duplicated ext resource ID')
for path,ident in exts:
    check((ROOT/path).exists(),f'Missing scene ext resource {ident}: {path}')
for key in ('v145_reaction','v145_aftershock'):
    check(sum(1 for _,id in exts if id==key)==1,f'New resource {key} missing')
# Enforce valid parent chains and unique names under each parent.
node_defs=re.findall(r'^\[node\s+name="([^\"]+)"[^\]]*?(?:parent="([^\"]+)")?[^\]]*\]',scene,re.M)
# Use a strict separate extraction as dynamic 'instance=' is legal.
paths=set(); sibling=[]
for line in scene.splitlines():
    if not line.startswith('[node '): continue
    name_match=re.search(r'\bname="([^\"]+)"',line)
    parent_match=re.search(r'\bparent="([^\"]+)"',line)
    if not name_match: continue
    name=name_match.group(1);parent=parent_match.group(1) if parent_match else ''
    path = name if parent in ('', '.') else parent + '/' + name
    check(path not in paths,f'Duplicate scene path {path}')
    if parent!='.': check(parent in paths or parent=='',f'Undefined node parent {parent} for {name}')
    paths.add(path)
for prefix in ('Gameplay/V145LivingMoor/WorldResponse','Gameplay/V145LivingMoor/WestAftershock','Gameplay/V145LivingMoor/EastAftershock'):
    check(prefix in paths,f'Missing anchored path {prefix}')
for display,chest in [('WestAftershock','V145WestAftershockChest'),('EastAftershock','V145EastAftershockChest')]:
    check(f'reward_chest_path = NodePath("../../TreasureChests/{chest}")' in scene,f'Invalid chest path for {display}')
print(json.dumps({'version':'1.45','status':'PASS' if not errors else 'FAIL','new_memories':2,'enemy_archetypes_reacting':3, 'godot_F5':'NOT RUN','errors':errors,'warnings':warnings},indent=2))
if errors: raise SystemExit(1)
