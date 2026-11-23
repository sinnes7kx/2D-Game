"""Ghost Girl v1.19: expanded Hollow Veil Moor biome texture + 5x area room pass.
Static validation only; live playtest in Godot recommended.
"""
from pathlib import Path
from PIL import Image
import json, re
R = Path(__file__).resolve().parents[1]
problems = []

def ok(cond, msg):
    if not cond:
        problems.append(msg)

scene_path = R / 'scenes/rooms/hollow_veil_moor.tscn'
bg_path = R / 'assets/world/hollow_veil_moor_v118.jpg'
old_bg_path = R / 'assets/world/hollow_veil_moor_v116.jpg'
ok(scene_path.is_file(), 'missing moor scene')
ok(bg_path.is_file(), 'missing new moor background')
text = scene_path.read_text(encoding='utf-8') if scene_path.exists() else ''
ok('res://assets/world/hollow_veil_moor_v118.jpg' in text, 'scene still points at old moor background')
if bg_path.exists() and old_bg_path.exists():
    new_size = Image.open(bg_path).size
    old_size = Image.open(old_bg_path).size
    ok(new_size == (10368, 6912), f'unexpected new moor size {new_size}')
    old_area = old_size[0] * old_size[1]
    new_area = new_size[0] * new_size[1]
    ok(new_area >= old_area * 5.0, 'moor area is not at least 5x larger')
else:
    new_size = old_size = (0, 0)

for token in (
    'size = Vector2(10368, 76)',
    'size = Vector2(76, 6912)',
    'position = Vector2(5184, 85.5)',
    'position = Vector2(5184, 6826.5)',
    'position = Vector2(85.5, 3456)',
    'position = Vector2(10282.5, 3456)',
):
    ok(token in text, f'room boundary token missing: {token}')

# Ensure objects were redistributed across the larger room.
pos = [tuple(map(float, m.groups())) for m in re.finditer(r'^position = Vector2\(([-\d.]+), ([-\d.]+)\)$', text, re.M)]
if pos:
    xs = [p[0] for p in pos]
    ys = [p[1] for p in pos]
    ok(max(xs) > 9000 and max(ys) > 6000, 'room content was not spread across the expanded playfield')

result = {
    'version': '1.19',
    'status': 'PASS' if not problems else 'FAIL',
    'old_bg_size': old_size,
    'new_bg_size': new_size,
    'problems': problems,
}
print(json.dumps(result, indent=2))
if problems:
    raise SystemExit(1)
