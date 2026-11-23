"""v1.11 frame bounds, hook removal, data and persistence checks.
Only Godot itself can finally confirm the shader/editor/runtime rendering.
"""
from pathlib import Path
from PIL import Image
import numpy as np
import cv2,json
R=Path(__file__).resolve().parents[1]
problems=[]
def check(cond,label):
 if not cond:problems.append(label)
layer=json.loads((R/'resources/weapon_layer_manifest.json').read_text())
body=json.loads((R/'resources/ghost_extra_animations.json').read_text())
by_name={x['name']:x for x in body}
check(len(layer)==32 and len(set(x['name'] for x in layer))==32,'32 weapon tracks expected')
check(len(body)==len(by_name),'duplicate animation names')
body_atlas=R/'assets/ghost/weapon_body_v111/weapon_ready_locomotion_2048x1760.png'
check(body_atlas.exists(),'missing no-hook body atlas')
with Image.open(body_atlas) as f:
 check(f.size==(2048,1760) and f.mode=='RGBA','body geometry invalid')
 clean=np.asarray(f).copy()
leftover_total=0
for row,(m,d) in enumerate([(m,d) for m in ('idle','walk') for d in ('front','back','left','right')]):
 for c in range(8):
  frame=clean[row*220:(row+1)*220,c*256:(c+1)*256]
  orig=np.asarray(Image.open(R/f'assets/ghost/weapon_body_v110/{m}_{d}_{c:02}.png').convert('RGBA'))
  check(np.array_equal(frame[:115],orig[:115]),f'body face changed at {m}/{d}/{c}')
  check(np.all(frame[:,:,3]<=orig[:,:,3]),f'body pixels added at {m}/{d}/{c}')
  hsv=cv2.cvtColor(frame[:,:,:3],cv2.COLOR_RGB2HSV)
  yy,xx=np.indices((220,256))
  sat=(frame[:,:,3]>60)&(hsv[:,:,1]>83)&(hsv[:,:,0]>125)&(hsv[:,:,0]<178)
  sat &= (yy>138)&((xx<105) if d=='left' else (xx>148))
  leftover_total+=int(sat.sum())
  e=by_name.get(f'scythe_{m}_{d}',{})
  check(e.get('row')==row and e.get('frame_count')==8 and e.get('atlas','').endswith('weapon_ready_locomotion_2048x1760.png'),f'clean body not assigned to scythe {m}/{d}')
  e=by_name.get(f'halberd_{m}_{d}',{})
  check(e.get('row')==row and e.get('atlas','').endswith('weapon_ready_locomotion_2048x1760.png'),f'clean body not assigned to halberd {m}/{d}')
check(leftover_total==0,f'remaining hook-colored pixels: {leftover_total}')
atlases=sorted((R/'assets/ghost/weapon_layers_v111').glob('*.png'))
check(len(atlases)==8,'should have eight layered weapon atlases')
active=0
for p in atlases:
 with Image.open(p) as f:
  check(f.size==(2048,1760) and f.mode=='RGBA','overlay geometry: '+p.name)
  arr=np.asarray(f)[:,:,3]
  for row in range(8):
   for col in range(8):
    a=arr[row*220:(row+1)*220,col*256:(col+1)*256]
    check(int(a.max())>0,f'empty overlay {p.name} row{row} col{col}')
    # No weapon pixels touching any boundary: prevents physical atlas clipping.
    check(int(a[:4].max())==0 and int(a[-4:].max())==0 and int(a[:,:4].max())==0 and int(a[:,-4:].max())==0,
          f'weapon clipped {p.name} row{row} col{col}')
    active+=1
for e in layer:
 for k in ('atlas_front','atlas_back'):
  check('weapon_layers_v111/' in e.get(k,''),f'{e["name"]} not pointing to new safe overlay')
 check(e.get('frame_count')==8 and e.get('name') in by_name,f'bad overlay body mapping {e["name"]}')
for k in ('weapon_base_index','weapon_gradient_index','weapon_detail_a_index','weapon_detail_b_index'):
 for path in ('scripts/item_instance.gd','scripts/item_generator.gd','scripts/inventory.gd'):
  check(k in (R/path).read_text(),f'{path} missing {k}')
shader=(R/'assets/equipment/weapon_surface_v111.gdshader').read_text()
for token in ('base_color','gradient_color','detail_a_index','detail_b_index','detail_atlas'):
 check(token in shader,'shader lacks '+token)
check((R/'assets/equipment/weapon_detail_atlas_v111.png').exists(),'missing generated texture artwork')
check('"Ghost/WeaponLayers"' in (R/'scripts/game.gd').read_text(),'inventory not bound to weapon appearance layers')
check('user://ghost_girl_treasures_v2.json' in (R/'scripts/inventory.gd').read_text(),'save filename changed')
result={'version':'1.11','status':'PASS' if not problems else 'FAIL','body_frames_audited':64,'hook_pixels_remaining':leftover_total,'overlay_frames_audited':active,'palette_appearance_combinations_per_weapon':6*6*4*4,'problems':problems}
print(json.dumps(result,indent=2))
if problems:raise SystemExit(1)
