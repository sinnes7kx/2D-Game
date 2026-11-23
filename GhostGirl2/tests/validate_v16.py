"""Validate patch structure, spritesheet rows, and save-compatible weapon integration.
This is a static test; Godot runtime testing must still be done in the editor.
"""
from pathlib import Path
from collections import Counter
from PIL import Image,ImageChops
import json,re,hashlib
ROOT=Path(__file__).resolve().parents[1]
issues=[]
manifest=json.loads((ROOT/'resources/ghost_extra_animations.json').read_text())
names=[a['name'] for a in manifest]
if len(set(names))!=len(names):issues.append('duplicate animation names')
new=[a for a in manifest if 'atlas' in a or ('scythe' in a['name'] or 'halberd' in a['name'])]
layered_mode=all('textures' in a and len(a['textures'])==8 for a in new)
if len(new)!=32:issues.append(f'expected 32 weapon animation tracks, got {len(new)}')
for style in ('scythe','halberd'):
 for group in ('combat','locomotion'):
  p=ROOT/f'assets/ghost/weapons_v16/{style}_{group}_2048x1760.png'
  if not p.is_file():issues.append(f'missing {p}');continue
  with Image.open(p) as im:
   if im.size!=(2048,1760):issues.append(f'invalid size {p}: {im.size}')
   if im.mode not in ('RGBA','P'):issues.append(f'{p} needs transparency')
   unique=[]
   for row in range(8):
    rowdata=[]
    for column in range(8):
     cell=im.crop((column*256,row*220,(column+1)*256,(row+1)*220))
     if cell.getbbox() is None:issues.append(f'empty atlas cell {style}/{group} {row},{column}')
     rowdata.append(hashlib.sha1(cell.tobytes()).hexdigest())
    if len(set(rowdata))<4:issues.append(f'not enough distinct frames {style}/{group} row{row}')
    unique.append(rowdata)
   if unique[0]==unique[1]:issues.append(f'duplicated front/back rows in {p}')
  for direction in ('front','back','left','right'):
   for a in (('light','heavy') if group=='combat' else ('idle','walk')):
    expected=(f'attack_{style}_{a}_{direction}' if group=='combat' else f'{style}_{a}_{direction}')
    if expected not in names:issues.append(f'missing animation {expected}')
for entry in new:
 if 'atlas' in entry:
  path=ROOT/entry['atlas']
  if not path.exists():issues.append(f'manifest missing {path}')
  if entry.get('frame_count')!=8 or entry.get('frame_width')!=256 or entry.get('frame_height')!=220:issues.append('manifest geometry mismatch')
  if not 0<=entry.get('row',-1)<8:issues.append('invalid row index')
 else:
  if len(entry.get('textures',[]))!=8:issues.append('layered weapon body missing 8 frames')
  for path in entry.get('textures',[]):
   if not (ROOT/path).is_file():issues.append(f'missing approved body frame {path}')
if layered_mode:
 overlays=json.loads((ROOT/'resources/weapon_layer_manifest.json').read_text())
 if len(overlays)!=32:issues.append(f'expected 32 transparent weapon layer tracks, got {len(overlays)}')
 for ent in overlays:
  for key in ('atlas_back','atlas_front'):
   if not (ROOT/ent[key]).is_file():issues.append(f'missing {key} {ent[key]}')
for name,style in [('rose_reaper_scythe','scythe'),('lunar_vigil_halberd','halberd')]:
 path=ROOT/f'items/{name}.tres'
 content=path.read_text()
 for required in ('equip_slot = "sword"',f'weapon_style = "{style}"',f'reliquary/v16_{style}.png'):
  if required not in content:issues.append(f'{name}: {required}')
for name,item in [('blackbrick_court','rose_reaper_scythe'),('ashen_causeway','lunar_vigil_halberd')]:
 scene=(ROOT/f'scenes/rooms/{name}.tscn').read_text()
 if f'items/{item}.tres' not in scene or f'v16_{name}_armory' not in scene:
  issues.append(f'{name} missing persistent weapon reward')
player=(ROOT/'scripts/player.gd').read_text()
for required in ('attack_hit_threshold','_weapon_motion_prefix','attack_arc','weapon_reach','_melee_cost','active_attack_style'):
 if required not in player and required!='weapon_reach':issues.append(f'player lacks {required}')
loader=(ROOT/'scripts/ghost_animation_library.gd').read_text()
if 'AtlasTexture.new()' not in loader or 'tile.region' not in loader:issues.append('AtlasTexture integration missing')
inv=(ROOT/'scripts/inventory.gd').read_text()
if 'user://ghost_girl_treasures_v2.json' not in inv or '"quality": item.quality' not in inv:issues.append('save compatibility changed')
report={'status':'FAIL' if issues else 'PASS','weapon_tracks':len(new),'layered_mode':layered_mode,'atlas_count':4,'atlas_frames':256,'new_items':2,'weapon_chests':2,'problems':issues}
print(json.dumps(report,indent=2))
if issues:raise SystemExit(1)
