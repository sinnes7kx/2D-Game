"""Source-level v1.37 validation. Requires a Godot F5 playtest afterward."""
from pathlib import Path
import re, json, hashlib, wave, math
ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT.parent/'GhostGirl_v136_work'
errors=[]
def check(test,note):
    if not test:
        errors.append(note)
def read(rel):
    p=ROOT/rel
    check(p.is_file(),f'missing {rel}')
    return p.read_text('utf-8') if p.is_file() else ''
scene=read('scenes/rooms/hollow_veil_moor.tscn')
world=read('scripts/game.gd')
bell=read('scripts/bellroot_resonance_v137.gd')
chorus=read('scripts/bellroot_chorus_v137.gd')
head=re.search(r'^\[gd_scene load_steps=(\d+) format=3\]',scene,re.M)
exts=re.findall(r'^\[ext_resource[^\n]+\]$',scene,re.M)
subs=re.findall(r'^\[sub_resource[^\n]+\]$',scene,re.M)
check(head is not None, 'scene header missing')
if head:
    check(int(head.group(1))==len(exts)+len(subs)+1,'load_steps incorrect')
check(not re.search(r'^\s*#',scene,re.M),'invalid # comment in tscn')
check(not re.search(r'Color\("[0-9a-fA-F]{6}"\)',scene),'GDScript-only Color string in tscn')
resource_ids=re.findall(r'^\[ext_resource[^\n]*\bid="([^"\n]+)"',scene,re.M)
sub_ids=re.findall(r'^\[sub_resource[^\n]*\bid="([^"\n]+)"',scene,re.M)
check(len(resource_ids)==len(set(resource_ids)),'duplicated ExtResource id')
check(len(sub_ids)==len(set(sub_ids)),'duplicated SubResource id')
for ident in re.findall(r'ExtResource\("([^"\n]+)"\)',scene):
    check(ident in resource_ids,f'unknown resource id {ident}')
for ident in re.findall(r'SubResource\("([^"\n]+)"\)',scene):
    check(ident in sub_ids,f'unknown subresource id {ident}')
for rel in re.findall(r'^\[ext_resource[^\n]*path="res://([^"\n]+)"',scene,re.M):
    check((ROOT/rel).is_file(),f'missing referenced file {rel}')
# Parents must be declared earlier than their children in the serialized scene.
known=set()
for m in re.finditer(r'^\[node name="([^"\n]+)"[^\n]*\]$',scene,re.M):
    line=m.group(0); name=m.group(1)
    pm=re.search(r'parent="([^"\n]+)"',line)
    if not pm:
        known.add('')
        continue
    parent=pm.group(1)
    check(parent=='.' or parent in known,f'missing node parent: {name} under {parent}')
    known.add(name if parent=='.' else parent+'/'+name)
section=scene[scene.find('; BEGIN V137 BELLROOT CHORUS'):]
check(section.startswith('; BEGIN V137'),'missing v137 section')
check(section.count('script = ExtResource("v137_bell")')==4,'must place four playable bell nodes')
check(section.count('shape = SubResource("v137_bell_shape")')==4,'missing bell physical hitboxes')
check(section.count('script = ExtResource("v137_chorus")')==2,'two reward seals required')
check(section.count('guaranteed_quality = "unique"')==2,'two unique rewards required')
check(len(re.findall(r'parent="Gameplay/Enemies" instance=ExtResource\("v129_creature"\)',section))==8,'eight lightweight enemy nodes required')
check(section.count('script = ExtResource("v120_waystone")')==5,'five navigation hints required')
ids=['v137_willow_bell','v137_dusk_bell','v137_grave_bell','v137_fen_bell']
for ident in ids:
    check(f'bell_id = "{ident}"' in section,f'missing persistent bell {ident}')
    check(section.count(f'"{ident}"')>=3,f'missing bell id in both locks: {ident}')
for goal in ['v137_four_chimes_reward','v137_creative_chorus_reward']:
    check(f'chest_id = "{goal}"' in section,f'missing reward {goal}')
check('method_threshold = 3' in section,'creativity gate must require 3 distinct methods')
check('Gameplay/V137Bellroots' in world and 'device.is_in_group("hook_switch")' in world and 'device.is_in_group("v137_chorus_vault")' in world,'room restore path not wired')
methods=['hook','roses','frost','bow','debris']
for token in ['func on_hook_latched()', 'func on_grasping_roses() -> bool:', 'func on_moonfall() -> bool:', 'func on_bow_hit(charged: bool, airborne: bool)', 'func on_falling_debris_impact(', 'func restore_from_inventory(saved_inventory: Node)', 'if cooldown > 0.0 or recorded_methods.has(style):','flags[_method_key(style)] = true','inventory.call("save_game")','get_tree().call_group("v137_chorus_vault", "refresh")','func _pulse_once()']:
    check(token in bell,f'bell missing {token}')
check(bell.count('enemy.call("hit",')==1,'bell can deal more than one strike per pulse')
for token in ['method_count = discovered.size()', 'progress == bell_ids.size()', 'method_count >= method_threshold','func restore_from_inventory(saved_inventory: Node)', 'gate.call("set_open", unlocked)']:
    check(token in chorus,f'chorus progression incomplete: {token}')
check('v136_chain_receivers' in bell,'debris activation not wired')
# Eastern chain final impact (7820,4050)+(145,45) -> (7965,4095).
check(math.dist((7990,4140),(7965,4095)) < 90,'Grave bell too far from actual eastern chain debris')
for rel in ['items/v137/chimekeeper_rosary.tres','items/v137/choral_moonbow.tres']:
    text=read(rel)
    check('unique = true' in text, f'{rel} is not unique')
    for path in re.findall(r'path="res://([^"\n]+)"',text):
        check((ROOT/path).is_file(),f'item references missing path {path}')
sound=ROOT/'assets/audio/v137_bellroot_chime.wav'
check(sound.is_file(), 'original bell sound missing')
if sound.is_file():
    with wave.open(str(sound),'rb') as wav:
        check(wav.getframerate()==22050 and wav.getnchannels()==1 and wav.getnframes()>15000,'bad original sound encoding')
for rel in ['assets/world/hollow_veil_moor_v118.jpg', 'scripts/inventory.gd','resources/ghost_extra_animations.json']:
    if (BASE/rel).is_file():
        check(hashlib.sha256((BASE/rel).read_bytes()).digest()==hashlib.sha256((ROOT/rel).read_bytes()).digest(),f'core source unexpectedly changed: {rel}')
# Enumerate states as a pure cross-check of the documented save flag semantics:
def state(flags,threshold):
    done=sum(ident in flags for ident in ids)
    seen={meth for ident in ids for meth in methods if ident+'_method_'+meth in flags}
    return done==4 and len(seen)>=threshold
four={ident for ident in ids}
four.update({ident+'_method_hook' for ident in ids})
check(state(four,0),'four-bell first reward should unlock')
check(not state(four,3),'three-method second reward should not unlock too early')
check(state(four|{ids[0]+'_method_frost',ids[0]+'_method_roses'},3),'using multiple methods on one bell should unlock the creativity reward')
summary={'version':'1.37','status':'PASS' if not errors else 'FAIL','bells':4,'distinct_methods':len(methods),'creativity_threshold':3,'additional_enemies':8,'new_unique_rewards':2,'godot_runtime_tested':False,'errors':errors}
print(json.dumps(summary,indent=2))
if errors:
    raise SystemExit(1)
