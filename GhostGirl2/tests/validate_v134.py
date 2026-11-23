"""Ghost Girl v1.34 — The Last Vigil, strict static integration checks.
Does NOT claim that Godot editor loading or F5 runtime behavior was tested.
"""
from pathlib import Path
import hashlib, json, re, sys
R=Path(__file__).resolve().parents[1]
BASE=R.parent/'GhostGirl_v133_work'
issues=[]
def chk(cond, msg):
    if not cond: issues.append(msg)
def source(rel):
    p=R/rel
    chk(p.is_file(), 'missing '+rel)
    return p.read_text(encoding='utf8') if p.exists() else ''

scene=source('scenes/rooms/hollow_veil_moor.tscn')
script=source('scripts/vesper_vigil_v134.gd')
game=source('scripts/game.gd')
warden=source('scripts/moor_warden_v132.gd')
fx=source('scripts/warden_attack_echo_v134.gd')
story=source('scripts/moor_story_slab_v134.gd')
relic=source('items/v134/vesperglass_wand.tres')

chk(scene.endswith('\n'), 'room missing final newline')
chk(not any(x.lstrip().startswith('#') for x in scene.splitlines()), 'tscn invalid # comment')
chk(not any(x.startswith('<<<<<<<') for x in scene.splitlines()), 'merge markers in tscn')
nres=len(re.findall(r'^\[(?:ext_resource|sub_resource) ',scene,re.M))
m=re.search(r'^\[gd_scene load_steps=(\d+) format=3\]$',scene,re.M)
chk(bool(m) and int(m.group(1)) == nres+1, 'incorrect load_steps in room')
paths={'.'}
for linno,line in enumerate(scene.splitlines(),1):
    if line.startswith('[ext_resource '):
        mpath=re.search(r'path="res://([^"]+)"',line)
        chk(bool(mpath),f'malformed resource at line {linno}')
        if mpath: chk((R/mpath.group(1)).is_file(),f'missing resource at line {linno}: {mpath.group(1)}')
    if line.startswith('[node '):
        match=re.search(r'\bname="([^"]+)".*?\bparent="([^"]+)"',line)
        if match:
            name,parent=match.groups()
            chk(parent in paths, f'unknown parent {parent} at line {linno}')
            full=name if parent=='.' else parent+'/'+name
            chk(full not in paths, f'duplicate node {full}')
            paths.add(full)

for node in ('V134VesperVigil','V134VesperCircle','V134VesperGate','V134VesperChest','V134WarningStone','V134InscriptionOne','V134InscriptionTwo'):
    chk(scene.count(f'[node name="{node}"')==1, 'missing/duplicate '+node)
for key in ('v134_vesperglass_wand_reward','v134_vesper_vigil_completed'):
    chk(key in scene or key in script, 'missing persistent ID '+key)
for frag in ('gate_path = NodePath("../../V134VesperGate")','wave_container_path = NodePath("../../Enemies")','chest_path = NodePath("../TreasureChests/V134VesperChest")','loot_data = ExtResource("v134_wand")','guaranteed_quality = "unique"'):
    chk(frag in scene,'missing scene linkage '+frag)
for tok in ('const REQUIRED_TIME: float = 18.0','const HOLD_RADIUS: float = 190.0','func restore_from_inventory(save_data: Node)','func try_begin() -> String:','func _spawn_wave(index: int)','func _complete()','inventory.call("save_game")','flags[COMPLETE_ID] = true','moth.set("loot_template", null)','moth.position = container.to_local(world_point)','_clear_waves()'):
    chk(tok in script, 'vigil mechanic missing '+tok)
for tok in ('Gameplay/V134VesperVigil','"v134_vesper_vigil"','"v134_story_slab"','target.call("try_begin")'):
    chk(tok in game,'game wiring missing '+tok)
chk('item_id = "v134_vesperglass_wand"' in relic and 'unique = true' in relic and 'stat_id = "spell_power_pct"' in relic, 'unique wand definition invalid')
chk('res://scripts/warden_attack_echo_v134.gd' in warden and '_release_attack_echo()' in warden,'boss release effect not wired')
chk(warden.count('girl.call("receive_damage", amount, global_position)')==1,'Warden damage path duplicated')
chk('call("receive_damage"' not in fx and 'call("hit"' not in fx and 'CollisionShape2D.new' not in fx, 'cosmetic boss FX changes damage/collision')
chk('extends Node2D' in story and 'inscription' in story,'story nodes missing text or art')
# No changes to the approved art, old spells, or equipment save file.
for rel in ('assets/world/hollow_veil_moor_v118.jpg','resources/ghost_extra_animations.json','resources/weapon_layer_manifest.json','scripts/inventory.gd','scripts/player.gd','scripts/moonfall_blizzard.gd','scripts/bow_arrow_v126.gd','scripts/bellglass_echo_v133.gd'):
    chk((R/rel).is_file() and (BASE/rel).is_file() and hashlib.sha256((R/rel).read_bytes()).digest()==hashlib.sha256((BASE/rel).read_bytes()).digest(),'unexpected change to '+rel)
# Unique interaction node is placed in navigable bounds, not stacked on Warden.
match=re.search(r'^\[node name="V134VesperCircle"[^\n]*\nposition = Vector2\(([-\d.]+), ([-\d.]+)\)',scene,re.M)
chk(bool(match),'circle has no position')
if match:
    x,y=map(float,match.groups())
    chk(100<x<10268 and 100<y<6812,'circle out of room')
    chk(((x-6400)**2+(y-1570)**2)**0.5>700,'circle overlaps Warden arena')
print(json.dumps({'release':'v1.34','result':'PASS' if not issues else 'FAIL','new_mechanics':['18-second hold-ground ritual','3 staged waves of temporary low-HP enemies','unique saved reward','3 boss attack release visuals','2 story inscriptions'],'scene_resources':nres,'verified_game_engine':False,'problems':issues},indent=2))
if issues:sys.exit(1)
