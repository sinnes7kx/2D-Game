"""Static build-sanity for Hollow Veil Moor v1.21; engine playtest still required."""
from pathlib import Path
import re, json, collections, math
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
errors=[]
def check(test, message):
    if not test: errors.append(message)
def rd(p):return (ROOT/p).read_text(encoding='utf-8')
scene=rd('scenes/rooms/hollow_veil_moor.tscn')
player=rd('scripts/player.gd')
spell=rd('scripts/moon_spell.gd')
with Image.open(ROOT/'assets/world/hollow_veil_moor_v118.jpg') as img:
    width,height=img.size
check((width,height)==(10368,6912),'moor dimensions changed unexpectedly')
check(scene.count('[node name="MoorWater')==3,'expected three water Area2D nodes')
check(scene.count('type="CollisionPolygon2D" parent="Gameplay/WaterBodies/')==3,'water collision polygons incomplete')
check(scene.count('type="Node2D" parent="Gameplay/WaterBodies/MoorWater')==3,'water ripple nodes incomplete')
check(scene.count('[node name="MoorRain"')==1,'rain node must be present exactly once')
check('streak_count = 190' in scene and 'intensity = 0.42' in scene,'rain configuration missing')
check('func contains_world_point(world_point: Vector2)' in rd('scripts/water_body.gd'),'water hitbox API missing')
check('var water_label: String' in rd('scripts/water_body.gd'),'water display property missing')
check('func _draw() -> void:' in rd('scripts/moor_rain.gd'),'rain renderer missing')
check('func _draw() -> void:' in rd('scripts/moor_water_ripples.gd'),'water ripple renderer missing')
check(not re.search(r'^#',scene,re.MULTILINE),'invalid # scene comments remain')
for rel in re.findall(r'\[ext_resource[^\n]* path="res://([^"]+)"',scene):
    check((ROOT/rel).exists(),f'missing resource: {rel}')
# validate that child nodes have existing parent paths and no duplicate scene nodes
node_paths=set(); paths=[]; positions={}
for block in re.split(r'(?=^\[node )',scene,flags=re.MULTILINE)[1:]:
    header=block.splitlines()[0]
    m=re.search(r'\bname="([^"]+)"',header)
    p=re.search(r'\bparent="([^"]+)"',header)
    if not m: continue
    name=m.group(1);parent=p.group(1) if p else ''
    path=parent+'/'+name if parent and parent!='.' else name
    check(path not in node_paths,'duplicate scene node path: '+path)
    check(not parent or parent=='.' or parent in node_paths,'missing/out-of-order node parent: '+path)
    node_paths.add(path);paths.append((name,parent,path))
    coords=re.search(r'^position = Vector2\(([-.\d]+), ([-.\d]+)\)',block,re.MULTILINE)
    if coords:positions[path]=tuple(float(c) for c in coords.groups())
# do not count resource instances as bound to levels when their resource references are missing
enemy_paths=[path for name,parent,path in paths if parent=='Gameplay/Enemies']
check(len(enemy_paths)==136,f'expected 136 existing enemies, found {len(enemy_paths)}')
xs=[positions[p][0] for p in enemy_paths if p in positions];ys=[positions[p][1] for p in enemy_paths if p in positions]
check(min(xs)<1500 and max(xs)>9000 and min(ys)<1400 and max(ys)>6000, 'enemies clustered in a corner')
# Room uses 2x2 or more wilderness across measured cells (not original vertical bands)
sectors=set((int(x//1728),int(y//1152)) for x,y in zip(xs,ys))
check(len(sectors)>=19,f'only {len(sectors)} map sectors occupied')
for path in ['Collisions/DeadWillow1/CollisionShape2D','Collisions/DeadWillow2/CollisionShape2D','Collisions/RuinedMonument1/CollisionShape2D']:
    check(path in positions, 'missing aligned obstacle collision: '+path)
# TSCN PackedVector2Array must contain scalar xy pairs, not nested Vector2 values
for polygon in re.findall(r'^polygon = PackedVector2Array\((.*)\)$',scene,re.MULTILINE):
    check('Vector2' not in polygon,'incorrect packed polygon serialization')
    arr=[t.strip() for t in polygon.split(',')]
    check(len(arr)>=6 and len(arr)%2==0,'malformed packed polygon')
check('.call("configure", kind, tint, motif, tier' not in player, 'spectacle version-sensitive call remains')
check('burst.call("configure"' not in player,'melee spectacle still invokes incompatible configure')
check(not re.search(r'(?<![a-zA-Z_])burst\.call\("configure"',spell),'wand spectacle still invokes incompatible configure')
check('burst.set("effect_kind", kind)' in player,'melee hit effect lacks direct init')
check('burst.set("effect_kind", "spell")' in spell,'wand hit effect lacks direct init')
summary={'version':'1.21','status':'PASS' if not errors else 'FAIL','enemy_count':len(enemy_paths),'occupied_sectors':len(sectors),'water_areas':3,'weather':'camera-local rain','errors':errors}
print(json.dumps(summary,indent=2))
if errors:raise SystemExit(1)
