"""v1.9 static validation of artist-keyed, synchronized two-plane weapon overlays.
This cannot replace a real F5 playtest in Godot 4.
"""
from pathlib import Path
from PIL import Image
import json,re,hashlib

R=Path(__file__).resolve().parents[1]
errors=[]
def need(ok,msg):
 if not ok:errors.append(msg)

body=json.loads((R/'resources/ghost_extra_animations.json').read_text())
layer=json.loads((R/'resources/weapon_layer_manifest.json').read_text())
bodyby={e['name']:e for e in body}
layerby={e['name']:e for e in layer}
need(len(layer)==32 and len(layerby)==32,'must have exactly 32 distinct layered animation tracks')
need(len(bodyby)==len(body),'body animation names duplicated')
oldpaths=set()
for style in ['scythe','halberd']:
 for family in ['locomotion','combat']:
  src=R/f'assets/ghost/weapons_v16/{style}_{family}_2048x1760.png'
  need(src.is_file(),f'approved v1.6 source missing {src}')
  if src.is_file():oldpaths.add(str(src))
  for depth in ['back','front']:
   png=R/f'assets/ghost/weapon_layers_v19/{style}_{family}_{depth}_2048x1760.png'
   need(png.is_file(),f'missing layer {png}')
   if not png.is_file():continue
   with Image.open(png) as im:
    need(im.size==(2048,1760),f'invalid atlas dimensions: {png}')
    need(im.mode=='RGBA',f'layer requires RGBA: {png}')
    for row in range(8):
     a=[]
     for col in range(8):
      tile=im.crop((col*256,row*220,(col+1)*256,(row+1)*220))
      need(tile.getbbox() is not None,f'empty {style} {family} {depth} row {row} col {col}')
      a.append(hashlib.sha256(tile.tobytes()).hexdigest())
     need(len(set(a))>=4,f'insufficient authored frame variations {style}/{family}/{depth}/row{row}')

for name,entry in layerby.items():
 need(name in bodyby,f'missing body animation for {name}')
 if name not in bodyby:continue
 b=bodyby[name]
 # v1.11 packs the CLEAN v1.10 body PNGs into a single frame-indexed
 # atlas. Never accept the older composite atlas with a weapon painted in.
 tex=b.get('textures',[])
 if 'atlas' in b:
  atlas=b['atlas']
  need('weapon_body_v111/' in atlas,f'old precomposited weapon used for {name}')
  need((R/atlas).is_file(),f'missing weapon-ready body atlas for {name}')
  need(b.get('frame_count')==8 and 0<=b.get('row',-1)<8,'body atlas track invalid: '+name)
  frame_count=b.get('frame_count',0)
 else:
  need(len(tex)==8,f'expected eight Ghost Girl body frames for {name}')
  for frame in tex:
   need(frame.startswith('assets/ghost/'),f'external body frame {name}: {frame}')
   need((R/frame).is_file(),f'missing body frame {frame}')
  frame_count=len(tex)
 need(entry.get('frame_count')==frame_count,'body/weapon frame mismatch: '+name)
 need(entry.get('speed')==b.get('speed') and entry.get('loop')==b.get('loop'),'body/weapon timing mismatch: '+name)
 for key in ['atlas_back','atlas_front']:
  need((R/entry.get(key,'')).is_file(),f'missing {key} for {name}')
 row=entry.get('row',-1)
 need(isinstance(row,int) and 0<=row<8,f'invalid row for {name}')

scene=(R/'scenes/player.tscn').read_text()
need('scripts/weapon_animation_layers.gd' in scene,'missing layer player scene script')
need('parent="Ghost/WeaponLayers"' in scene and 'z_index = -1' in scene and 'z_index = 1' in scene,'front/back nodes and ordering missing')
script=(R/'scripts/weapon_animation_layers.gd').read_text()
for token in ['set_frame_and_progress(body.frame, body.frame_progress)','layer.hide()',
              'MANIFEST_PATH', 'AtlasTexture.new()']:
 need(token in script or (token=='layer.hide()' and 'back_layer.hide()' in script),f'layer synchronization token missing: {token}')
# The permanent project animation source should remain untouched by v1.9.
need('user://ghost_girl_treasures_v2.json' in (R/'scripts/inventory.gd').read_text(),'save filename changed')
need('BASE_ART_POS' in (R/'scripts/player.gd').read_text(),'player art transform changed')
need((R/'tools/generate_weapon_overlays.py').is_file(),'missing editable per-frame generator')
if (R/'tools/generate_weapon_overlays.py').is_file():
 generator=(R/'tools/generate_weapon_overlays.py').read_text()
 need('POSES =' in generator and "'heavy_right'" in generator,'individual pose keyframes missing')
result={'version':'1.9','status':'PASS' if not errors else 'FAIL','weapon_animations':len(layerby),
        'transparent_overlay_atlases':8,'frame_positions':32*8,'save_schema':'unchanged','errors':errors}
print(json.dumps(result,indent=2))
if errors:raise SystemExit(1)
