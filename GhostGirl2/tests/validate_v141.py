#!/usr/bin/env python3
"""Static regression checks for restrained weapon FX and unique controls.
Does not replace running Godot 4.7 and testing equipped items in the engine.
"""
from pathlib import Path
import re, json
R = Path(__file__).resolve().parents[1]
problems = []
def check(v, message):
    if not v:
        problems.append(message)
def read(name):
    f = R / name
    check(f.exists(), f'missing {name}')
    return f.read_text() if f.exists() else ''

prestige = read('scripts/weapon_prestige_fx.gd')
layer = read('scripts/weapon_animation_layers.gd')
wand = read('scripts/wand_idle_glimmer.gd')
hud = read('scripts/hud.gd')
help_scene = read('scenes/hud.tscn')
project = read('project.godot')

for code in ['func _axial_span() -> PackedVector2Array:',
             'tip_by_name.get(animation, [])',
             'body.to_local(hand.global_position)',
             'grip.lerp(tip, fraction)',
             'var normal: Vector2 = Vector2(-tangent.y, tangent.x)',
             'GhostWeaponFXLibrary.prestige_variant',
             'item.procedural_visuals()']:
    check(code in prestige, 'Missing axial seeded prestigious effect: ' + code)
for code in ['draw_arc(center, radius', 'draw_circle(center, radius', 'Vector2.from_angle(angle) * orbit_radius']:
    check(code not in prestige, 'Old floating ring still present: ' + code)
check('func _draw() -> void:\n    pass' in layer, 'Old circular weapon-overlay decorations still draw')
check('draw_arc(' not in wand and 'draw_circle(' not in wand, 'Wand still uses orbital/circular shapes')
check('draw_line(base, tip' in wand and 'direction.normalized()' in wand, 'Wand has no direction-aligned effect')
check('GhostWeaponFXLibrary.prestige_variant' in wand, 'Wand effect is not gated to prestige-quality items')
check('KEY_C' not in hud, 'C is still bound to inventory')
check('KEY_I' in hud and 'KEY_TAB' in hud, 'Inventory lost its I/Tab bindings')
check('C  Jump' in help_scene and 'B  Heal' in help_scene, 'Controls guide not updated')

for action, physical_code in [('jump', 67), ('use_dew', 66), ('astral_rain', 86)]:
    match = re.search(r'^'+action+r'=\{\s*.*?\n\}', project, flags=re.M | re.S)
    check(match is not None, f'Missing action {action}')
    if match:
        check(f'physical_keycode":{physical_code}' in match.group(), f'Incorrect key for {action}')
    
check('C' not in project[project.index('use_dew={'):project.index('target_lock={')].split('physical_keycode":')[1].split(',')[0], 'Unexpected healing control')
check((R/'scripts/procedural_relic_palette_v139.gd').exists(), 'Original procedural palette missing')
result = {'version':'1.41', 'status':'PASS' if not problems else 'FAIL', 'problems':problems,
          'engine_test':'not run (Godot executable not installed)'}
print(json.dumps(result, indent=2))
if problems:
    raise SystemExit(1)
