#!/usr/bin/env python3
"""v1.47 gameplay-loop static validator. Does not replace a Godot F5 playtest."""
import re
from pathlib import Path
R = Path(__file__).resolve().parents[1]
checks = []
def check(label, condition):
    checks.append((label, bool(condition)))

def load(path):
    f=R/path
    check('exists '+str(path),f.is_file())
    return f.read_text(encoding='utf-8') if f.exists() else ''

def inspect_scene(name):
    source=load('scenes/rooms/'+name+'.tscn')
    all_resources=dict((b,a) for a,b in re.findall(r'^\[ext_resource[^\n]*path="([^"]+)" id="([^"]+)"\]',source,re.M))
    all_sub=set(re.findall(r'^\[sub_resource[^\n]*id="([^"]+)"',source,re.M))
    for rid in re.findall(r'ExtResource\("([^"]+)"\)',source):
        check(name+' ext ref '+rid,rid in all_resources)
    for rid in re.findall(r'SubResource\("([^"]+)"\)',source):
        check(name+' sub ref '+rid,rid in all_sub)
    node_paths=set()
    for line in source.splitlines():
        if not line.startswith('[node '): continue
        match=re.search(r'\bname="([^"]+)"',line)
        parent=re.search(r'\bparent="([^"]+)"',line)
        if not match: continue
        group='.' if parent is None else parent.group(1)
        path=match.group(1) if group=='.' else group+'/'+match.group(1)
        check(name+' unique path '+path,path not in node_paths)
        if group!='.':
            check(name+' declared parent '+path,group in node_paths)
        node_paths.add(path)
    return source,node_paths

trial=load('scripts/v147_echo_trial.gd')
bell=load('scripts/v147_rose_bell.gd')
relay=load('scripts/v147_rose_relay.gd')
relay_bell=load('scripts/v147_rose_relay_bell.gd')
game=load('scripts/game.gd')
hud=load('scripts/hud.gd')
inventory=load('scripts/inventory.gd')
for token in ('func interact()', 'func prompt_text()', 'func restore_from_inventory(saved_inventory:', 'func _spawn_next_wave()', 'func _round_finished()', 'func _finish()', 'func _claim_reward()', 'func _update_hud()'):
    check('trial functionality '+token,token in trial)
for token in ('rose_wraith.tscn','gothic_hunter.tscn','SpawnWaves/Wave%d','v147_trial_enemy','warder','occultist','_recover_between_waves()'):
    check('varied waves '+token,token in trial)
check('one-time item claim flag', 'trial_id + "_claimed"' in trial)
check('one-time first reward not per replay', 'if not reward_claimed:' in trial)
check('no repeated trash loot', 'creature.set("loot_template", null)' in trial and 'creature.set("drop_data", null)' in trial)
check('trial can survive full backpack', 'BACKPACK FULL · E TO CLAIM WHEN SPACE IS FREE' in trial)
check('numeric bests kept outside legacy collected flags', 'RECORD_FILE:' in trial and 'ghost_girl_echo_trial_bests_v147.json' in trial and 'time_ms' in trial)
check('existing inventory format untouched', 'collected_pickups[str(key)] = true' in inventory)
check('same original world save file untouched', 'ghost_girl_world_v1.json' in game)
check('trial room binding', 'Gameplay/V147Trials' in game and 'trial.call("restore_from_inventory", inventory)' in game)
check('relay binding', 'Gameplay/V147RoseRelay' in game and 'rose_relay.call("restore_from_inventory", inventory)' in game)
check('new E interaction branch', 'target.is_in_group("v147_echo_trial")' in game and 'target.call("interact")' in game)
check('context prompt from trial node', 'current_target.call("prompt_text")' in game)
check('quiet HUD reused, no blocking menu', 'func set_echo_trial_progress(' in hud and 'vigil_label.text = ' in hud)
check('rose hook bell stagger, cooldown', 'func on_hook_latched()' in bell and 'cooldown_seconds' in bell and 'target.call("hit", damage, 1.7)' in bell)
check('existing bell sound reused', 'res://assets/audio/hook_chime.wav' in bell and 'res://assets/audio/hook_chime.wav' in relay_bell)
check('correct relay order', 'if step == progress + 1:' in relay and 'progress = 0' in relay)
check('relay reward separate persistent flag', 'flags[relay_id] = true' in relay and '_reveal(true)' in relay)
check('relay cache nodepath points to sibling container', 'NodePath("../TreasureChests/ThreeRoseCache")' in relay)
check('relay bell hook wired to manager', 'relay.call("ring", sequence_number)' in relay_bell)

for name in ('moonwake_crypt','garden'):
    source,paths=inspect_scene(name)
    base='Gameplay/V147Trials/'
    trials=[p for p in paths if p.startswith(base) and p.endswith('/SpawnWaves')]
    check(name+' exactly one authored trial', len(trials)==1)
    for i in (1,2,3):
        check(name+f' wave {i} markers', any(p.startswith(trials[0]+f'/Wave{i}/') and p.count('/')==trials[0].count('/')+2 for p in paths) if trials else False)
    check(name+' active bell with collision', 'Gameplay/V147Trials/RoseBell/HookBody/CollisionShape2D' in paths)
    check(name+' one first-clear reward', 'first_clear_reward = ExtResource("v147_trial_reward")' in source)
    check(name+' no old scene removed', 'V1464EarlyPuzzles' in source and 'V147Trials' in source)
    check(name+' site ID unique', 'v147_moonwake_echoes' in source if name=='moonwake_crypt' else 'v147_garden_thorn_trial' in source)

source,paths=inspect_scene('crypt_gallery')
for number in (1,2,3):
    check('gallery chime '+str(number),f'Gameplay/V147RoseRelay/Bells/Chime{number}/HookBody/CollisionShape2D' in paths)
check('gallery reward cache', 'Gameplay/TreasureChests/ThreeRoseCache' in paths and 'chest_id = "v147_gallery_three_rose_cache"' in source)
check('gallery retains original dress', 'DressOfTheMemorial' in source)
check('gallery keeps normal portals', 'Gameplay/Portals/crypt' in paths and 'Gameplay/Portals/garden' in paths)

for name in ['scripts/v147_echo_trial.gd','scripts/v147_rose_bell.gd','scripts/v147_rose_relay.gd','scripts/v147_rose_relay_bell.gd', 'scripts/game.gd','scripts/hud.gd']:
    script=load(name)
    check(name+' no merge markers',not any(p in script for p in ('<<<<<<<','=======\n>>>>>>>','>>>>>>>')))
    check(name+' no tabs-spaces mixed on same line',re.search(r'^ +\t|^\t+ +\S',script,re.M) is None)
    # Balanced code delimiters ignoring strings and comment text.
    raw='\n'.join(l.split('#')[0] for l in script.splitlines())
    opens={'(':')','[':']','{':'}'};stack=[];in_string=False;escape=False;balanced=True
    for char in raw:
        if in_string:
            if escape:escape=False
            elif char=='\\':escape=True
            elif char=='"':in_string=False
        elif char=='"':in_string=True
        elif char in opens:stack.append(opens[char])
        elif char in ')]}':
            if not stack or stack.pop()!=char:balanced=False;break
    check(name+' balanced basic delimiters', balanced and not stack)

errors=[c for c,ok in checks if not ok]
print(f'v1.47 game content: {len(checks)-len(errors)}/{len(checks)} static checks passed.')
for error in errors[:25]: print('FAIL:',error)
if errors:raise SystemExit(1)
