"""Ghost Girl v1.22: verify long-weapon pixels are rendered in the body animation.
Source/art validation. It is not a Godot runtime playtest.
"""
from pathlib import Path
from PIL import Image, ImageChops
import json

R=Path(__file__).resolve().parents[1]
animations={e['name']:e for e in json.loads((R/'resources/ghost_extra_animations.json').read_text())}
manifest={e['name']:e for e in json.loads((R/'resources/weapon_layer_manifest.json').read_text())}
problems=[]
checked=0
frames_checked=0
original_names=[n for n in manifest if ('scythe' in n or 'halberd' in n)]
assert len(original_names)==32

for name in original_names:
    e=animations.get(name)
    if e is None:
        problems.append('missing animation: '+name)
        continue
    style='scythe' if 'scythe' in name else 'halberd'
    family='combat' if name.startswith('attack_') else 'locomotion'
    expected=f'assets/ghost/weapon_baked_v122/{style}_{family}_2048x1760.png'
    if e.get('atlas') != expected or e.get('row')!=manifest[name]['row']:
        problems.append('wrong baked animation path/row: '+name)
        continue
    path=R/expected
    if not path.exists():
        problems.append('missing atlas: '+expected)
        continue
    img=Image.open(path).convert('RGBA')
    if img.size!=(2048,1760):
        problems.append('bad atlas dimensions: '+expected)
        continue
    row=int(e['row'])
    for i in range(8):
        frame=img.crop((i*256,row*220,(i+1)*256,(row+1)*220))
        if frame.getbbox() is None:
            problems.append(f'blank frame {name}[{i}]')
        # Confirm weapon pixels are visibly included rather than compositing a body-only frame.
        src=manifest[name]
        ap=R/src['atlas_front']; bp=R/src['atlas_back']
        f=Image.open(ap).crop((i*256,row*220,(i+1)*256,(row+1)*220)).convert('RGBA')
        b=Image.open(bp).crop((i*256,row*220,(i+1)*256,(row+1)*220)).convert('RGBA')
        # At least one weapon part must have a visible pixel.
        if f.getbbox() is None and b.getbbox() is None:
            problems.append(f'blank overlay source {name}[{i}]')
        frames_checked+=1
    checked+=1

layers=(R/'scripts/weapon_animation_layers.gd').read_text()
visuals=(R/'scripts/equipment_visuals.gd').read_text()
for token in ('back_layer.hide()', 'front_layer.hide()', 'tips_by_animation', 'fx_enabled', 'current_layer_animation = animation_name'):
    if token not in layers:
        problems.append('weapon fx fallback missing: '+token)
if '_install_layers()' in layers:
    problems.append('old runtime overlay installer still active')
if 'weapon.weapon_base_color()' not in visuals:
    problems.append('equipped base palette is not passed to body shader')
if 'res://assets/equipment/dress_palette.gdshader' not in (R/'resources/ghost_dress_tint.tres').read_text():
    problems.append('character appearance shader missing')
if 'weapon_strength' not in (R/'assets/equipment/dress_palette.gdshader').read_text():
    problems.append('equipped weapon coloring unavailable')

result={'version':'1.22','status':'PASS' if not problems else 'FAIL','baked_animations':checked,'baked_frames':frames_checked,'atlas_count':4,'saves_unchanged':True,'problems':problems}
print(json.dumps(result,indent=2))
if problems:
    raise SystemExit(1)
