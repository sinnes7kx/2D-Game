#!/usr/bin/env python3
"""Static checks for Ghost Girl v1.44. Does NOT certify Godot F5 behavior."""
from pathlib import Path
import json, re

ROOT=Path(__file__).resolve().parents[1]
errors=[]

def check(ok,msg):
    if not ok:errors.append(msg)

def source(path):
    p=ROOT/path
    check(p.is_file(),f'Missing file {path}')
    return p.read_text(encoding='utf8') if p.is_file() else ''

scene=source('scenes/rooms/hollow_veil_moor.tscn')
game=source('scripts/game.gd')
fx=source('scripts/weapon_prestige_fx.gd')
lattice=source('scripts/moonroot_lattice_v144.gd')
hitbox=source('scripts/moonroot_hitbox_v144.gd')

for token in ['V144MoonrootCauseways','V144WestRoot','V144WestChain',
              'V144EastFrostJoint','V144Moonmark','V144WestCoffer','V144EastCoffer',
              'V144WestWaystone','V144EastWaystone']:
    check(token in scene,f'Missing node {token}')
check(scene.count('script = ExtResource("v144_lattice")')==3,'Expected 3 causeway lattice mechanisms')
check(scene.count('script = ExtResource("v144_hitbox")')==3,'Expected 3 actual physical hitboxes')
for rid in ['v144_west_shape','v144_westchain_shape','v144_east_shape']:
    check(f'[sub_resource type="RectangleShape2D" id="{rid}"]' in scene,f'Missing editable {rid}')
    check(f'shape = SubResource("{rid}")' in scene,f'Unreferenced editable shape {rid}')
check(scene.count('lattice_kind = "frost_joint"')==1,'Expected one frost-then-hook barrier')
check('V144MoonrootCauseways' in game and 'restore_from_inventory' in game,'World load does not restore v144 state')
check('v144_east_hidden_moonmark' in scene and 'v144_east_causeway_coffer' in scene,'Hidden light coffer missing')
check('loot_seed = 144118' in scene and 'loot_seed = 144276' in scene,'Unique v144 reward seeds missing')

for token in ('func on_hook_latched()', 'func on_elemental_arrow_hit(',
              'func on_grasping_roses()', 'func on_moonfall()',
              'func ignite_from_environment()', 'func receive_damage(',
              'func on_neighbor_opened(', 'func restore_from_inventory(',
              'add_to_group("hook_switch")', 'add_to_group("v139_elemental_world")',
              'add_to_group("v135_frost_targets")', 'add_to_group("v140_flammable")',
              'add_to_group("rose_bloom_relay")', '_save(lattice_id)',
              '_save(lattice_id + "_frost")', 'set_deferred("disabled", opened)',
              'if opened or Engine.is_editor_hint():', 'var HITBOX'):
    if token=='var HITBOX':
        check('const HITBOX_SCRIPT' in lattice,'Lattice should use explicit body forwarding script')
    else:check(token in lattice,f'Gameplay callback/persistence missing: {token}')
check('if opened:' in lattice and 'remove_from_group("hook_switch")' in lattice,
      'Opened barriers should stop responding to hook')
check('if opened or not allow_chain_open' in lattice,'Chain reaction must be bounded')
check('if opened or burning' in lattice,'Fire ignition should be one-shot')
check('enemy.call("hit", impact_damage, 0.5)' in lattice,'No confirmed one-shot impact on nearby enemies')
check('func receive_damage(' in hitbox and 'get_parent()' in hitbox,'Physical collisions do not forward to scripted parent')
check('func ignite_from_environment()' in hitbox,'Flammable physical hitbox missing ignition forwarding')

for token in ('animation.begins_with("sword_")', 'animation.begins_with("attack_sword_")',
              'player.get_node_or_null("Hand")', 'if player == null or float(player.get("spell_time_left")) <= 0.0:',
              '_fallback_tip(grip, face, 24.0)', 'return empty'):
    check(token in fx,f'Restrained sword/wand alignment guard missing: {token}')
check('draw_arc(' not in fx,'Round prestige effects accidentally reintroduced')

check(not re.search(r'^\s*#',scene,re.M),'Invalid # comments in .tscn')
# Scene ext/sub resource IDs must be unique; newly referenced assets must exist.
resources=re.findall(r'^\[ext_resource[^\]]+id="([^\"]+)"\]',scene,re.M)
check(len(resources)==len(set(resources)), 'Duplicate external resource IDs')
subresources=re.findall(r'^\[sub_resource[^\]]+id="([^\"]+)"\]',scene,re.M)
check(len(subresources)==len(set(subresources)), 'Duplicate subresource IDs')
for ident in ('v144_lattice','v144_hitbox'):
    matches=re.findall(r'^\[ext_resource[^\]]*path="res://([^\"]+)"[^\]]*id="'+ident+'"',scene,re.M)
    check(len(matches)==1 and (ROOT/matches[0]).is_file(), f'v144 dependency {ident} missing')
# Check the parent path for every new v144 scene node without relying on editor import caches.
known_names={'Gameplay','Gameplay/TreasureChests','Gameplay/Waystones', 'Gameplay/V144MoonrootCauseways'}
for name,parent in re.findall(r'^\[node name="(V144[^\"]+|Barrier|CollisionShape2D)"[^\]]*parent="(Gameplay/V144MoonrootCauseways[^\"]*|Gameplay/TreasureChests|Gameplay/Waystones)"',scene,re.M):
    check(parent in known_names, f'v144 parent not previously defined: {name} -> {parent}')
    known_names.add(parent+'/'+name)

result={'version':'1.44','status':'PASS' if not errors else 'FAIL',
        'causeway_barriers':3,'new_chests':2,'waystones':2,
        'engine_runtime':'NOT TESTED','errors':errors}
print(json.dumps(result,indent=2))
if errors:raise SystemExit(1)
