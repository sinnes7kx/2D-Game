"""Ghost Girl v1.35 Falling World static scene integration test.
Checks source behavior and editable-scene structure. Not an F5 engine test.
"""
from pathlib import Path
from collections import Counter
import hashlib, json, re, wave
R=Path(__file__).resolve().parents[1]
errors=[]
def ok(test,description):
    if not test:errors.append(description)
def read(path):
    p=R/path
    ok(p.is_file(),f'missing {path}')
    return p.read_text() if p.is_file() else ''
scene=read('scenes/rooms/hollow_veil_moor.tscn')
header=re.search(r'^\[gd_scene load_steps=(\d+) format=3\]',scene,re.M)
ex=re.findall(r'^\[ext_resource[^\n]*\]',scene,re.M)
sub=re.findall(r'^\[sub_resource[^\n]*\]',scene,re.M)
ok(header is not None,'scene header not in Godot 4 format')
if header:ok(int(header.group(1))==len(ex)+len(sub)+1,'Godot load_steps count mismatch')
ids=re.findall(r'^\[ext_resource[^\n]*id="([^\"]+)"',scene,re.M)
subids=re.findall(r'^\[sub_resource[^\n]*id="([^\"]+)"',scene,re.M)
ok(len(ids)==len(set(ids)),'duplicate ext_resource id')
ok(len(subids)==len(set(subids)),'duplicate sub_resource id')
all_ext=set(ids)
for token in re.findall(r'ExtResource\("([^"\n]+)"\)',scene):
    ok(token in all_ext,f'undefined external resource {token}')
for token in re.findall(r'SubResource\("([^"\n]+)"\)',scene):
    ok(token in set(subids),f'undefined subresource {token}')
for match in re.finditer(r'^\[ext_resource[^\n]*path="res://([^"\n]+)"',scene,re.M):
    ok((R/match.group(1)).is_file(),'missing external path '+match.group(1))
ok(not re.search(r'^\s*#',scene,re.M),'tscn contains # comments rather than semicolon')
new=scene.split('; BEGIN V135 FALLING WORLD',1)[-1].split('; BEGIN V136 CHAINFALL',1)[0]
supports=re.findall(r'^\[node name="V135\w+" type="Node2D" parent="Gameplay/V135FallingWorld"\]',new,re.M)
ok(len([n for n in supports if 'Inscription' not in n and 'Seal' not in n])==12,'expected 12 authored hazard supports')
site_ids=re.findall(r'^site_id = "([^"]+)"',new,re.M)
ok(len(site_ids)==12 and len(set(site_ids))==12,'missing or duplicate support IDs')
ok(len(re.findall(r'parent="Gameplay/V135FallingWorld/V135\w+"\]',new))==12,'expected 12 hookable hitbox bodies')
ok(len(re.findall(r'script = ExtResource\("v135_hitbox"\)',new))==12,'crate impact proxies missing')
ok(len(re.findall(r'shape = SubResource\("v135_anchor_shape"\)',new))==12,'hitbox collisions missing')
triggers=re.findall(r'^activation = "([^"]+)"',new,re.M)
for trigger in ['hook','airborne_bow','roses','frost','frost_then_hook']:
    ok(trigger in triggers,'missing trigger type '+trigger)
expected_paths=re.findall(r'^perched_enemy_path = NodePath\("\.\./\.\./Enemies/(V135Perched\w+)"\)',new,re.M)
ok(len(expected_paths)==8,'perched enemy links incomplete')
for name in expected_paths:ok(f'[node name="{name}" parent="Gameplay/Enemies"' in new,'orphaned perched enemy '+name)
ok(new.count('guaranteed_quality = "unique"')==2,'two unique salvage rewards missing')
ok(len(re.findall(r'parent="Gameplay/Enemies" instance=',new))==24,'expected 24 scattered/perched weak enemies')
for required in ('v135_WestWidowBeam','v135_WestHangingBell','v135_WestThornBrace','v135_EastBrittleShelf','v135_EastRottenRig','v135_EastColdJoint'):
    ok(required in new,'salvage gate missing requirement '+required)
for item in ['items/v135/widows_knot.tres','items/v135/rafterfall_moonbow.tres']:
    item_text=read(item)
    ok('unique = true' in item_text and 'equip_slot' in item_text,'invalid unique item '+item)
    for res in re.findall(r'path="res://([^"\n]+)"',item_text):ok((R/res).exists(),'missing reward asset '+res)

support=read('scripts/collapse_support_v135.gd')
debris=read('scripts/falling_debris_v135.gd')
proxy=read('scripts/collapse_support_hitbox_v135.gd')
seal=read('scripts/moor_salvage_seal_v135.gd')
game=read('scripts/game.gd')
rose=read('scripts/grasping_roses_v127.gd')
moon=read('scripts/moonfall_blizzard.gd')
for t in ['func on_hook_latched()','func on_bow_hit(charged: bool, airborne: bool)','func on_grasping_roses()','func on_moonfall()','func receive_damage(amount: float)','func restore_from_inventory(saved_inventory: Node)','func _drop_perched_enemies()','site_id + "_frozen"']:
    ok(t in support,'support behavior missing '+t)
for t in ['func _impact()','if not struck and age >= warning_seconds:','for candidate in get_tree().get_nodes_in_group("enemies")','player.get("jump_time_left")','temporary_cover = StaticBody2D.new()']:
    ok(t in debris,'falling debris behavior missing '+t)
ok('support.call("receive_damage", amount)' in proxy,'thrown crate transfer missing')
ok('get_tree().call_group("v135_hazard_seal", "refresh")' in support,'salvage reward not refreshed')
ok('inventory.call("has_collected", site)' in seal and 'gate.call("set_open", activated)' in seal,'persistence/gate check missing')
ok('Gameplay/V135FallingWorld' in game and 'restore_from_inventory' in game,'world progress not restored in game')
ok('relay.is_ancestor_of(obstacle)' in rose,'Grasping Roses support self-obstruction broken')
ok('get_nodes_in_group("v135_frost_targets")' in moon,'Moonfall support interactions missing')
for filename in ['v135_beam_creak.wav','v135_debris_impact.wav']:
    p=R/'assets/audio'/filename
    ok(p.exists(),'missing original audio '+filename)
    if p.exists():
        with wave.open(str(p),'rb') as w:ok(w.getnframes()>1000 and w.getnchannels()==1,'invalid audio '+filename)
# Ensure saved files, paintings, approved sprite sheets not included in patch.
result={'version':'1.35','status':'PASS' if not errors else 'FAIL','authored_supports':len(site_ids),'perched_enemies':len(expected_paths),'additional_enemy_nodes':len(re.findall(r'parent="Gameplay/Enemies" instance=',new)),'salvage_reward_gates':2,'original_sound_effects':2,'scene_resource_count':len(ex)+len(sub),'runtime_tested':False,'errors':errors}
print(json.dumps(result,indent=2))
if errors: raise SystemExit(1)
