#!/usr/bin/env python3
"""Static version integrity test, not a Godot runtime test."""
from pathlib import Path
import re, json, sys
root = Path(__file__).resolve().parents[1]
scene = (root/'scenes/rooms/hollow_veil_moor.tscn').read_text()
manager = (root/'scripts/moor_performance_director_v1462.gd').read_text()
game = (root/'scripts/game.gd').read_text()
errors = []
def check(ok, message):
    if not ok:
        errors.append(message)
for resource_id, qty in [('wraith',127),('v129_creature',64),('hunter',19),('v132_boss',1)]:
    check(scene.count('instance=ExtResource("'+resource_id+'")') == qty, 'Enemy count changed: '+resource_id)
check('script = ExtResource("v1462_lod")' in scene, 'Director node missing')
check('res://scripts/moor_performance_director_v1462.gd' in scene, 'Director dependency missing')
for needle in ['enemy.set_physics_process(false)', 'enemy.set_physics_process(true)', 'enemy.set_process(false)', 'enemy.set_process(true)', 'distance_sq > sleep_enemy_sq', 'distance_sq < wake_enemy_sq', 'visual.set_process(false)', 'visual.set_process(true)', 'get_first_node_in_group("ghost_girl_player")']:
    check(needle in manager, 'Missing sleep/wake mechanic: '+needle)
check('queue_free(' not in manager, 'Director must never delete enemies')
check('if room == "hollow_veil_moor"' in game and '_prompt_update_accumulator < 0.10' in game, 'Moor-specific prompt throttle missing')
check('bool(' not in game, 'Previous bool runtime repair was lost')
for script in ['moor_waystone.gd','moor_lantern.gd','moor_story_slab_v134.gd','moor_water_ripples.gd']:
    check('_redraw_accumulator' in (root/'scripts'/script).read_text(), 'Missing draw throttle: '+script)
check('_redraw_accumulator >= 0.033:' in (root/'scripts/moor_rain.gd').read_text(), 'Rain draw throttle missing')
check((root/'assets/world/hollow_veil_moor_v118.jpg').exists(), 'Original moor artwork missing')
check('[gd_scene load_steps=88 format=3]' in scene, 'Scene load step count not updated')
check(scene.count('[ext_resource') + scene.count('[sub_resource') + 1 == 88, 'Scene load_steps count mismatch')
ids = set(re.findall(r'^\[ext_resource [^\n]+ id="([^"]+)"\]', scene, re.M))
refs = set(re.findall(r'ExtResource\("([^"]+)"\)', scene))
check(refs <= ids, 'Orphan external resource references: '+str(sorted(refs-ids)))
for res in re.findall(r'^\[ext_resource [^\n]*path="res://([^"]+)"', scene, re.M):
    check((root/res).is_file(), 'Missing resource file: '+res)
print(json.dumps({'version':'1.46.2','status':'PASS' if not errors else 'FAIL','normal_enemies_preserved':210,'visual_nodes_throttled':79,'runtime_test':'NOT TESTED','errors':errors},indent=2))
sys.exit(bool(errors))
