from pathlib import Path
import json
from PIL import Image
root=Path(__file__).resolve().parents[1]
guides=json.loads((root/'resources/wand_pose_guides_v163.json').read_text())
assert guides['rows']==12 and guides['columns']==9
assert len(guides['animations'])==12
assert sum(v['count'] for v in guides['animations'].values())==92
for variant in ['crystal_rose','moonlit_censer','thorn_crescent']:
 p=root/f'assets/equipment/wands_v163/{variant}_poses_v163.png'
 im=Image.open(p)
 assert im.size==(9*176,12*176)
 for a,data in guides['animations'].items():
  assert len(data['guides'])==data['count']
  for i,g in enumerate(data['guides']):
   assert len(g)==4
   tile=im.crop((i*176,data['row']*176,(i+1)*176,(data['row']+1)*176))
   assert tile.getchannel('A').getbbox() is not None,(variant,a,i)
visual=(root/'scripts/equipment_visuals.gd').read_text()
fx=(root/'scripts/weapon_prestige_fx.gd').read_text()
for s in ['region_enabled = true','_apply_wand_pose()','WAND_POSE_ATLASES','show_behind_parent = facing == "back"']:
 assert s in visual,s
for s in ['wand_pose_by_animation','WAND_POSE_GUIDES_PATH','clampi(body.frame']:
 assert s in fx,s
assert 'item_seed' not in '\n'.join([l for l in visual.splitlines() if 'wand' in l.lower()])
print('v1.63 targeted validation PASS: 12 animations, 92 frames per wand, 3 pose atlases, synchronized glow')
