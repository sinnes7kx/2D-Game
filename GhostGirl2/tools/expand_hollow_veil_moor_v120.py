#!/usr/bin/env python3
"""Append authored v1.20 Moor gameplay additions to the v1.19 expanded room.
All placements are editor-owned nodes. Existing content, art, and saves retained.
Safe to rerun: removes prior v1.20 appended section first.
"""
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parents[1]
SCENE = ROOT/'scenes/rooms/hollow_veil_moor.tscn'
MARKER = '\n# ===== V1.20: MOOR WAYSTONES, PATROLS, AND SIDE ROUTES =====\n'
s=SCENE.read_text()
if MARKER in s:
    s=s.split(MARKER)[0]
if '[ext_resource type="Script" path="res://scripts/moor_waystone.gd" id="v120_waystone"]' not in s:
    needle='[ext_resource type="Script" path="res://scripts/lantern_shrine.gd" id="v117_shrine"]\n'
    assert needle in s
    s=s.replace(needle,needle + '[ext_resource type="Script" path="res://scripts/moor_waystone.gd" id="v120_waystone"]\n[ext_resource type="Script" path="res://scripts/moor_lantern.gd" id="v120_lantern"]\n[ext_resource type="Script" path="res://scripts/weighted_rose_plate.gd" id="v120_plate"]\n')
s=s.replace('[gd_scene load_steps=22 format=3]','[gd_scene load_steps=25 format=3]')
parts=[MARKER]
def append(t): parts.append(t+'\n')
append('[node name="Waystones" type="Node2D" parent="Gameplay"]')
append('[node name="PathLanterns" type="Node2D" parent="Gameplay"]')

waystones=[
    ('LowRoad', (1390,5730),'The Low Lantern Road','Briar Hollow to the southwest; crossroads northeast.',(0.8,-0.4)),
    ('MossGraves', (3030,4950),'The Moss Graves','Follow the warm lamps east to the crossroads.',(1,-0.2)),
    ('Crossroads', (5150,3750),'The Weeping Crossroads','Southwest: Briar Hollow. Northeast: Moonthorn Woods.',(0.9,-0.6)),
    ('Moonwell', (6510,4990),'The Sunken Moonwell','Detour south to a rose weight seal; return north.',(-0.8,-0.5)),
    ('CrescentRise', (7350,2580),'Crescent Rise','The northern trail goes to Moonthorn Woods.',(0.8,-0.6)),
    ('LilyFen', (8610,4750),'The Silted Lily Fen','Keep northwest to find the lamp-lit high path.',(-1,-0.6)),
    ('NorthWatch', (9170,1370),'The North Watch','Moonthorn Woods is nearby to the northeast.',(1,-0.7)),
]
for name,xy,title,info,arrow in waystones:
    ax,ay=arrow
    append(f'''[node name="V120{name}Waystone" type="Node2D" parent="Gameplay/Waystones"]
position = Vector2({xy[0]}, {xy[1]})
script = ExtResource("v120_waystone")
region_title = "{title}"
route_hint = "{info}"
arrow_direction = Vector2({ax}, {ay})''')

lamps=[(1570,5630),(2430,5240),(3590,4630),(4520,4040),(5420,3550),(6280,3110),(7210,2560),(8350,1860),(8900,1460),(6710,4650),(7770,5190)]
for i,(x,y) in enumerate(lamps,1):
    append(f'''[node name="V120PathLantern_{i:02d}" type="Node2D" parent="Gameplay/PathLanterns"]
position = Vector2({x}, {y})
script = ExtResource("v120_lantern")''')

# Optional rest stations keep travel humane without making the area tiny.
for name,pos in [('Crossroads',(4810,3780)),('Moonwell',(6930,5160))]:
    append(f'''[node name="V120{name}Shrine" type="Node2D" parent="Gameplay/RestShrines"]
position = Vector2({pos[0]}, {pos[1]})
script = ExtResource("v117_shrine")
shrine_id = "v120_moor_{name.lower()}_shrine"
interaction_name = "Rest at the {name.lower()} lantern"''')

# Three accessible roadside rewards: no artificial rarity inflation.
chests=[
    ('OldRoadCache',(2760,5470),'gem',120010,'normal'),
    ('GravePathCache',(3690,3170),'scythe',120025,'magic'),
    ('LilyFenCache',(8970,5100),'gem',120040,'normal'),
]
for name,pos,loot,seed,quality in chests:
    append(f'''[node name="V120{name}" parent="Gameplay/TreasureChests" instance=ExtResource("chest")]
position = Vector2({pos[0]}, {pos[1]})
chest_id = "v120_moor_{name.lower()}"
loot_data = ExtResource("{loot}")
loot_seed = {seed}
guaranteed_quality = "{quality}"''')

