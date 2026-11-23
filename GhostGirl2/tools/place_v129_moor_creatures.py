#!/usr/bin/env python3
"""Idempotently add eight small v1.29 creature pockets to Hollow Veil Moor.
Existing enemy placements, scene assets and path geometry remain untouched.
"""
from pathlib import Path
import math, re
ROOT=Path(__file__).resolve().parents[1]
SCENE=ROOT/'scenes/rooms/hollow_veil_moor.tscn'
s=SCENE.read_text()
if '[node name="V129HushMoth' in s:
    print('already placed')
    raise SystemExit()
assert s.startswith('[gd_scene load_steps=37 format=3]')
insert='[ext_resource type="PackedScene" path="res://scenes/moor_creature_v129.tscn" id="v129_creature"]\n'
s=s.replace('[gd_scene load_steps=37 format=3]','[gd_scene load_steps=38 format=3]',1)
last='[ext_resource type="Resource" path="res://items/moonveil_bow.tres" id="v128_moonveil"]\n'
assert last in s
s=s.replace(last,last+insert,1)
# Ground all pocket placement against the current editable map markers.
blocks=re.findall(r'^\[node name="([^\"]+)"[^\]]*parent="([^\"]+)"[^\]]*\]\n(.*?)(?=^\[node |\Z)',s,re.M|re.S)
existing=[]; collision=[]; avoid=[]
for name,parent,body in blocks:
    match=re.search(r'^position = Vector2\(([-\d.]+), ([-\d.]+)\)$',body,re.M)
    if not match:
        continue
    p=(float(match.group(1)),float(match.group(2)))
    if parent=='Gameplay/Enemies': existing.append(p)
    elif parent.startswith('Collisions/') and name=='CollisionShape2D': collision.append(p)
    elif parent in ('SpawnPoints','Gameplay/Portals','Gameplay/V128BloomRelays','Gameplay/V128BowTargets','Gameplay/RestShrines'):
        avoid.append(p)

packs=[
  ('HushMoth', (1850,1310)),('HushMoth',(4030,1840)),('HushMoth',(6490,1370)),('HushMoth',(8940,4890)),
  ('GloomLantern',(2890,4410)),('GloomLantern',(5130,5430)),('GloomLantern',(7650,5610)),('GloomLantern',(9280,2990)),
]
new=[]
def safe(point, for_pack=False):
    x,y=point
    if x < 450 or x>9900 or y<460 or y>6440:
        return False
    if any(math.dist(point,t)< (180 if for_pack else 130) for t in existing):
        return False
    if any(math.dist(point,t)< 110 for t in collision):
        return False
    if any(math.dist(point,t)< 250 for t in avoid):
        return False
    if any(math.dist(point,t)< 60 for t in new):
        return False
    # Water regions: approximate their painted outer envelopes.
    for cx,cy,rx,ry in [(870,3466,910,410),(7675,4377,1130,550),(8870,1927,620,350)]:
        if ((x-cx)/rx)**2+((y-cy)/ry)**2 < 1:
            return False
    return True

out=['','; v1.29: two deliberately weak procedural enemy silhouettes in eight small, spaced pockets.']
for pack_index,(species,center) in enumerate(packs):
    count=3
    offsets=[(-65,45),(72,35),(3,-77)]
    for i,offset in enumerate(offsets):
        target=(center[0]+offset[0],center[1]+offset[1])
        if not safe(target):
            for n in range(1,60):
                theta=n*2.399963
                radius=30+18*math.sqrt(n)
                trial=(round(target[0]+math.cos(theta)*radius,1),round(target[1]+math.sin(theta)*radius,1))
                if safe(trial):
                    target=trial
                    break
            else:
                raise AssertionError(f'Cannot place {species} pocket {pack_index}:{i}')
        new.append(target)
        name=f'V129{species}{pack_index:02d}_{i:02d}'
        out.extend(['',f'[node name="{name}" parent="Gameplay/Enemies" instance=ExtResource("v129_creature")]',
                    f'position = Vector2({target[0]}, {target[1]})',
                    f'creature_kind = "{"hush_moth" if species=="HushMoth" else "gloom_lantern"}"',
                    f'max_health = {13.0 if species=="HushMoth" else 20.0}',
                    f'chase_speed = {112.0 if species=="HushMoth" else 63.0}',
                    f'attack_damage = {3.0 if species=="HushMoth" else 4.0}',
                    f'alert_distance = {320.0 if species=="HushMoth" else 280.0}',
                    f'loot_seed = {129100+pack_index*10+i}'])
s+='\n'.join(out)+'\n'
SCENE.write_text(s)
print('Added',len(new),'new creatures; nearest existing creature:',round(min(math.dist(p,q) for p in new for q in existing),1))
for pack_index,(species,center) in enumerate(packs):
    print(f'{species} {pack_index}: {new[pack_index*3: pack_index*3+3]}')
