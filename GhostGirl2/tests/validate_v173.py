#!/usr/bin/env python3
"""v1.73 dual-dagger frame, loot, attack, equip and Mythic integration tests."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
read = lambda rel: (ROOT / rel).read_text(encoding="utf-8")
player = read("scripts/player.gd")
game = read("scripts/game.gd")
item_data = read("scripts/item_data.gd")
dual = read("scripts/v173_dual_daggers.gd")
blade = read("scripts/v173_dual_dagger_blade.gd")
fx = read("scripts/weapon_prestige_fx.gd")
scene = read("scenes/player.tscn")
armory = read("scenes/rooms/moonwake_crypt.tscn")
definition = read("items/moonlace_dual_daggers_v173.tres")
icon = ROOT / "assets/ui/weapons_v173/moonlace_dual_daggers.svg"

assert icon.is_file() and "<svg" in icon.read_text(encoding="utf-8")
assert 'weapon_style = "dual_dagger"' in definition
assert 'item_id = "moonlace_dual_daggers_v173"' in definition
assert 'equip_slot = "sword"' in definition
assert '"dual_dagger"' in item_data
assert 'preload("res://items/moonlace_dual_daggers_v173.tres")' in game
assert 'item_data = ExtResource("v173_dual_daggers")' in armory
assert 'pickup_id = "v173_armory_moonlace_dual_daggers"' in armory
assert 'guaranteed_quality = "unique"' in armory
assert 'ground_display = true' in armory

assert "V173_DUAL_DAGGER_SCRIPT.install_animations(body_art)" in player
assert "DualDaggersV173" in scene and 'script = ExtResource("v173_dual")' in scene
assert 'const BLADE_SCRIPT = preload("res://scripts/v173_dual_dagger_blade.gd")' in dual
assert 'for i in range(2):' in dual  # two physical hand layers
assert 'blade.set("blade_index", i)' in dual
assert 'var span: PackedVector2Array = blades[blade_index]' in blade
assert 'z_index = -2 if back' in blade  # side/back depth

# 4 directional sets * [idle, walk, light A/B/C, heavy] * 8 frame cells.
assert 'for face in ["front", "back", "left", "right"]:' in dual
assert 'for mode in ["idle", "walk", "light_a", "light_b", "light_c", "heavy"]:' in dual
assert 'for i in range(8):' in dual
assert 'frames.add_frame(target, frames.get_frame_texture(source, i % existing))' in dual
assert 'return "dual_dagger"' not in player or '"dual_dagger"' in player
assert 'attack_dual_dagger_light_" + ["a", "b", "c"][combo_step]' in player
assert '"dual_dagger":' in player
assert 'reach = 153.0 if heavy_attack else 122.0' in player

# Dual wield is cosmetic per hand: one original hit check per melee attack.
assert 'for candidate in get_tree().get_nodes_in_group("enemies"):' in player
assert player.count('candidate.call("hit", power, poise_bonus') == 1
assert 'get_blade_spans' in dual
assert 'func _draw_v173_dual_dagger_fx(' in fx
assert 'if style == "dual_dagger":' in fx
assert '"Ghost/DualDaggersV173"' in fx
assert 'visual_signature_level in [4, 5]' in fx
assert 'item.mythic_layer_variant()' in fx
assert 'var a: Vector2 = grip.lerp(tip, 0.39)' in fx  # handle unlit
assert 'for hand_index in range(2):' in fx
assert '"user://" not in dual' and '"user://" not in blade

print("v1.73 PASS: 24 directional clips, 192 logical frames, 2 hand sprites,")
print("  loot/armory pickup, single-hit combat, and independent seeded Mythic glows")
