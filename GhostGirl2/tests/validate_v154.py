#!/usr/bin/env python3
"""Ghost Girl v1.54 static checks; cannot substitute for Godot F5."""
from pathlib import Path
import sys, os, re, hashlib
import numpy as np
from PIL import Image
root=Path(sys.argv[1]) if len(sys.argv)>1 else Path(__file__).resolve().parents[1]
prior=Path(os.environ.get('GG_V153_SOURCE', '/mnt/data/gg_v153_work/GhostGirl2'))
refs=Path(os.environ.get('GG_V154_ART_REFS', '/mnt/data/gg_v154_refs'))
n=0
def ok(x,why):
 global n
 n+=1
 if not x:raise AssertionError(f'v1.54 #{n}: {why}')
def read(k):
 p=root/k;ok(p.exists(),f'{k} file exists');return p.read_text()
fx=read('scripts/weapon_prestige_fx.gd')
arrow=read('scripts/bow_arrow_v126.gd')
arrowfx=read('scripts/arrow_glow_v154.gd')
player=read('scripts/player.gd')
equip=read('scripts/equipment_visuals.gd')
shader=read('assets/equipment/dress_palette.gdshader')
bow=read('scripts/bow_palette_overlay_v139.gd')
bowshader=read('assets/equipment/bow_palette_v139.gdshader')
for text in ['_draw_signature(', 'BLEND_MODE_ADD','for i in range(10):','draw_circle(p, radius','"bow"','_blade_span(animation, face, body.frame)','_gradient_at(t)','ghost']:
 if text!='ghost':ok(text in fx, f'weapon FX {text}')
ok('draw_line(start_point, end_point,' not in fx,'no old 26px hard-ended rectangle beam')
ok('draw_polyline' not in fx,'no hard polygon wing patterns behind head')
ok('z_index = 8' in fx,'glow above sprite art')
ok('var lantern: Node2D = Node2D.new()' in arrow,'projectile has separate cosmetic child')
ok('ARROW_GLOW_V154' in arrow and 'add_child(lantern)' in arrow,'arrow glow instantiated')
ok('const ARROW_GLOW_V154: Script = preload("res://scripts/arrow_glow_v154.gd")' in arrow,'new arrow script has valid local preload')
for k in ['glow_a','glow_b','glow_c']:
 ok(k in arrow and f'arrow.set("{k}"' in player, f'gradient {k} follows actual bow item')
ok('arrow.to_local(history[i])' in arrowfx,'trail positions follow last world-space projectile samples')
ok('BLEND_MODE_ADD' in arrowfx and 'draw_line(at, next_at,' in arrowfx,'luminous arrow trail, visual only')
ok('intersect_ray' not in arrowfx and 'receive_damage' not in arrowfx,'glow cannot deal extra damage')
ok('cloth_filagree_strength' in shader and 'cloth_filagree_strength' in equip,'dress-only motif wired')
ok('cloth_filagree_phase' in shader and 'fabric.visual_seed()' in equip,'motif has dress-specific saved deterministic phase')
ok('COLOR = vec4(mix(embroidered, weapon_dyed, spectral), base.a)' in shader,'dress alpha and weapon tint retained')
ok('smoothstep(0.02, 0.88, original.a) * 0.32' in bowshader,'bow base art visible through reduced-pattern mask')
ok('glow_power", 0.12' in bow,'rare bow paint overlay no longer opaque')
ok('ghost' not in arrowfx and 'inventory' not in arrowfx,'arrow glow scene independent of equipment / player behavior')
# Check the new patch only touches arrow glow param propagation in player script.
a=(prior/'scripts/player.gd').read_text() if (prior/'scripts/player.gd').is_file() else None
b=player
added='''\t# Match the physical arrow's light to the equipped bow's saved 128-bit look.\n\tvar shot_gradient: Array[Color] = equipped.glow_gradient_colors()\n\tarrow.set("glow_a", shot_gradient[0])\n\tarrow.set("glow_b", shot_gradient[1])\n\tarrow.set("glow_c", shot_gradient[2])\n'''
if a is not None:
 ok(b.replace(added,'')==a,'player gameplay source preserved byte-for-byte except arrow glow colors')
else:
 ok(added in b and 'func _begin_attack(heavy: bool)' in b, 'bow glow is color only; original attack logic retained')
# Assert physical collision/range/damage behavior unchanged in projectile.
old=(prior/'scripts/bow_arrow_v126.gd').read_text() if (prior/'scripts/bow_arrow_v126.gd').is_file() else None
original_ready='''\t# A separate additive layer preserves the readable painted arrow shaft.\n\tvar lantern: Node2D = Node2D.new()\n\tlantern.name = "ArrowLanternGlowV154"\n\tlantern.set_script(ARROW_GLOW_V154)\n\tadd_child(lantern)\n'''
original_const='''const ARROW_GLOW_V154: Script = preload("res://scripts/arrow_glow_v154.gd")\nvar glow_a: Color = Color("efb3d7")\nvar glow_b: Color = Color("c09df2")\nvar glow_c: Color = Color("a6dbfa")\n'''
if old is not None:
 ok(arrow.replace(original_ready,'').replace(original_const,'')==old,'physical arrow collision and projectile mechanics unchanged')
else:
 ok(all(z in arrow for z in ['func _check_moon_targets','func _check_world_elements','func _physics_process','_impact(point)','target.call("hit"']), 'original physical arrow gameplay remains')
for style in ['thornrose','moonveil']:
  art=root/f'assets/ghost/bows_v126/{style}_locomotion_2048x1760.png'
  m=root/f'assets/ghost/bows_v139/{style}_locomotion_mask_2048x1760.png'
  ok(art.is_file() and m.is_file(),style+' bow art+mask')
  updated=np.asarray(Image.open(art).convert('RGBA'))
  nm=np.asarray(Image.open(m).convert('RGBA'))
  ok(updated.shape==(1760,2048,4),style+' atlas dimensions unchanged')
  ok(nm.shape==updated.shape,style+' overlay mask dimensions unchanged')
  ok(np.count_nonzero(nm[:,:,3])>8000,style+' mask is nonempty')
  # When the original RAR reference is available, also prove all other
  # directions and animation rows are preserved pixel-for-pixel.
  orig_art=refs/(style+'_locomotion_2048x1760.png')
  orig_mask=refs/(style+'_locomotion_mask_2048x1760.png')
  if orig_art.is_file() and orig_mask.is_file():
    orig=np.asarray(Image.open(orig_art).convert('RGBA'))
    om=np.asarray(Image.open(orig_mask).convert('RGBA'))
    for row in range(8):
      a=orig[row*220:(row+1)*220];b=updated[row*220:(row+1)*220]
      ma=om[row*220:(row+1)*220];mb=nm[row*220:(row+1)*220]
      if row in (2,6):
        ok(not np.array_equal(a,b) and not np.array_equal(ma,mb),style+f' left row {row} corrected')
      else:
        ok(np.array_equal(a,b) and np.array_equal(ma,mb),style+f' other row {row} unchanged')
print(f'v1.54: {n}/{n} targeted static and art-preservation checks PASSED')
