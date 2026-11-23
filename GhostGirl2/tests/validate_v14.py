#!/usr/bin/env python3
from pathlib import Path
from PIL import Image
import re, json
P=Path(__file__).resolve().parents[1]
frames=(P/'resources/ghost_girl_frames.tres').read_text()
player=(P/'scripts/player.gd').read_text()
inventory=(P/'scripts/inventory.gd').read_text()
game=(P/'scripts/game.gd').read_text()
refs=set(re.findall(r'^\[ext_resource[^\n]+ id="([^"]+)"\]',frames,re.M))
assert len(refs)==len(re.findall(r'^\[ext_resource',frames,re.M)), 'duplicate resource IDs'
assert frames.rstrip().endswith('}]')
expected={}
for weapon in ('unarmed','sword'):
    for weight in ('light','heavy'):
        for direction in ('front','back','left','right'):
            name=f'attack_{weapon}_{weight}_{direction}'
            match=re.search(r'"frames": \[([^]]+)\],\s*"loop": 0,\s*"name": &"'+name+r'"',frames)
            assert match,name
            ids=re.findall(r'ExtResource\("([^"]+)"\)',match.group(1))
            assert len(ids)==8,(name,len(ids))
            assert all(x in refs for x in ids),name
            expected[name]=len(ids)
for weapon in ('unarmed','sword'):
    atlas=P/f'art_sources/combat_v14/GhostGirl_{weapon}_attacks_2048x1760.png'
    with Image.open(atlas) as img:
        assert img.size==(2048,1760) and img.mode=='RGBA'
    for f in (P/'assets/ghost/combat_v14').glob(f'attack_{weapon}_*.png'):
        with Image.open(f) as im:
            assert im.size==(256,220) and im.mode=='RGBA'
assert len(list((P/'assets/ghost/combat_v14').glob('*.png')))==128
assert len(list((P/'assets/ghost/combat_v12').glob('*.png')))==64
assert all((P/'assets/ghost/combat_v12'/f'attack_{w}_{d}_{i:02d}.png').exists()
    for w in ('light','heavy') for d in ('front','back','left','right') for i in range(8))
assert 'attack_unarmed_heavy_' in player and 'attack_sword_light_' in player
assert 'get_equipped("sword")' in player and 'weapon_damage()' in player
assert 'var equipment: Dictionary' in inventory and '"sword": -1' in inventory
assert '"wand"] = -1' in inventory and '"sword"] = -1' in inventory
assert '"sword"' in (P/'scripts/equipment_panel.gd').read_text()
assert 'Sword" type="Button"' in (P/'scenes/equipment_panel.tscn').read_text()
assert 'user://ghost_girl_treasures_v2.json' in inventory
assert 'Dusk Needle' in (P/'items/dusk_needle.tres').read_text()
assert len(list((P/'items').glob('*sword*.tres')))+len([f for f in (P/'items').glob('*.tres') if any(s in f.name for s in ('needle','sabre','rapier','falchion','grandblade'))])>=5
assert '_grant_v14_first_sword' in game and '_roll_sword_drop' in game
assert 'Hover to compare' in (P/'scripts/inventory_panel.gd').read_text()
print(json.dumps({"result":"passed","new_tracks":len(expected),"new_animation_frames":128,
    "restored_v12_frames":64,"new_swords":6,"atlases":"2 x 2048x1760"}))
