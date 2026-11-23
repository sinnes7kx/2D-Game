"""Ghost Girl v1.36: Chainfall environmental gameplay checks.
This is structural/source validation, NOT an in-engine F5 gameplay test.
"""
from pathlib import Path
import json, re, hashlib
R = Path(__file__).resolve().parents[1]
BASE = R.parent / 'GhostGirl_v135_work'
errors=[]
def check(condition, note):
    if not condition: errors.append(note)
def read(rel):
    p=R/rel
    check(p.is_file(),f'missing {rel}')
    return p.read_text(encoding='utf-8') if p.is_file() else ''
scene=read('scenes/rooms/hollow_veil_moor.tscn')
header=re.search(r'^\[gd_scene load_steps=(\d+) format=3\]',scene,re.M)
exts=re.findall(r'^\[ext_resource[^\n]+\]',scene,re.M)
subs=re.findall(r'^\[sub_resource[^\n]+\]',scene,re.M)
check(header is not None,'invalid Godot text scene header')
if header: check(int(header.group(1)) == len(exts)+len(subs)+1,'wrong load_steps')
check(not re.search(r'^\s*#',scene,re.M),'illegal # comments in tscn')
ids=re.findall(r'^\[ext_resource[^\n]*\bid="([^"\n]+)"',scene,re.M)
sub_ids=re.findall(r'^\[sub_resource[^\n]*\bid="([^"\n]+)"',scene,re.M)
check(len(ids)==len(set(ids)),'duplicate ext_resource ids')
check(len(sub_ids)==len(set(sub_ids)),'duplicate sub_resource ids')
for id in re.findall(r'ExtResource\("([^"\n]+)"\)',scene):
    check(id in ids,f'unresolved ExtResource({id})')
for id in re.findall(r'SubResource\("([^"\n]+)"\)',scene):
    check(id in sub_ids,f'unresolved SubResource({id})')
for rel in re.findall(r'^\[ext_resource[^\n]*path="res://([^"\n]+)"',scene,re.M):
    check((R/rel).is_file(),f'missing referenced scene file {rel}')
# Verify all directly-declared node parents resolve.
nodes=re.findall(r'^\[node name="([^"\n]+)"[^\n]*?(?:parent="([^"\n]+)")?[^\n]*\]$',scene,re.M)
known=set(); missing_parents=[]
for name,parent in nodes:
    if not parent:
        known.add('')
        continue
    if parent=='.':
        full=name
    else:
        if parent not in known: missing_parents.append((name,parent))
        full=parent+'/'+name
    known.add(full)
check(not missing_parents, f'unknown node parents: {missing_parents[:10]}')
start=scene.find('; BEGIN V136 CHAINFALL')
check(start!=-1,'missing new scene segment')
new=scene[start:] if start>=0 else ''
check(len(re.findall(r'^site_id = "v136_',new,re.M))==6,'should be 6 new persistent chain supports')
check(len(re.findall(r'accepted_source_site = "v136_',new))==4,'should have four ordered downstream links')
check(new.count('chain_only = true')==4,'must require debris for the four downstream supports')
check(new.count('starting_support = true')==2,'need two starter supports')
check(len(re.findall(r'script = ExtResource\("v136_cover"\)',new))==4,'need four destructible cover pieces')
check(len(re.findall(r'script = ExtResource\("v136_chain"\)',new))==6,'six chain supports are not wired')
check(new.count('shape = SubResource("v136_anchor_shape")')==6,'missing chain hitbox shape')
check(new.count('shape = SubResource("v136_cover_shape")')==4,'missing cover shape')
check(new.count('guaranteed_quality = "unique"')==2,'expected 2 unique chain rewards')
check(len(re.findall(r'parent="Gameplay/Enemies" instance=ExtResource\("v129_creature"\)',new))==8,'need eight low-health enemies')
for site in ['west_first','west_second','west_final','east_first','east_second','east_final']:
    check(f'site_id = "v136_{site}"' in new,f'missing v136_{site}')
for region in ['West','East']:
    for part in ['ChainSeal','ChainGate','ChainChest']:
        check(f'V136{region}{part}' in new,f'missing {region} {part}')
    check(f'required_sites = PackedStringArray("v136_{region.lower()}_first", "v136_{region.lower()}_second", "v136_{region.lower()}_final")' in new,'reward requirements not persisted')
    check(f'chest_id = "v136_{region.lower()}_chain_reward"' in new,'reward chest id missing')
    check(f'gate_path = NodePath("../../V136{region}ChainGate")' in new,'gate linkage missing')

support=read('scripts/chain_support_v136.gd')
base=read('scripts/collapse_support_v135.gd')
debris=read('scripts/falling_debris_v135.gd')
cover=read('scripts/breakable_cover_v136.gd')
hook=read('scripts/rose_hook.gd')
for token in ['func on_falling_debris_impact(', 'source_id != accepted_source_site','starting_support','chain_only','_complete_chain','super._collapse']:
    if token=='super._collapse': continue
    check(token in support, f'chain support missing {token}')
check('source_site_id' in base and 'falling.set("source_site_id", site_id)' in base, 'support does not propagate unique site id')
check('get_tree().call_group("v136_chain_receivers", "on_falling_debris_impact"' in debris,'falling debris does not trigger chain on impact')
check('if not struck and age >= warning_seconds' in debris,'debris lacks impact warning')
check('hit_ids' not in debris or debris.count('enemy.call("hit"') <= 1,'repeated hazard enemy hit path')
for t in ['extends StaticBody2D','func on_hook_latched()','func receive_damage(', 'add_to_group("hook_switch")', 'add_to_group("breakable_cover")','if broken:', 'set_deferred("collision_layer", 0)']:
    check(t in cover,'cover lacks '+t)
check('func _hook_switch_ancestor(hit_node: Node)' in hook and 'picked = mechanism if mechanism != null' in hook,'hook is still aiming at the collision child')
for rel in ['items/v136/chainwake_amulet.tres','items/v136/mourning_girder_bow.tres']:
    item=read(rel)
    check('unique = true' in item,'item not unique '+rel)
    for p in re.findall(r'path="res://([^"\n]+)"',item):
        check((R/p).is_file(),f'item missing art/script {p}')
# Verify no existing character painting / save file is modified.
for rel in ['assets/world/hollow_veil_moor_v118.jpg','resources/ghost_extra_animations.json','scripts/inventory.gd']:
    a=R/rel; b=BASE/rel
    if a.is_file() and b.is_file():
        check(hashlib.sha256(a.read_bytes()).digest()==hashlib.sha256(b.read_bytes()).digest(),f'unexpected changes to {rel}')
result={'version':'1.36','status':'PASS' if not errors else 'FAIL','chain_supports':6,'chain_receivers':4,'breakable_cover':4,'new_weak_enemies':8,'unique_rewards':2,'scene_ext_resources':len(exts),'scene_sub_resources':len(subs),'engine_playtest':False,'errors':errors}
print(json.dumps(result,indent=2))
if errors: raise SystemExit(1)
