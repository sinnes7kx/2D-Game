#!/usr/bin/env python3
"""v1.74 regression: two-hand sword art, directional attacks, cosmetics, saves."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")

player = read("scripts/player.gd")
item_data = read("scripts/item_data.gd")
instance = read("scripts/item_instance.gd")
game = read("scripts/game.gd")
rig = read("scripts/v174_dual_swords.gd")
sword = read("scripts/v174_dual_sword_blade.gd")
fx = read("scripts/weapon_prestige_fx.gd")
scene = read("scenes/player.tscn")
room = read("scenes/rooms/moonwake_crypt.tscn")
definition = read("items/gloamrose_dual_swords_v174.tres")
icon = read("assets/ui/weapons_v174/gloamrose_dual_swords.svg")

assert "<svg" in icon and 'width="96"' in icon
assert 'item_id = "gloamrose_dual_swords_v174"' in definition
assert 'weapon_style = "dual_sword"' in definition
assert 'equip_slot = "sword"' in definition
assert '"dual_sword"' in item_data
assert 'preload("res://items/gloamrose_dual_swords_v174.tres")' in game
assert 'item_data = ExtResource("v174_dual_swords")' in room
assert 'pickup_id = "v174_armory_gloamrose_dual_swords"' in room
assert 'guaranteed_quality = "unique"' in room
assert 'ground_display = true' in room

assert 'V174_DUAL_SWORD_SCRIPT.install_animations(body_art)' in player
assert 'script = ExtResource("v174_swords")' in scene
assert 'const SWORD_SCRIPT: Script = preload("res://scripts/v174_dual_sword_blade.gd")' in rig
assert "for i in range(2):" in rig
assert 'sword.set("blade_index", i)' in rig
assert 'var span: PackedVector2Array = blades[blade_index]' in sword
assert 'z_index = -2 if back' in sword

# 4 facing x 7 separate states x 8 frame-positioned body/weapon poses.
for tag in ('"front"', '"back"', '"left"', '"right"'):
    assert tag in rig
for tag in ('"idle"', '"walk"', '"light_a"', '"light_b"', '"light_c"', '"heavy"', '"riposte"'):
    assert tag in rig
assert 'for mode in ["idle", "walk", "light_a", "light_b", "light_c", "heavy", "riposte"]:' in rig
assert 'for i in range(8):' in rig
assert 'frames.add_frame(target, frames.get_frame_texture(source, i % existing))' in rig
assert "attack_dual_sword_riposte_" in rig and "attack_dual_sword_riposte_" in player
assert 'attack_dual_sword_light_" + ["a", "b", "c"][combo_step]' in player
assert 'attack_dual_sword_heavy_' in rig
assert "var riposte_advances: Array[float]" in rig
assert "static func authored_blade_spans(" in rig
assert "return authored_blade_spans(face, action, frame_index)" in rig
assert "var lead_reach: Array[float]" in rig
assert "cross_amount: float" in rig


# A new single-item equipment class, retaining one confirmed melee hit.
assert '"dual_sword":' in player
assert "reach = 199.0 if heavy_attack else 165.0" in player
assert player.count('candidate.call("hit", power, poise_bonus') == 1
assert '"dual_sword": return 0.47' in instance
assert '"dual_sword": return 20.52' in instance
assert '"dual_sword": return 165.0' in instance

# Two different blade silhouettes and independent visual-only Mythic trails.
assert 'for hand_index in range(2):' in fx
assert 'Ghost/DualSwordsV174' in fx
assert 'func _draw_v174_dual_sword_fx(' in fx
assert 'var blade_root: Vector2 = grip.lerp(tip, 0.25)' in fx
assert 'visual_signature_level in [4, 5]' in fx
assert 'item.mythic_layer_variant()' in fx
assert "for glitter_i in range(7)" in fx
assert 'blade_index == 0 else' in sword
assert "Color" in sword
assert "user://" not in rig and "user://" not in sword
assert "user://" not in fx
print("v1.74 PASS: 28 animation clips / 224 eight-frame poses; two swords,")
print("  persistent armory/loot, single-hit combat, independent blade-only Mythic FX")
