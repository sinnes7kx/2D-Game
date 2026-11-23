#!/usr/bin/env python3
"""Static integration/visual guide checks for Ghost Girl v1.42.
Godot F5 is still needed; don't confuse this test with runtime verification.
"""
from pathlib import Path
from PIL import Image
import json,re,math
import numpy as np

ROOT=Path(__file__).resolve().parents[1]
errors=[]
def check(cond,msg):
    if not cond: errors.append(msg)

def load(path):return (ROOT/path).read_text(encoding='utf8')

axes=json.loads(load('resources/weapon_glow_axes_v142.json'))
check(len(axes)==32, f'Expected 32 named bow tracks, got {len(axes)}')
for style in ('thornrose','moonveil'):
    for family in ('combat','locomotion'):
        path=ROOT/f'assets/ghost/bows_v139/{style}_{family}_mask_2048x1760.png'
        with Image.open(path) as image:
            im=image.convert('RGBA')
            for phase in range(2):
                action=('light' if phase==0 else 'heavy') if family=='combat' else ('idle' if phase==0 else 'walk')
                for d,face in enumerate(('front','back','left','right')):
                    name=(f'attack_{style}_{action}_{face}' if family=='combat' else f'{style}_{action}_{face}')
                    poses=axes.get(name,[])
                    check(len(poses)==8,f'{name} wrong guide count')
                    for frame,pose in enumerate(poses):
                        if len(pose)!=4:continue
                        check(all(isinstance(x,(int,float)) and math.isfinite(x) for x in pose), f'{name}[{frame}] nonnumeric')
                        x0,y0,x1,y1=pose
                        length=math.hypot(x1-x0,y1-y0)
                        check(12.0<=length<=160.0,f'{name}[{frame}] implausible length {length:.1f}')
                        for px,py in ((x0,y0),(x1,y1)):
                            check(-126<=px<=126 and -108<=py<=108,f'{name}[{frame}] point beyond sprite cell')
                        row=phase*4+d
                        tile=np.asarray(im.crop((frame*256,row*220,(frame+1)*256,(row+1)*220)).getchannel('A'))
                        ys,xs=np.where(tile>32)
                        for px,py in ((x0,y0),(x1,y1)):
                            if len(xs):
                                closest=np.min((xs-(px+128))**2+(ys-(py+110))**2)
                                check(closest<19*19,f'{name}[{frame}] guide far from bow-only pixels')

prestige=load('scripts/weapon_prestige_fx.gd')
for needle in ('weapon_glow_axes_v142.json','bow_axes_by_animation.get(animation, [])','body.frame','grip = Vector2(float(pose[0])','end_point = Vector2(float(pose[2])'):
    check(needle in prestige, f'Bow guide not used in renderer: {needle}')
player=load('scripts/player.gd')
check('draw_arc(Vector2(0, -17), radius' not in player,'old circular bow charge meter remains')
check('if bow_draw_active:\n\t\t# v1.42:' in player,'jump-while-drawing handling missing')
check('Input.is_action_just_pressed("jump") and stamina >=' in player,'cannot jump during held draw')
check('body_art.set_frame_and_progress(keep_frame, 0.0)' in player,'held frame not preserved during jump')
check('if not Input.is_action_pressed("attack_heavy"):' in player,'bow release not tied to button state')
check('arrow.set("launched_in_air", jump_time_left > 0.0)' in player,'aerial arrow state missing')

scene=load('scenes/rooms/moonwake_crypt.tscn')
check('res://scripts/bow_practice_v142.gd' in scene,'practice script missing scene reference')
check(scene.count('script = ExtResource("v142_practice")')==2,'expected exactly two bow practice targets')
check('require_full_draw = true' in scene and 'require_airborne = true' in scene,'airborne charged practice target not configured')
check(not re.search(r'^\s*#',scene,re.M),'invalid scene # comments')
for ref in re.findall(r'\[ext_resource [^\]]+path="res://([^\"]+)"',scene):
    check((ROOT/ref).is_file(),f'missing moonwake scene resource {ref}')

script=load('scripts/bow_practice_v142.gd')
for needle in ('add_to_group("v139_elemental_world")','func on_elemental_arrow_hit(','require_full_draw','require_airborne','func _draw()'):
    check(needle in script,f'practice component missing {needle}')
check('queue_free()' not in script and 'save_game' not in script, 'practice target has unwanted persistence/consumption')

print(json.dumps({'version':'1.42','status':'PASS' if not errors else 'FAIL','bow_animation_tracks':len(axes),'frame_axes':sum(map(len,axes.values())),'practice_targets':2,'errors':errors,'godot_f5_test':'not run'},indent=2))
if errors:raise SystemExit(1)
