#!/usr/bin/env python3
"""Original procedural gothic moor painting and editor-editable Godot room.
No assets are copied from the reference game or reused as another level.
"""
from pathlib import Path
import math,random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT=Path(__file__).resolve().parents[1]
W,H=4608,3072
random.seed(116116)
rng=np.random.default_rng(116)
out=ROOT/'assets/world/hollow_veil_moor_v116.jpg'
# Mineral-dark lavender grass, pale worn soil, broad irregular winding trails.
xx=np.arange(W,dtype=np.float32)[None,:]
yy=np.arange(H,dtype=np.float32)[:,None]
coarse=Image.fromarray(rng.integers(0,256,(H//45+1,W//45+1),dtype=np.uint8),'L').resize((W,H),Image.Resampling.BICUBIC)
medium=Image.fromarray(rng.integers(0,256,(H//12+1,W//12+1),dtype=np.uint8),'L').resize((W,H),Image.Resampling.BILINEAR)
c=np.asarray(coarse,dtype=np.float32)/255-0.5
m=np.asarray(medium,dtype=np.float32)/255-0.5
micro=rng.normal(0,4.1,(H,W)).astype(np.float32)
ambient=15*c+7*m+micro + 6*np.sin(xx/630.0+yy/790.0)
# Mud path meanders from southwest to northeast; two smaller branches.
center=2600 - 0.43*xx + 128*np.sin(xx/510)+78*np.sin(xx/1130)
dist=np.abs(yy-center)
main=np.clip((122-dist)/65,0,1)
west=np.clip((90-np.abs(yy-(1220+0.55*xx+60*np.sin(xx/280))))/53,0,1)
east=np.clip((82-np.abs(yy-(400+0.28*xx+88*np.sin(xx/430))))/48,0,1)
path=np.maximum(main,np.maximum(west*0.57,east*0.46))
terrain=np.empty((H,W,3),np.uint8)
for k,(grass,soil) in enumerate(zip((36,37,45),(74,64,67))):
    terrain[:,:,k]=np.uint8(np.clip(grass+ambient*(1.00 if k!=2 else 1.25)+(soil-grass)*path,13,145))
del micro,c,m,coarse,medium
im=Image.fromarray(terrain,'RGB').convert('RGBA')
pen=ImageDraw.Draw(im,'RGBA')
# Low-value rust/grey wildflowers and tufts. These preserve full traversability.
for n in range(19000):
    x=random.randrange(100,W-110); y=random.randrange(110,H-125)
    if n%7 == 0:
        color=random.choice([(103,86,92,75),(94,79,103,75),(133,105,93,46),(84,105,92,80)])
        r=random.randint(2,5)
        pen.ellipse((x-r,y-r,x+r,y+r), fill=color)
    else:
        s=random.randint(3,11)
        col=random.choice([(44,68,56,138),(58,79,67,134),(71,67,81,131),(78,81,72,84),(89,85,98,97)])
        pen.line((x,y,x-3,y-s),fill=col,width=1)
        pen.line((x,y,x+4,y-s+1),fill=col,width=1)
# Wet stones, small violet flowers and rusted petals.
for i in range(1800):
    x=random.randint(110,W-110);y=random.randint(110,H-110)
    rx=random.randint(2,11);ry=random.randint(1,5)
    pen.ellipse((x-rx,y-ry,x+rx,y+ry),fill=random.choice([(121,104,116,75),(103,108,122,78),(68,71,82,120)]))
# Cross-shaped weathered gravestones / fallen walls are bespoke marks in ground illustration.
landmarks=[(845,710),(3820,840),(2980,2520),(1560,1890),(4220,2140),(2360,560)]
for x,y in landmarks:
    # soft ellipse shadow behind layered stonework
    pen.ellipse((x-170,y-45,x+180,y+90), fill=(4,7,14,80))
    for j in range(15):
        a=random.uniform(0,TAU:=math.tau)
        r=random.uniform(65,178)
        px=int(x+math.cos(a)*r);py=int(y+math.sin(a)*r*0.55)
        stone=random.choice([(93,87,103,215),(109,99,112,205),(65,67,81,240)])
        pen.rectangle((px-21,py-10,px+20,py+10),fill=stone,outline=(22,24,32,230),width=2)
    pen.ellipse((x-26,y-14,x+26,y+15),fill=(126,99,111,180))
    pen.line((x-11,y-15,x-11,y-76),fill=(121,105,119,215),width=9)
    pen.line((x-30,y-54,x+11,y-54),fill=(121,105,119,205),width=8)
# Dead willows and twisted rose thickets. Sparse enough to traverse.
trunks=[(500,460),(1200,360),(2000,300),(2950,430),(4300,550),(390,1910),(4070,2560),(1450,2770),(3240,2760)]
for x,y in trunks:
    pen.ellipse((x-100,y-25,x+110,y+32),fill=(9,14,19,115))
    pen.line((x,y,x+14,y-195),fill=(29,28,36,220),width=21)
    for j in range(6):
        a=random.uniform(-2.85,-0.35)
        end=(x+14+math.cos(a)*random.randint(95,170),y-195+math.sin(a)*random.randint(80,145))
        pen.line((x+14,y-175,*end),fill=(23,23,29,230),width=random.randint(3,10))
        for k in range(5):
            bx=int((end[0]+x+14)*0.5+random.randint(-40,40));by=int((end[1]+y-175)*0.5+random.randint(-20,20))
            pen.line((bx,by,bx+random.randint(-38,38),by-random.randint(15,59)),fill=(23,25,31,155),width=2)
    for j in range(15):
        dx=random.randint(-120,140);dy=random.randint(-65,58)
        pen.ellipse((x+dx-3,y+dy-3,x+dx+3,y+dy+3),fill=(115,48,83,149))
# Broken path lamplights, subtle amber pooling.
for x,y in [(780,2240),(1750,1800),(2710,1240),(3750,1010),(3920,2240)]:
    pen.ellipse((x-70,y-40,x+70,y+40),fill=(126,78,55,30))
    pen.line((x,y,x,y-71),fill=(34,32,38,240),width=6)
    pen.line((x-7,y-65,x+7,y-65),fill=(153,125,91,200),width=4)
    pen.ellipse((x-9,y-83,x+9,y-65),fill=(248,166,107,230))
    pen.ellipse((x-4,y-82,x+4,y-71),fill=(255,220,160,235))
# Cold vignette, using low resolution mask for efficiency.
mini=np.mgrid[0:192,0:288].astype(np.float32)
u=(mini[1]-144)/144;v=(mini[0]-96)/96
vignette=np.clip((u*u+v*v-0.17)*24,0,20).astype('uint8')
vignette=Image.fromarray(vignette,'L').resize((W,H),Image.Resampling.BILINEAR)
from PIL import ImageChops
shade=Image.new('RGBA',(W,H),(5,7,16,0));shade.putalpha(vignette)
im=Image.alpha_composite(im,shade).convert('RGB')
out.parent.mkdir(parents=True,exist_ok=True)
im.save(out,quality=90,subsampling=0,optimize=True)
print('Generated',out,out.stat().st_size)

# Static Godot scene assembled from individually editable gameplay nodes.
scene=ROOT/'scenes/rooms/hollow_veil_moor.tscn'
s=[]
s += ['[gd_scene load_steps=17 format=3]','','[ext_resource type="Texture2D" path="res://assets/world/hollow_veil_moor_v116.jpg" id="bg"]','[ext_resource type="Script" path="res://scripts/portal.gd" id="portal"]','[ext_resource type="PackedScene" path="res://scenes/rose_wraith.tscn" id="wraith"]','[ext_resource type="PackedScene" path="res://scenes/gothic_hunter.tscn" id="hunter"]','[ext_resource type="PackedScene" path="res://scenes/treasure_chest.tscn" id="chest"]','[ext_resource type="Script" path="res://scripts/hook_anchor.gd" id="anchor"]','[ext_resource type="Resource" path="res://items/moon_gem.tres" id="gem"]','[ext_resource type="Resource" path="res://items/rose_reaper_scythe.tres" id="scythe"]','[ext_resource type="Resource" path="res://items/briar_wand.tres" id="wand"]','[ext_resource type="PackedScene" path="res://scenes/carryable.tscn" id="crate"]','']
for axis,width,height in [('North',W,76),('South',W,76),('West',76,H),('East',76,H)]:
    s += [f'[sub_resource type="RectangleShape2D" id="lim{axis}"]',f'size = Vector2({width}, {height})','']
s += ['[sub_resource type="CircleShape2D" id="grave_shape"]','radius = 62.0','','[sub_resource type="CircleShape2D" id="tree_shape"]','radius = 27.0','','[node name="HollowVeilMoor" type="Node2D"]','','[node name="PaintedRoom" type="Sprite2D" parent="."]','texture = ExtResource("bg")','centered = false','z_index = -50','','[node name="Collisions" type="Node2D" parent="."]','']
for axis,point in [('North',(W//2,38)),('South',(W//2,H-38)),('West',(38,H//2)),('East',(W-38,H//2))]:
    s += [f'[node name="{axis}Boundary" type="StaticBody2D" parent="Collisions"]','collision_layer = 2','collision_mask = 0','',f'[node name="CollisionShape2D" type="CollisionShape2D" parent="Collisions/{axis}Boundary"]',f'position = Vector2({point[0]}, {point[1]})',f'shape = SubResource("lim{axis}")','']
s += ['[node name="SpawnPoints" type="Node2D" parent="."]','', '[node name="Default" type="Marker2D" parent="SpawnPoints"]','position = Vector2(720, 2670)','', '[node name="From_briar_hollow" type="Marker2D" parent="SpawnPoints"]','position = Vector2(715, 2660)','', '[node name="From_moonthorn_woods" type="Marker2D" parent="SpawnPoints"]','position = Vector2(4000, 480)','', '[node name="Gameplay" type="Node2D" parent="."]','', '[node name="Portals" type="Node2D" parent="Gameplay"]','', '[node name="briar_hollow" type="Node2D" parent="Gameplay/Portals"]','position = Vector2(560, 2870)','script = ExtResource("portal")','interaction_name = "Return to Briar Hollow"','destination = "briar_hollow"','opened = true','', '[node name="moonthorn_woods" type="Node2D" parent="Gameplay/Portals"]','position = Vector2(4190, 365)','script = ExtResource("portal")','interaction_name = "Enter Moonthorn Woods"','destination = "moonthorn_woods"','opened = true','']
for bucket in ['Carryables','Plates','PuzzlePieces','VisualClues','Memories','Collectibles','TreasureChests','Enemies','HookAnchors','FutureSecrets','WaterBodies','Effects']:
    s += [f'[node name="{bucket}" type="Node2D" parent="Gameplay"]','']
for n,(x,y,item) in enumerate([(3150,2420,'gem'),(4170,1690,'wand'),(1510,580,'scythe')]):
    s += [f'[node name="HiddenCoffer{n+1}" parent="Gameplay/TreasureChests" instance=ExtResource("chest")]',f'position = Vector2({x}, {y})',f'chest_id = "v116_hollow_veil_cache_{n+1}"',f'loot_data = ExtResource("{item}")',f'loot_seed = {116600+n*799}',f'guaranteed_quality = "{["normal","magic","rare"][n]}"','']
for n,(x,y) in enumerate([(1200,790),(2450,1690),(3550,2370),(4250,1160),(2250,2500),(3550,660)]):
    s += [f'[node name="RoseAnchor{n+1}" type="Node2D" parent="Gameplay/HookAnchors"]',f'position = Vector2({x}, {y})','script = ExtResource("anchor")','']
# Pockets of fragile enemies + comparatively rare elites. Starting lawn is empty.
clusters=[(1100,2280,5),(1500,1940,4),(1970,2450,5),(2470,2150,4),(2930,2730,5),(3620,2480,4),
(4170,2020,4),(3780,1630,4),(3100,1580,5),(2480,1220,4),(1780,1220,5),(1000,1250,4),
(1050,650,4),(1900,490,3),(2870,650,4),(3910,700,4)]
random.seed(11666)
roster=[]
for i,(cx,cy,num) in enumerate(clusters):
    for j in range(num):
        x=max(200,min(W-200,cx+random.randint(-125,125)))
        y=max(200,min(H-180,cy+random.randint(-110,110)))
        if j==0 and i in [2,8,13]:
            who='hunter';health=85;damage=10;speed=87;elite=True;archetype='blade_hunter'
        elif j==0 and i%3==1:
            who='hunter';health=18;damage=3;speed=75;elite=False;archetype='mourner'
        else:
            who='wraith';health=12 if (i+j)%4!=0 else 15;damage=3;speed=77;elite=False;archetype=''
        roster.append((who,x,y,health,damage,speed,elite,archetype))
        name=f'Moor_{i:02d}_{j:02d}'
        s += [f'[node name="{name}" parent="Gameplay/Enemies" instance=ExtResource("{who}")]',f'position = Vector2({x}, {y})']
        if who=='wraith':
            s += [f'max_health = {float(health)}',f'damage_to_player = {float(damage)}',f'move_speed = {float(speed)}','aggro_radius = 310.0']
        else:
            s += [f'archetype = "{archetype}"',f'maximum_health = {float(health)}',f'strike_damage = {float(damage)}',f'move_speed = {float(speed)}','notice_range = 360.0',f'is_elite = {str(elite).lower()}','windup_duration = 0.72', 'loot_template = ExtResource("gem")' if elite else '']
        s += ['']
# Painted landmarks gain corresponding physical obstacles for honest traversal.
for n,(x,y) in enumerate(landmarks):
    s += [f'[node name="RuinedMonument{n+1}" type="StaticBody2D" parent="Collisions"]', 'collision_layer = 2', 'collision_mask = 0', '', f'[node name="CollisionShape2D" type="CollisionShape2D" parent="Collisions/RuinedMonument{n+1}"]', f'position = Vector2({x}, {y})', 'shape = SubResource("grave_shape")', '']
for n,(x,y) in enumerate(trunks):
    s += [f'[node name="DeadWillow{n+1}" type="StaticBody2D" parent="Collisions"]', 'collision_layer = 2', 'collision_mask = 0', '', f'[node name="CollisionShape2D" type="CollisionShape2D" parent="Collisions/DeadWillow{n+1}"]', f'position = Vector2({x}, {y})', 'shape = SubResource("tree_shape")', '']
for n,(x,y) in enumerate([(1330,2030),(2100,1550),(3400,1150),(3730,2730)]):
    s += [f'[node name="MoorCrate{n+1}" parent="Gameplay/Carryables" instance=ExtResource("crate")]', f'position = Vector2({x}, {y})','']
scene.write_text('\n'.join(s))
(ROOT/'docs/V116_ENEMY_DENSITY.json').write_text(__import__('json').dumps({'level':'Hollow Veil Moor','size':[W,H],'enemy_count':len(roster),'small_enemies':sum(not e[6] for e in roster),'elites':sum(e[6] for e in roster),'groups':len(clusters),'enemy_positions':[(e[1],e[2]) for e in roster]},indent=2))
print('Scene',scene,'enemies',len(roster),'clusters',len(clusters))
