"""Regression and geometry audit for v1.20's integrated Hollow Veil Moor.
Verifies playable scene wiring; Godot F5 remains the runtime acceptance test.
"""
from pathlib import Path
import re, json, hashlib
from PIL import Image

R=Path(__file__).resolve().parents[1]
scene=R/'scenes/rooms/hollow_veil_moor.tscn'
errors=[]
def check(expr,why):
    if not expr: errors.append(why)
text=scene.read_text()

# Primary geography and visible layout
bg=R/'assets/world/hollow_veil_moor_v118.jpg'
check(bg.is_file(), 'painted background missing')
if bg.is_file():
    with Image.open(bg) as im:
        check(im.size==(10368,6912),'expected expanded 10368x6912 painting')
check('path="res://assets/world/hollow_veil_moor_v118.jpg"' in text,'room background not connected')
check('size = Vector2(10368, 76)' in text and 'size = Vector2(76, 6912)' in text,'boundary collision sizes not expanded')

# All scene resources must be real, including new signpost and lantern scripts.
refs=re.findall(r'^\[ext_resource[^\n]* path="(res://[^\"]+)"',text,re.M)
for ref in refs:
    check((R/ref[6:]).is_file(),f'missing scene resource {ref}')

nodes=re.findall(r'^\[node name="([^"]+)"[^\n]*? parent="([^"]+)"',text,re.M)
check(len(nodes)==len(set(nodes)), 'duplicate sibling node names')
for name,token in [('waystones', '[node name="V120LowRoadWaystone"'),('lanterns','[node name="V120PathLantern_01"'),('weight seal','[node name="V120MoonwellPressureRose"')]:
    check(token in text,f'missing {name}')
counts={
    'waystones':len(re.findall(r'^\[node name="V120\w+Waystone"',text,re.M)),
    'guide_lanterns':len(re.findall(r'^\[node name="V120PathLantern_',text,re.M)),
    'new_weak_enemies':len(re.findall(r'^\[node name="V120Moor(?:Wraith|Sentinel)_',text,re.M)),
    'total_enemies':len(re.findall(r'^\[node name="[^"]+" parent="Gameplay/Enemies" instance=',text,re.M)),
    'new_chests':len(re.findall(r'^\[node name="V120[^\"]+" parent="Gameplay/TreasureChests" instance=',text,re.M)),
    'total_chests':len(re.findall(r'^\[node name="[^"]+" parent="Gameplay/TreasureChests" instance=',text,re.M)),
    'new_hidden_rose_secrets':len(re.findall(r'^\[node name="V120(?:SilentOrchard|MourningPond)Rose"',text,re.M)),
    'new_rest_shrines':len(re.findall(r'^\[node name="V120[^\"]+Shrine"',text,re.M)),
}
expected={'waystones':7,'guide_lanterns':11,'new_weak_enemies':44,'total_enemies':136,'new_chests':6,'total_chests':14,'new_hidden_rose_secrets':2,'new_rest_shrines':2}
for k,v in expected.items():check(counts[k]==v,f'{k}: found {counts[k]}, expected {v}')

# No duplicates in persistent save keys.
for label,prefix in [('chest','chest_id'),('discovery','discovery_id')]:
    ids=re.findall(r'^'+prefix+r' = "([^"]+)"',text,re.M)
    check(len(ids)==len(set(ids)),f'duplicate persistent {label} IDs')

# Validate all named target nodes and that the linked extra weight puzzle is in bounds.
for target in ('V120MoonwellCrate','V120MoonwellPressureRose','V120MoonwellGate','V120MoonwellReward','V120SilentOrchardSecretCoffer','V120MourningPondSecretCoffer'):
    check(f'name="{target}"' in text,f'broken / missing node {target}')
for link in ('../../Carryables/V120MoonwellCrate','../../V120MoonwellGate','../TreasureChests/V120MoonwellReward','../../TreasureChests/V120SilentOrchardSecretCoffer','../../TreasureChests/V120MourningPondSecretCoffer'):
    check(link in text,f'broken NodePath {link}')
for x,y in re.findall(r'^position = Vector2\(([-\d.]+), ([-\d.]+)\)',text,re.M):
    # includes boundary nodes, all should remain within the map
    check(0 <= float(x) <= 10368 and 0 <= float(y) <= 6912,f'out-of-bounds scene placement {x},{y}')

# Restore completed weighted switch state on re-entering any room.
game=(R/'scripts/game.gd').read_text()
check('if target.is_in_group("moor_waystone"):' in game,'waystone interaction missing')
check('elif current_target.is_in_group("moor_waystone"):' in game,'waystone HUD hint missing')
check('for node in room_view.get_node("Gameplay/Plates").get_children():' in game and 'node.call("restore_secret", inventory)' in game,'weighted plate restore hook missing')

# Source scripts have expected interface fields to the scene nodes.
way=(R/'scripts/moor_waystone.gd').read_text()
lantern=(R/'scripts/moor_lantern.gd').read_text()
for t in ('add_to_group("interactable")','add_to_group("moor_waystone")','@export var region_title','@export_multiline var route_hint'):
    check(t in way, 'waystone script contract missing '+t)
check('func _draw() -> void:' in lantern,'lantern has no visible world-space artwork')
result={'version':'1.20','status':'PASS' if not errors else 'FAIL','content':counts,'errors':errors}
print(json.dumps(result,indent=2))
if errors: raise SystemExit(1)
