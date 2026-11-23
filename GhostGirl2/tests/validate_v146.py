#!/usr/bin/env python3
"""Ghost Girl v1.46 – static/incremental integration checks (not an F5 test).

Runs against an assembled v1.45 source tree containing its original dependencies.
No Godot executable was present when this patch was authored.
"""
from pathlib import Path
import re, json
R = Path(__file__).resolve().parents[1]
errors=[]
def check(ok, why):
    if not ok: errors.append(why)
def read(path):
    p=R/path
    check(p.is_file(), f'Missing {path}')
    return p.read_text(encoding='utf-8') if p.exists() else ''

scene=read('scenes/rooms/blackbrick_court.tscn')
game=read('scripts/game.gd')
controller=read('scripts/moor_world_response_v145.gd')
helper=read('scripts/environment_navigation_v146.gd')
signal=read('scripts/ashglass_signal_v146.gd')
gate=read('scripts/ashglass_gate_v146.gd')

for token in ('report_fire_ignition(world_point: Vector2, alert_radius: float = 175.0)',
              'on_environment_threat', 'if not Engine.is_editor_hint()'):
    check(token in controller, f'Missing fire announcement feature: {token}')
check('enemy.call("hit"' not in controller and 'receive_damage' not in controller,
      'Fire announcement must not add damage hits')
for token in ('static func avoid_fire(enemy: CharacterBody2D, desired_velocity: Vector2) -> Vector2:',
              'get_first_node_in_group("v146_live_fire")', 'if desired_velocity.length_squared() < 1.0:',
              'return blended.normalized() * speed'):
    check(token in helper, f'Hazard steering token missing {token}')

for path in ('scripts/elemental_flammable_v139.gd', 'scripts/elemental_kindling_v140.gd',
             'scripts/breakable_cover_v136.gd', 'scripts/moonroot_lattice_v144.gd'):
    code=read(path)
    check('add_to_group("v146_live_fire")' in code, f'Fire is not registered in {path}')
    check('remove_from_group("v146_live_fire")' in code, f'Burnt hazard remains active in {path}')
    check('"report_fire_ignition"' in code, f'Fire ignition does not notify world in {path}')
    check('fire_avoid_radius' in code, f'No authored avoidance radius in {path}')

for path in ('scripts/moor_creature_v129.gd', 'scripts/gothic_hunter.gd', 'scripts/rose_wraith.gd'):
    code=read(path)
    check('environment_navigation_v146.gd' in code, f'Enemy has no fire navigation dependency {path}')
    check('FIRE_STEERING.avoid_fire(self, velocity)' in code, f'Enemy movement lacks fire avoidance {path}')
    check('func on_environment_threat(world_point: Vector2, seconds: float) -> void:' in code,
          f'Enemy cannot react to ignition {path}')
    check('fire_alert_left = maxf(0.0, fire_alert_left - delta)' in code,
          f'Enemy fire alert never expires {path}')

for token in ('func restore_from_inventory(saved_inventory: Node)',
              'func on_hook_latched() -> void:',
              'func on_elemental_arrow_hit(element: int, _formation: int, _charged: bool, _airborne: bool) -> bool:',
              'func on_moonfall() -> bool:', 'func ignite_from_environment() -> void:',
              'chest.visible = unlocked', 'gate.call("set_open", unlocked)',
              '_save(signal_id)', '_save(signal_id + "_chilled")'):
    check(token in signal, f'Missing editor-editable signal behavior: {token}')
check('receive_damage' not in signal and '.call("hit"' not in signal,
      'A court signal must not add attack damage')
for token in ('func set_open(value: bool) -> void:',
              'collider.set_deferred("disabled", opened)',
              'blocker.set_deferred("collision_layer", 0 if opened else 2)'):
    check(token in gate, f'Missing physical-gate transition: {token}')
check('Gameplay/V146CourtSignals' in game and 'device.call("restore_from_inventory", inventory)' in game,
      'Room loader does not restore the two Ashglass puzzles')

