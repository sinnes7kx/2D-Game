#!/usr/bin/env python3
"""v1.72.3 no-save-change Mythic visibility and twinblade safety checks.

Godot's own import/check-only/scene boot separately verify GDScript parsing.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
fx = (ROOT / "scripts/weapon_prestige_fx.gd").read_text(encoding="utf-8")
item = (ROOT / "scripts/item_instance.gd").read_text(encoding="utf-8")
player = (ROOT / "scripts/player.gd").read_text(encoding="utf-8")
styles = ["blade", "dagger", "spear", "maul", "twinblade", "scythe", "halberd", "bow"]

assert "func _draw_v1723_mythic_sheen(" in fx
assert "func _draw_v1723_twinblade_edges(" in fx
assert "func _v1723_blade_segments(" in fx
assert "visual_signature_level not in [4, 5]" in fx
assert "mythic_layer_variant()" in fx
assert "item.visual_seed()" in fx
assert "elapsed * 0.105" in fx  # deliberately slow color cycling
assert "for sparkle_i in range(6)" in fx
assert "for segment_i in range(segments.size())" in fx
assert "Color" in fx

# Twinblade is handled *before* the legacy shaft-wide generic bloom, and
# before any old ring/ambient signature that used to illuminate its grip.
start = fx.index('if style == "twinblade":\n\t\t_draw_v1723_twinblade_edges(')
end = fx.index('return', start)
twinblade_early_branch = fx[start:end]
assert "_draw_signature" not in twinblade_early_branch
assert "_draw_ambient_fireflies" not in twinblade_early_branch
assert "_draw_v1723_mythic_sheen" in twinblade_early_branch
assert fx.index('if style == "twinblade":\n\t\t_draw_v1723_twinblade_edges(') < fx.index('for i in range(15):')

# Two cutting regions; no central-handle glow.
segment_body = fx.split('func _v1723_blade_segments(', 1)[1].split('func _draw_v1723_twinblade_edges(', 1)[0]
assert "grip.lerp(tip, 0.58)" in segment_body
assert "grip.lerp(back_tip, 0.56)" in segment_body
assert 'elif style == "maul":' in segment_body
assert 'elif style == "spear" or style == "halberd":' in segment_body
assert 'elif style == "scythe":' in segment_body
assert 'elif style == "dagger":' in segment_body
assert "return result" in segment_body
assert "item.get_slot() == \"wand\"" in fx
assert 'elif style == "bow":' in fx
assert all(style in fx or style in item or style in player for style in styles)
assert "func _draw_v172_named_weapon_fx" in fx  # existing named effects preserved
assert "func _draw_bow_dual_glow" in fx
assert "func _draw_mythic_signature" in fx
print("v1.72.3 source tests passed: seeded Mythic, visible glints, dual blade-only segments, preserved FX")
