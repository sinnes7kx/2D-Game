"""v1.26 first-pass bows: resource, artwork, input and projectile checks.
Offline structural/image validation only. Godot gameplay test required.
"""
from pathlib import Path
import json, re
from PIL import Image,ImageChops
R=Path(__file__).resolve().parents[1]
issues=[]
def chk(test,msg):
    if not test: issues.append(msg)
def src(name):
    p=R/name;chk(p.is_file(),f'missing {name}');return p.read_text() if p.exists() else ''
manifest=json.loads(src('resources/bow_animations_v126.json'))
loaded=json.loads(src('resources/ghost_extra_animations.json'))
lookup={e['name']:e for e in loaded}
chk(len(manifest)==32,f'expected 32 tracks, got {len(manifest)}')
for track in manifest:
    chk(track['name'] in lookup,f'not installed: {track["name"]}')
    chk(track['frame_count']==8 and track['frame_width']==256 and track['frame_height']==220,'wrong atlas grid')
    chk((R/track['atlas']).is_file(),f'missing atlas {track["atlas"]}')
body=Image.open(R/'assets/ghost/weapon_body_v111/weapon_ready_locomotion_2048x1760.png').convert('RGBA')
count=0
for style in ('thornrose','moonveil'):
    for phase in ('locomotion','combat'):
        name=f'assets/ghost/bows_v126/{style}_{phase}_2048x1760.png'
        im=Image.open(R/name).convert('RGBA')
        chk(im.size==(2048,1760),f'bad size: {name}')
        for row in range(8):
            for frame in range(8):
                tile=im.crop((frame*256,row*220,(frame+1)*256,(row+1)*220))
                chk(tile.getbbox() is not None,f'empty pose {name} row {row} frame {frame}')
                if phase=='locomotion':
                    bare=body.crop((frame*256,row*220,(frame+1)*256,(row+1)*220))
                    chk(ImageChops.difference(tile,bare).getbbox() is not None,f'no bow pixels: {name} {row}/{frame}')
                count+=1
    chk((R/f'assets/ghost/bows_v126/{style}_icon.png').is_file(),f'missing icon: {style}')
    item=src(f'items/{style}_bow.tres')
    for token in (f'item_id = "{style}_bow"','weapon_style = "bow"','equip_slot = "sword"',f'bows_v126/{style}_icon.png'):
        chk(token in item,f'{style} item missing {token}')
itemdef=src('scripts/item_data.gd');inst=src('scripts/item_instance.gd')
chk('"halberd", "bow"' in itemdef,'bow enum not defined')
chk('"bow": return 830.0' in inst,'bow range missing')
player=src('scripts/player.gd');arrow=src('scripts/bow_arrow_v126.gd')
for token in ('BOW_ARROW_SCENE.instantiate()','func _begin_bow_shot(charged: bool, airborne: bool)','func _launch_bow_arrow(heading: Vector2, charged: bool)','_begin_bow_shot(not _from_heavy_button, true)','bow_time_left = 0.0','_bow_art_style() + ("_walk_" if moving else "_idle_")'):
    chk(token in player,f'player bow code missing {token}')
chk(player.find('if _weapon_style() == "bow":') < player.find('elif world.inventory.get_equipped("wand") != null:',player.find('func _begin_weapon_attack')), 'bow does not precede wand for attack')
for token in ('hit_ids.has(target_id)','hit_ids[target_id] = true','hit_ids.size() >= 2','wall_query.collision_mask = 6','query.collision_mask = 16 | 32','queue_free()'):
    chk(token in arrow,f'arrow safety missing {token}')
chk(arrow.count('target.call("hit", damage,')==1,'duplicate damage event path')
scene=src('scenes/rooms/moonwake_crypt.tscn')
for token in ('v126_showcase_thornrose','v126_showcase_moonveil','items/thornrose_bow.tres','items/moonveil_bow.tres'):
    chk(token in scene,f'no showroom bow: {token}')
game=src('scripts/game.gd')
chk('const BOW_LOOT_TABLE' in game and 'posmod(seed_value, 23) == 0' in game,'bow drops not available')
chk(src('scripts/inventory.gd')==(R.parent/'GhostGirl_v125_work/GhostGirl2/scripts/inventory.gd').read_text() if (R.parent/'GhostGirl_v125_work/GhostGirl2/scripts/inventory.gd').exists() else True, 'existing save serialization was changed')
for name in ('scenes/rooms/moonwake_crypt.tscn','scenes/bow_arrow_v126.tscn'):
    text=src(name)
    links=re.findall(r'^\[ext_resource\s+[^\]]*path="res://([^"]+)"[^\]]*id="([^"]+)"[^\]]*\]',text,re.M)
    chk(len({x[1] for x in links})==len(links),f'duplicate ext IDs in {name}')
    for path,_ in links:
        chk((R/path).exists(),f'broken resource reference in {name}: {path}')
    chk(not re.search(r'^\s*#\s',text,re.M),f'invalid # comment in {name}')
print(json.dumps({'version':'1.26','status':'PASS' if not issues else 'FAIL','bow_tracks':len(manifest),'composited_frames':count,'runtime_tested':False,'issues':issues},indent=2))
if issues:raise SystemExit(1)
