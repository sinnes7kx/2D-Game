#!/usr/bin/env python3
"""v1.48 file-level and integration checks. NOT an in-engine playtest."""
import re, sys, hashlib, json
from pathlib import Path
P = Path(__file__).resolve().parents[1]  # validate against installed project root
checks=[]
def ck(k,v): checks.append((k,bool(v)))
def get(name):
    p=P/name;ck('exists '+name,p.exists());return p.read_text(encoding='utf-8') if p.exists() else ''
game=get('scripts/game.gd');hud=get('scripts/hud.gd');trial=get('scripts/v147_echo_trial.gd')
route=get('scripts/v148_rose_run.gd');lantern=get('scripts/v148_rose_lantern.gd')
bell=get('scripts/v147_rose_bell.gd');scene=get('scenes/rooms/garden_bridge.tscn')
for token in ['func restore_from_inventory(saved_inventory: Node)','func interact() -> String','func ring(step: int)','func _complete()','func _fail()','func _read_records()']:
    ck('route '+token,token in route)
for token in ['active = false','inventory.call("has_collected", route_id)','flags[route_id] = true','inventory.call("save_game")','RECORD_FILE','completed = true','_reveal(true)','_reveal(false)']:
    ck('one-time + replay route '+token,token in route)
ck('new record file separate from world and inventory schemas', 'ghost_girl_rose_run_bests_v148.json' in route and 'ghost_girl_world_v1.json' in game)
ck('only score for best, not duplicate loot','if not completed:' in route and route.count('flags[route_id] = true')==1)
ck('stamina refill successful step only', route.index('_restore_stamina(10.0)') > route.index('progress += 1'))
ck('mistake is recoverable', 'remaining - 4.0' in route and 'progress = 0' in route)
ck('pause menu', 'call("is_menu_open")' in route and 'call("is_menu_open")' in trial)
ck('trial aborts on defeat', '_abort_failed_trial()' in trial)
ck('rest return preserves context', 'ui.set_rose_run_progress(false)' in game and 'ui.set_echo_trial_progress(false)' in game)
ck('new room restore', 'Gameplay/V148RoseRun' in game and 'rose_path.call("restore_from_inventory", inventory)' in game)
ck('E prompt and interaction', 'current_target.is_in_group("v148_rose_run")' in game and 'target.is_in_group("v148_rose_run")' in game)
ck('existing HUD label', 'func set_rose_run_progress(' in hud and 'vigil_label.text = "ROSE PATH' in hud)
ck('hook collision parent resolution existing', 'func _hook_switch_ancestor' in get('scripts/rose_hook.gd'))
ck('lantern on-hook event', 'add_to_group("hook_switch")' in lantern and 'route.call("ring", order)' in lantern)
ck('bell interrupts really reward stamina', 'interrupted > 0' in bell and '+ 9.0' in bell and 'has_method("_spawn_death_burst")' in bell)
ck('no extra weapon drops in challenge', 'add_loot' not in route and 'spawn_world_loot' not in route)
ids={b:a for a,b in re.findall(r'^\[ext_resource[^\n]*path="([^"]+)" id="([^"]+)"',scene,re.M)}
subids=set(re.findall(r'^\[sub_resource[^\n]*id="([^"]+)"',scene,re.M))
for id in re.findall(r'ExtResource\("([^"]+)"\)',scene):
    ck('scene extref '+id,id in ids)
for id in re.findall(r'SubResource\("([^"]+)"\)',scene):
    ck('scene subref '+id,id in subids)
for id in ['v148_route','v148_lantern','v148_hidden_cache','v148_reward']:
    ck('v148 resource '+id,id in ids)
    if id in ids:ck('v148 actual path '+id,(P/ids[id][6:]).exists())
paths=set()
for line in scene.splitlines():
    if line.startswith('[node '):
        name=re.search(r'name="([^"]+)"',line)
        parent=re.search(r'parent="([^"]+)"',line)
        if not name:continue
        par=parent.group(1) if parent else '.'
        path=name.group(1) if par=='.' else par+'/'+name.group(1)
        ck('unique scene path '+path,path not in paths)
        if par!='.':ck('parent exists '+path,par in paths)
        paths.add(path)
for i in range(1,4):
    base=f'Gameplay/V148RoseRun/Lanterns/Lantern{i}'
    ck('hook lantern node '+str(i),base in paths)
    ck('hook lantern collider '+str(i),base+'/HookBody/CollisionShape2D' in paths)
    ck('correct lantern order '+str(i),'order = '+str(i) in scene)
ck('start altar near east entry','position = Vector2(2020, 1240)' in scene)
ck('unique treasure chest','Gameplay/TreasureChests/RoseRunCache' in paths and 'chest_id = "v148_bridge_rose_run_cache"' in scene)
ck('prior bridge exits retained',all(f'Gameplay/Portals/{x}' in paths for x in ('garden','garden_arbor','weeping_brook')))
ck('prior hook anchors retained',all(f'Gameplay/HookAnchors/{x}' in paths for x in ('AcrossTheBreak','ReturnBankRose','RoseGazebo')))
ck('reward no exit lock', 'opened = true' in scene)
for name in ['scripts/game.gd','scripts/hud.gd','scripts/v147_echo_trial.gd','scripts/v147_rose_bell.gd','scripts/v148_rose_run.gd','scripts/v148_rose_lantern.gd']:
    s=get(name)
    ck('no merge markers '+name,'<<<<<<<' not in s and '>>>>>>>' not in s)
    ck('no mixed indent '+name,re.search(r'^ +\t|^\t+ +\S',s,re.M) is None)
errors=[k for k,v in checks if not v]
print(f'v1.48: {len(checks)-len(errors)}/{len(checks)} offline file-level integration checks passed')
for e in errors[:60]:print('FAIL',e)
if errors:sys.exit(1)
