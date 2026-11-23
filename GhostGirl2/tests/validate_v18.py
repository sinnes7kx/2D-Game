"""v1.8 weight puzzles, combat and save schema static checks; not a Godot playtest."""
from pathlib import Path
import json,re,zipfile
R=Path(__file__).resolve().parents[1]
errors=[]
def require(predicate,message):
    if not predicate: errors.append(message)
new=(R/'scripts/weighted_rose_plate.gd').read_text()
game=(R/'scripts/game.gd').read_text()
player=(R/'scripts/player.gd').read_text()
wraith=(R/'scripts/rose_wraith.gd').read_text()
rose_gate=(R/'scripts/rose_gate.gd').read_text()
inventory=(R/'scripts/inventory.gd').read_text()
require('add_to_group("rose_weight_plate")' in new,'Missing plate group for HUD prompt')
require('func restore_secret(inventory: Node)' in new,'Plate restore interface missing')
require('not bool(crate.get("held"))' in new,'Held crate incorrectly triggers plate')
require('z_height < 13.0' in new,'Airborne thrown crate can trigger seal')
require('crate.global_position.distance_to(global_position) <= trigger_radius' in new,'Plate proximity trigger absent')
require('save_inventory.call("save_game")' in new and 'collected_pickups' in new,'Plate discovery is not persisted')
require('gate.call("set_open", activated)' in new,'Plate does not operate gate')
require('set_deferred("disabled", open)' in rose_gate,'Gate does not disable collision')
require('chest.add_to_group("interactable")' in rose_gate,'Gate does not unlock coffer')
require('if rose.has_method("restore_secret")' in game,'Plate not restored by room loader')
require('func _rose_weight_hint()' in game and 'Q  PULL WEIGHT' in game,'Missing mechanic hint')
require('func _attack_action_cost(heavy: bool)' in player,'Actual weapon attack costs not used')
require(player.count('stamina >= _attack_action_cost(')==4,'Queued and immediate weapon cost gates incomplete')
require('if dodge_time_left <= 0.21:' in player and '_queue_combat("heavy")' in player,'Late dodge buffers missing')
require('func offers_backstep_counter(player_position: Vector2)' in wraith,'Wraith not counterable after warning')
require('windup_left > 0.0 and windup_left <= 0.36' in wraith,'Wraith counter availability not tied to warning')
require('contact_cooldown = maxf(contact_cooldown, 0.34)' in wraith,'Wraith strike interruption cooldown missing')
require('user://ghost_girl_treasures_v2.json' in inventory and '"quality": item.quality' in inventory,'Existing saves not preserved')
rooms={'blackbrick_court':('v18_blackbrick_weight_rose','v18_blackbrick_weight_coffer','itemgem'), 'ashen_causeway':('v18_causeway_weight_rose','v18_causeway_weight_coffer','itemrune')}
for room,(switch,chest,reward) in rooms.items():
    scene=(R/'scenes/rooms'/f'{room}.tscn').read_text()
    for node in ('V18MoonstoneWeight','V18RoseWeightPlate','V18WeightGate','V18WeightCoffer'):
        require(scene.count(f'[node name="{node}"')==1,f'{room}: {node} not unique')
    for token in (f'discovery_id = "{switch}"',f'chest_id = "{chest}"',f'loot_data = ExtResource("{reward}")','crate_path = NodePath("../../Carryables/V18MoonstoneWeight")','gate_path = NodePath("../../V18WeightGate")','chest_path = NodePath("../TreasureChests/V18WeightCoffer")','shape = SubResource("v18_weight_gate_shape")'):
        require(token in scene,f'{room}: missing {token}')
    resources = dict(re.findall(r'\[ext_resource[^\n]*path="([^"]+)" id="([^"]+)"\]',scene))
    for path,ref in resources.items():
        require((R/path.replace('res://','')).is_file(), f'{room}: broken ext_resource {ref}')
    loaded = re.search(r'^\[gd_scene load_steps=(\d+)',scene)
    count=len(re.findall(r'^\[ext_resource ',scene,re.M))+len(re.findall(r'^\[sub_resource ',scene,re.M))+1
    require(loaded and int(loaded.group(1))>=count, f'{room}: resource load_steps undercount')
    # Resolve the authored NodePaths to real scene node names rather than only
    # checking string spellings. These paths are relative to their owner node.
    import posixpath
    paths={}
    for m in re.finditer(r'^\[node name="([^"]+)"([^\n]*)\]', scene, re.M):
        name, attrs=m.groups()
        parent_match=re.search(r'parent="([^"]+)"', attrs)
        if parent_match:
            parent=parent_match.group(1)
            paths[posixpath.normpath(("" if parent=="." else parent)+"/"+name)]=True
    owner='Gameplay/HookAnchors/V18RoseWeightPlate'
    gate='Gameplay/V18WeightGate'
    for origin,dest in [(owner,'../../Carryables/V18MoonstoneWeight'),(owner,'../../V18WeightGate'),(gate,'../TreasureChests/V18WeightCoffer')]:
        result=posixpath.normpath(origin+'/'+dest)
        require(result in paths,f'{room}: invalid NodePath {origin} -> {dest}: {result}')
    # Plate is close enough to its crate to allow hook pulling or carrying,
    # but not already occupied at first entry.
    coords={}
    for m in re.finditer(r'^\[node name="(V18\w+)"[^\n]*\]\nposition = Vector2\((\d+), (\d+)\)',scene,re.M):
        coords[m.group(1)]=(int(m.group(2)),int(m.group(3)))
    require(len(coords)==4,f'{room}: missing scene-space placement')
    if len(coords)==4:
        a=coords['V18MoonstoneWeight']; b=coords['V18RoseWeightPlate']
        distance=((a[0]-b[0])**2+(a[1]-b[1])**2)**0.5
        require(90 < distance < 280,f'{room}: crate-plate spacing not playable')
require('4.7' in (R/'project.godot').read_text(),'Engine feature requirements lost')
print(json.dumps({'version':'1.8','status':'PASS' if not errors else 'FAIL','physical_weight_puzzles':len(rooms),'save_schema':'unchanged','errors':errors},indent=2))
raise SystemExit(bool(errors))
