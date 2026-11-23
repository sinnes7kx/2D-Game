#!/usr/bin/env python3
"""v1.43 static checks for source-derived long-weapon glows and Moonthread Waylights.
This checks Godot resource references and mask geometry; it does not run Godot.
"""
from pathlib import Path
from PIL import Image
import numpy as np, json, math, re

ROOT=Path(__file__).resolve().parents[1]
errors=[]
def check(cond,msg):
    if not cond:errors.append(msg)
def read(path):return (ROOT/path).read_text(encoding='utf8')

axes=json.loads(read('resources/long_weapon_glow_axes_v143.json'))
check(len(axes)==32, f'Expected 32 scythe/halberd tracks; got {len(axes)}')
frame_total=0
for style in ('scythe','halberd'):
    for family in ('locomotion','combat'):
        sources=[Image.open(ROOT/f'assets/ghost/weapon_layers_v112/{style}_{family}_{layer}_2048x1760.png').convert('RGBA') for layer in ('front','back')]
        for phase in range(2):
            action=('idle' if phase==0 else 'walk') if family=='locomotion' else ('light' if phase==0 else 'heavy')
            for fi,direction in enumerate(('front','back','left','right')):
                row=phase*4+fi
                name=f'{style}_{action}_{direction}' if family=='locomotion' else f'attack_{style}_{action}_{direction}'
                seq=axes.get(name,[])
                check(len(seq)==8,f'{name} has {len(seq)} guides instead of 8')
                for i,coords in enumerate(seq):
                    frame_total+=1
                    if len(coords)!=4 or not all(isinstance(v,(float,int)) and math.isfinite(v) for v in coords):
                        errors.append(f'Invalid guide {name}/{i}')
                        continue
                    x0,y0,x1,y1=coords
                    distance=math.hypot(x1-x0,y1-y0)
                    check(26<=distance<=155,f'Suspicious axis length {name}/{i}: {distance:.2f}')
                    a0=np.asarray(sources[0].crop((i*256,row*220,(i+1)*256,(row+1)*220)).getchannel('A'))
                    a1=np.asarray(sources[1].crop((i*256,row*220,(i+1)*256,(row+1)*220)).getchannel('A'))
                    ys,xs=np.where(np.maximum(a0,a1)>40)
                    if len(xs)<45:
                        errors.append(f'Blank weapon-only pixels {name}/{i}')
                        continue
                    for x,y in ((x0,y0),(x1,y1)):
                        check(-127<=x<=127 and -109<=y<=109,f'Guide outside frame {name}/{i}')
                        nearest=np.min((xs-(x+128))**2+(ys-(y+110))**2)
                        check(nearest<=20**2, f'Guide endpoint too far from artwork {name}/{i}')

prestige=read('scripts/weapon_prestige_fx.gd')
for token in ('long_weapon_glow_axes_v143.json','long_axes_by_animation.get(animation, [])',
              'bow_axes_by_animation.get(animation, [])','var guide: Variant = axes[clampi(body.frame',
              'effect_intensity','return empty','grip.lerp(tip, fraction)'):
    check(token in prestige,f'Missing renderer integration: {token}')
check('draw_arc(' not in prestige and 'draw_circle(center' not in prestige,'Old floating circular prestige aura returned')

wand=read('scripts/wand_idle_glimmer.gd')
check('Ghost/EquippedPrestigeFX' in wand and 'prestige.get("item")' in wand,'Double wand glimmer suppression missing')

script=read('scripts/moonthread_waylight_v143.gd')
for token in ('add_to_group("hook_switch")','add_to_group("v139_elemental_world")',
              'func on_hook_latched()', 'func on_elemental_arrow_hit(', 'if element != 3:',
              'get_nodes_in_group("v140_light_reveal")', 'reveal_from_light', 'draw_line('):
    check(token in script,f'Missing Moonthread behavior: {token}')
check('"hit"' not in script and 'queue_free()' not in script,'Waylight must be reusable and non-damaging')

scene=read('scenes/rooms/hollow_veil_moor.tscn')
check(scene.count('script = ExtResource("v143_waylight")')==2,'Need two Waylight nodes')
check('res://scripts/moonthread_waylight_v143.gd' in scene,'Scene script dependency missing')
check('V143MoonthreadWaystone' in scene, 'Waylight navigation hint missing')
check(not re.search(r'^\s*#',scene,re.M),'Invalid Godot scene # comment')
paths=re.findall(r'\[ext_resource[^]]*path="res://([^"]+)"',scene)
for path in paths:check((ROOT/path).is_file(),f'Missing scene dependency: {path}')
check(len(paths)>=50,'Unexpectedly few moor dependencies')
for target,name in [((2350,4880),'V143MoonthreadWest'),((4370,2530),'V143MoonthreadCentral')]:
    check(f'[node name="{name}"' in scene and f'position = Vector2({target[0]}, {target[1]})' in scene,
          f'{name} missing or relocated unexpectedly')

result={'version':'1.43','status':'PASS' if not errors else 'FAIL','long_weapon_tracks':len(axes),
        'long_weapon_frame_guides':frame_total,'moonthread_waylights':2,'errors':errors,
        'godot_runtime':'NOT TESTED'}
print(json.dumps(result,indent=2))
if errors:raise SystemExit(1)
