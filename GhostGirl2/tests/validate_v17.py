"""Ghost Girl v1.7 incremental patch static validation, no Godot engine required.

Validates editor-authored rose relay scenes, linked gates and chests, save schema
continuity and the key combat fixes. This is not a runtime/gameplay playtest.
"""
from pathlib import Path
import json, re, hashlib

R=Path(__file__).resolve().parents[1]
errors=[]

def need(condition, description):
 if not condition: errors.append(description)

hook=(R/'scripts/rose_hook.gd').read_text()
switch=(R/'scripts/rose_switch.gd').read_text()
player=(R/'scripts/player.gd').read_text()
wraith=(R/'scripts/rose_wraith.gd').read_text()
game=(R/'scripts/game.gd').read_text()
inventory=(R/'scripts/inventory.gd').read_text()
markup=(R/'scripts/item_rich_text.gd').read_text()
item=(R/'scripts/item_instance.gd').read_text()

need('var finished_mode: int = mode' in hook and 'finished_mode == MODE_SWITCH' in hook,'switch cast cooldown must use saved hook mode')
need(hook.index('var finished_mode: int = mode') < hook.index('mode = MODE_NONE',hook.index('func _finish()')),'mode must be captured before clearing')
need('func _predecessor_ready()' in switch and 'previous_switch_path.is_empty()' in switch,'ordered switch dependency missing')
need('if not _predecessor_ready():' in switch and 'return\n    activated = true' in switch,'out-of-order latch is not blocked')
need('"hook_prompt"' in game and '_effective_range()' in game,'contextual hint for relay is missing')
need('if Input.is_action_just_pressed("attack_light"):' in player and 'if hitstop_left > 0.0:' in player,'hitstop queue not present')
need('_play_if_changed(_weapon_motion_prefix(false) + facing_name)' in player,'weapon-aware idle reset missing')
need('var windup_left: float' in wraith and 'windup_left = 0.52' in wraith,'wraith warning absent')
need('attack_heading.dot(towards.normalized()) > 0.20' in wraith,'wraith attack angle escape missing')
need('windup_left = 0.0' in wraith and 'func on_hook_yank' in wraith,'interruptible windup absent')
need('light_swing_duration' in markup and 'light_stamina_cost' in markup and 'QUICKER LIGHT STRIKE' in markup,'weapon tradeoff display missing')
need('func light_swing_duration()' in item and 'func light_stamina_cost()' in item,'weapon base cost helper missing')
need('user://ghost_girl_treasures_v2.json' in inventory,'save filename has changed')
need('"quality": item.quality' in inventory,'saved item quality field missing')

rooms={
 'ashglass_vault':('gem','v17_ashglass_first','v17_ashglass_second','v17_ashglass_relay_coffer'),
 'bellwether_court':('v07_1','v17_bellwether_first','v17_bellwether_second','v17_bellwether_relay_coffer')
}
for room,(reward,first,second,chest) in rooms.items():
 path=R/f'scenes/rooms/{room}.tscn'
 scene=path.read_text()
 need(scene.count('[node name="V17RoseFirst"')==1,f'{room}: first switch absent or repeated')
 need(scene.count('[node name="V17RoseSecond"')==1,f'{room}: second switch absent or repeated')
 need(scene.count('[node name="V17RoseRelayGate"')==1,f'{room}: gate absent or repeated')
 need(scene.count('[node name="V17RoseRelayCoffer"')==1,f'{room}: chest absent or repeated')
 need(f'discovery_id = "{first}"' in scene and f'discovery_id = "{second}"' in scene,f'{room}: persistent switch IDs incorrect')
 need(f'chest_id = "{chest}"' in scene,f'{room}: persistent reward ID missing')
 need('previous_switch_path = NodePath("../V17RoseFirst")' in scene,f'{room}: order path broken')
 need('gate_path = NodePath("../../V17RoseRelayGate")' in scene,f'{room}: gate link broken')
 need('chest_path = NodePath("../TreasureChests/V17RoseRelayCoffer")' in scene,f'{room}: gate-to-chest link broken')
 need(f'loot_data = ExtResource("{reward}")' in scene,f'{room}: reward unassigned')
 need('shape = SubResource("v17_gate_shape")' in scene,f'{room}: gate collision missing')
 ext=dict(re.findall(r'\[ext_resource[^\n]*path="([^"]+)" id="([^"]+)"\]',scene))
 for p,id in ext.items():
  need((R/p.replace('res://','')).is_file(),f'{room}: missing ext_resource {id}: {p}')
 need(scene.count('id="v17_switch"')==1 and scene.count('id="v17_gate"')==1,f'{room}: relay script resource missing')
 declared=re.search(r'^\[gd_scene load_steps=(\d+)',scene)
 n_ext=len(re.findall(r'^\[ext_resource ',scene,re.M))
 n_sub=len(re.findall(r'^\[sub_resource ',scene,re.M))
 need(declared is not None and int(declared[1]) >= n_ext+n_sub+1,f'{room}: scene load_steps too small')
 # No duplicate node paths in an editor-authored scene; prevents accidental
 # overwriting adjacent chest or world colliders during instantiation.
 paths=[]
 for name,parent in re.findall(r'^\[node name="([^"]+)"[^\n]*parent="([^"]+)"',scene,re.M):
  paths.append(parent+'/'+name)
 need(len(paths)==len(set(paths)),f'{room}: duplicate scene node paths')

# Scythe/halberd artwork from v1.6 must not be modified in a code-only patch.
manifest=json.loads((R/'resources/ghost_extra_animations.json').read_text())
weapon_tracks=[x for x in manifest if 'scythe' in x['name'] or 'halberd' in x['name']]
need(len(weapon_tracks)==32 and all('atlas' in x or len(x.get('textures',[]))==8 for x in weapon_tracks),'v1.6 weapon animations no longer present')
for family in ['scythe','halberd']:
 for track in ['locomotion','combat']:
  png=R/f'assets/ghost/weapons_v16/{family}_{track}_2048x1760.png'
  need(png.exists(),f'original {family} {track} atlas missing')

# Check that all references in newly affected GDScript scripts are available.
for name in ('rose_hook','rose_switch','rose_wraith','player','game','item_instance','item_rich_text'):
 for p in re.findall(r'res://([^"\']+)', (R/f'scripts/{name}.gd').read_text()):
  need((R/p).is_file(),f'{name}: missing script-linked resource {p}')

result={'version':'1.7','status':'PASS' if not errors else 'FAIL','new_ordered_rose_relays':len(rooms),'new_persistent_seals':len(rooms)*2,'new_gated_chests':len(rooms),'weapon_atlases_preserved':4,'files_checked':len(rooms)+7+4,'errors':errors}
print(json.dumps(result,indent=2))
raise SystemExit(1 if errors else 0)