# Two detour secrets revealed by rose-hook. Uses the existing save-compatible code.
for name,pos,rose_pos,loot,seed,quality in [
    ('SilentOrchard',(3140,2340),(2900,2460),'wand',120110,'magic'),
    ('MourningPond',(8030,5830),(7800,5660),'gem',120125,'normal'),
]:
    append(f'''[node name="V120{name}SecretCoffer" parent="Gameplay/TreasureChests" instance=ExtResource("chest")]
position = Vector2({pos[0]}, {pos[1]})
chest_id = "v120_moor_{name.lower()}_coffer"
loot_data = ExtResource("{loot}")
loot_seed = {seed}
guaranteed_quality = "{quality}"''')
    append(f'''[node name="V120{name}Rose" type="Node2D" parent="Gameplay/HookAnchors"]
position = Vector2({rose_pos[0]}, {rose_pos[1]})
script = ExtResource("v117_secret")
discovery_id = "v120_moor_{name.lower()}_revealed"
secret_chest = NodePath("../../TreasureChests/V120{name}SecretCoffer")''')

# A practical pull-or-carry crate puzzle with a linked, truly locked coffer.
append('''[node name="V120MoonwellCrate" parent="Gameplay/Carryables" instance=ExtResource("crate")]
position = Vector2(5830, 5790)''')
append('''[node name="V120MoonwellReward" parent="Gameplay/TreasureChests" instance=ExtResource("chest")]
position = Vector2(6650, 5710)
chest_id = "v120_moor_moonwell_weight_reward"
loot_data = ExtResource("scythe")
loot_seed = 120160
guaranteed_quality = "magic"''')
append('''[node name="V120MoonwellGate" type="StaticBody2D" parent="Gameplay"]
position = Vector2(6490, 5700)
script = ExtResource("v117_gate")
chest_path = NodePath("../TreasureChests/V120MoonwellReward")''')
append('''[node name="CollisionShape2D" type="CollisionShape2D" parent="Gameplay/V120MoonwellGate"]
shape = SubResource("v117_seal_shape")''')
append('''[node name="V120MoonwellPressureRose" type="Node2D" parent="Gameplay/Plates"]
position = Vector2(6220, 5700)
script = ExtResource("v120_plate")
crate_path = NodePath("../../Carryables/V120MoonwellCrate")
gate_path = NodePath("../../V120MoonwellGate")
discovery_id = "v120_moor_moonwell_weight_seal"''')

# 10 compact, independently separated packs. Avoid spawning directly on the road
# and keep each pack's aggro radius small to preserve free roaming.
centers=[
    (2800,4200),(3550,2600),(4320,5350),(4900,2550),(5600,4450),
    (6230,2110),(7100,3950),(8040,3230),(8470,5720),(9160,3650),
]
rng=random.Random(1202020)
added=0
for pack,(cx,cy) in enumerate(centers,1):
    for mob in range(4):
        x=int(cx+rng.uniform(-150,150));y=int(cy+rng.uniform(-116,116))
        life=[9,11,13,10][mob]
        append(f'''[node name="V120MoorWraith_{pack:02d}_{mob:02d}" parent="Gameplay/Enemies" instance=ExtResource("wraith")]
position = Vector2({x}, {y})
max_health = {life}.0
damage_to_player = 2.0
move_speed = 66.0
aggro_radius = 250.0''')
        added+=1

# A few recognizable, still forgiving warders at scenic locations.
for number,(x,y) in enumerate([(3660,3450),(5750,2450),(7600,4450),(9080,2070)],1):
    append(f'''[node name="V120MoorSentinel_{number:02d}" parent="Gameplay/Enemies" instance=ExtResource("hunter")]
position = Vector2({x}, {y})
archetype = "mourner"
maximum_health = 20.0
strike_damage = 3.0
move_speed = 67.0
notice_range = 320.0
windup_duration = 0.85
is_elite = false''')
    added+=1

SCENE.write_text(s+'\n'.join(parts))
print(f'Added {len(waystones)} waystones, {len(lamps)} lamps, {added} weaker enemies, 6 chests, 2 hidden hook stashes, 1 weight puzzle.')
