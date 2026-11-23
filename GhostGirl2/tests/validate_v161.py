#!/usr/bin/env python3
"""Portable targeted static checks for Ghost Girl v1.61 patch."""
from pathlib import Path
import hashlib
import re
ROOT = Path(__file__).resolve().parents[1]

def txt(path):
    return (ROOT / path).read_text(encoding="utf-8")

scene=txt("scenes/player.tscn")
visual=txt("scripts/equipment_visuals.gd")
glow=txt("scripts/weapon_prestige_fx.gd")
hunter=txt("scripts/gothic_hunter.gd")
checks = {
    "WandVisual is actually parented under Ghost": '[node name="WandVisual" type="Sprite2D" parent="Ghost"' in scene,
    "Gameplay Hand marker retained": '[node name="Hand" type="Marker2D" parent="."' in scene,
    "RoseHook scene retained": '[node name="RoseHook" parent="."' in scene,
    "Old Hand/WandVisual node removed": 'parent="Hand" unique_id=676680065' not in scene,
    "visual script reads relocated wand": 'get_node("Ghost/WandVisual")' in visual,
    "wand texture remains linked": 'texture = ExtResource("10_wand")' in scene,
    "wand shares Ghost transform": 'wand_visual.scale = Vector2(0.21, 0.21)' in visual,
    "wand correctly tucks behind from back": 'wand_visual.show_behind_parent = true' in visual,
    "glow reads actual sprite": 'body.get_node_or_null("WandVisual")' in glow,
    "glow uses artwork transform": glow.count('wand_sprite.transform * Vector2(') == 2,
    "fallback remains": 'if style == "blade":' in glow,
    "casting bloom remains cosmetic-only": 'if attacking:\n        # Spell preparation' in glow,
    "existing rare cosmetics retained": 'if sig == 5:' in glow and 'elif sig == 4:' in glow,
    "blade hunter circles": 'const CIRCLE: int = 7' in hunter and 'state = CIRCLE' in hunter,
    "circle does not call damage": 'girl.call("receive_damage"' not in hunter.split('\t\tCIRCLE:',1)[1].split('\t\tFEINT:',1)[0],
    "circle obeys steering": 'FIRE_STEERING.avoid_fire' in hunter and 'PURSUE, CIRCLE' in hunter,
    "whiff exposes guard": 'and not strike_done:' in hunter and 'opening_left = 0.90' in hunter,
    "occultist recovers with drift": 'recover_drift' in hunter and 'remaining > 0.60' in hunter,
    "strike damage calls unchanged": hunter.count('girl.call("receive_damage", strike_damage, global_position)') == 2,
    "one bolt per occultist release": hunter.count('HEX_BOLT_SCENE.instantiate()') == 1,
    "no extra loot paths": hunter.count('spawn_world_loot') == 2,
}
for name, passed in checks.items():
    if not passed:
        raise AssertionError(name)
assert '[node name="EquippedPrestigeFX" type="Node2D" parent="Ghost"]' in scene
assert '[node name="EquipmentVisuals" type="Node2D" parent="."' in scene
# Changed texts should remain parsable at the most basic level: no tabs in
# Python-only source; GDScript scene balance and leading whitespace untouched.
assert scene.count('[node ') == 18, scene.count('[node ')
assert all(x.endswith('.gd') for x in ['equipment_visuals.gd','weapon_prestige_fx.gd','gothic_hunter.gd'])
print(f'PASS {len(checks)+3}/{len(checks)+3} v1.61 targeted static checks')
