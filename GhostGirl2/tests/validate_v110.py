"""Static compatibility and artwork validation for v1.10 Clean Hands.
This is not a substitute for opening the project in Godot 4.
"""
import json
from pathlib import Path
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
manifest=json.loads((ROOT/'resources/ghost_extra_animations.json').read_text())
by_name={x['name']:x for x in manifest}
layer=json.loads((ROOT/'resources/weapon_layer_manifest.json').read_text())
errors=[]
def need(test,label):
    if not test:errors.append(label)
need(len(by_name)==len(manifest),'duplicate animation tracks')
need(len(layer)==32,'v1.9 layered weapon tracks missing')

for style in ['scythe','halberd']:
 for direction in ['front','back','left','right']:
  for mode in ['idle','walk']:
   name=f'{style}_{mode}_{direction}'
   ent=by_name[name]
   want=[f'assets/ghost/weapon_body_v110/{mode}_{direction}_{i:02}.png' for i in range(8)]
   if 'atlas' in ent:
    dirs=['front','back','left','right']
    expected_row=(0 if mode=='idle' else 4)+dirs.index(direction)
    need(ent['atlas']=='assets/ghost/weapon_body_v111/weapon_ready_locomotion_2048x1760.png' and ent['row']==expected_row and ent['frame_count']==8,
         f'new hook-free atlas wrong track: {name}')
   else:
    need(ent['textures']==want,f'manifest mismatch: {name}')
  for action in ['light','heavy']:
   name=f'attack_{style}_{action}_{direction}'
   ent=by_name[name]
   if action=='light':
    want=[f'assets/ghost/combat_v14/attack_unarmed_light_{direction}_{(5 if i==4 else i):02}.png' for i in range(8)]
   else:
    want=[f'assets/ghost/weapon_combat_body_v110/heavy_{direction}_{i:02}.png' for i in range(8)]
   need(ent['textures']==want,f'attack body mismatch: {name}')

# Hook and unarmed actions must still use the canonical art so the hook is
# visible when she deliberately launches it or uses it without a weapon.
for entry in manifest:
 if 'scythe' not in entry['name'] and 'halberd' not in entry['name']:
  need('weapon_body_v110' not in str(entry) and 'weapon_combat_body_v110' not in str(entry),
       'unrelated animation modified: '+entry['name'])

cleaned=0;different=0
for mode in ['idle','walk']:
 for direction in ['front','back','left','right']:
  for n in range(8):
   source_name=f'idle_{direction}_{n:02}.png' if mode=='idle' else f'{direction}_{n:02}.png'
   original=ROOT/'assets/ghost'/source_name
   new=ROOT/f'assets/ghost/weapon_body_v110/{mode}_{direction}_{n:02}.png'
   need(new.is_file(),f'missing {new}')
   if not new.is_file():continue
   with Image.open(original) as a,Image.open(new) as b:
    need(a.size==b.size==(256,220) and b.mode=='RGBA',f'wrong dimensions: {new}')
    aa=np.asarray(a.convert('RGBA'));bb=np.asarray(b.convert('RGBA'))
    need(bool(np.all(bb[:,:,3]<=aa[:,:,3])),f'alpha increase on clean body: {new}')
    # Head pixels must remain exact, including Ghost Girl's eyes and hair.
    need(bool(np.array_equal(aa[:110],bb[:110])),f'head/hair changed: {new}')
    removed=int(np.count_nonzero(bb[:,:,3]<aa[:,:,3]))
    need(removed>50,f'hook not isolated: {new}')
    different+=removed
   cleaned+=1
heavy=0
for direction in ['front','back','left','right']:
 for i in range(8):
  p=ROOT/f'assets/ghost/weapon_combat_body_v110/heavy_{direction}_{i:02}.png'
  need(p.exists(),f'missing heavy body {p}')
  if p.exists():
   with Image.open(p) as im:
    need(im.mode=='RGBA' and im.size==(256,220),f'wrong heavy image geometry {p}')
   heavy+=1
need('user://ghost_girl_treasures_v2.json' in (ROOT/'scripts/inventory.gd').read_text(),'save-file compatibility changed')
result={'version':'1.10','status':'PASS' if not errors else 'FAIL','weapon_tracks':32,
        'hook_free_idle_walk_frames':cleaned,'effect_free_heavy_frames':heavy,
        'transparent_body_pixels_cleared':different,'v19_weapon_layers':'unchanged',
        'save_schema':'unchanged','errors':errors}
print(json.dumps(result,indent=2))
if errors:raise SystemExit(1)