exts=re.findall(r'^\[ext_resource[^\n]*path="res://([^\"]+)"[^\n]*id="([^"]+)"\]',scene,re.M)
subresources=re.findall(r'^\[sub_resource',scene,re.M)
load_steps=int(re.search(r'load_steps=(\d+)',scene).group(1))
check(load_steps==len(exts)+len(subresources)+1,
      f'.tscn load_steps {load_steps} != ext+sub+1 ({len(exts)+len(subresources)+1})')
ids=[item[1] for item in exts]
check(len(ids)==len(set(ids)),'Duplicate .tscn external-resource IDs')
for resource,identity in exts:
    check((R/resource).is_file(),f'Scene resource not present {identity}: {resource}')
check(not re.search(r'^\s*#',scene,re.M),'Godot .tscn comments must begin with ;')

paths=set()
sections={}
current=None
for line in scene.splitlines():
    if line.startswith('[node '):
        nm=re.search(r'\bname="([^"]+)"',line)
        parent=re.search(r'\bparent="([^"]+)"',line)
        if nm is None:
            continue
        name=nm.group(1); base=parent.group(1) if parent else ''
        full=name if base in ('', '.') else base+'/'+name
        check(full not in paths, f'Duplicate scene node {full}')
        if base not in ('', '.'):
            check(base in paths,f'Undefined node parent {base} at {full}')
        paths.add(full)
        current=full
        sections[current]=[]
    elif current is not None:
        sections[current].append(line)

for named in ('Gameplay/V146CourtSignals/EmberSignal','Gameplay/V146CourtSignals/FrostSignal',
              'Gameplay/V146CourtSignals/EmberGate','Gameplay/V146CourtSignals/FrostGate',
              'Gameplay/TreasureChests/V146EmberCoffer','Gameplay/TreasureChests/V146FrostCoffer',
              'Gameplay/Effects/V146CourtWorldResponse',
              'Gameplay/Memories/V146EmberInscription','Gameplay/Memories/V146FrostInscription'):
    check(named in paths, f'Expected editable node missing {named}')

for kind, id_value, reward in (
    ('Ember','v146_blackbrick_ember_gate','V146EmberCoffer'),
    ('Frost','v146_blackbrick_frost_gate','V146FrostCoffer')):
    path='Gameplay/V146CourtSignals/'+kind+'Signal'
    content='\n'.join(sections.get(path,[]))
    check('signal_id = "'+id_value+'"' in content, f'Unstable save flag {path}')
    check('gate_path = NodePath("../'+kind+'Gate")' in content, f'Wrong gate link {path}')
    check('chest_path = NodePath("../../TreasureChests/'+reward+'")' in content,
          f'Wrong reward link {path}')
    c='\n'.join(sections.get('Gameplay/TreasureChests/'+reward,[]))
    check('visible = false' in c and 'guaranteed_quality = "rare"' in c,
          f'Reward not initially hidden/rare {reward}')

check('script = ExtResource("v145_world_response")' in '\n'.join(sections.get('Gameplay/Effects/V146CourtWorldResponse',[])),
      'Blackbrick Court has no local world disturbance responder')
check('v146_signal' in ids and 'v146_gate' in ids, 'New scripts not declared in scene')
check('script = ExtResource("v134_story")' in scene, 'Missing player-readable lore hints')

print(json.dumps({
    'version':'1.46',
    'status':'PASS' if not errors else 'FAIL',
    'features': {'fire_avoidance_enemy_types':3, 'active_fire_prop_types':4,
                 'optional_blackbrick_mechanisms':2, 'hidden_rare_caches':2,
                 'new_world_interaction_area':'Blackbrick Court'},
    'scene_ext_resources':len(exts), 'scene_sub_resources':len(subresources),
    'godot_runtime':'NOT TESTED', 'errors':errors},indent=2))
if errors: raise SystemExit(1)
