#!/usr/bin/env python3
"""Ghost Girl v1.72.2 source/reference regression tests (stdlib only).

These checks are separate from the Godot parser and runtime checks in CI.
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
room = (ROOT / "scenes/rooms/moonwake_crypt.tscn").read_text()
game = (ROOT / "scripts/game.gd").read_text()
player = (ROOT / "scripts/player.gd").read_text()
scene = (ROOT / "scenes/player.tscn").read_text()
effect = (ROOT / "scripts/weapon_prestige_fx.gd").read_text()
pose = (ROOT / "scripts/v172_weapon_pose.gd").read_text()
wing = (ROOT / "scripts/v172_armory_wing.gd").read_text()

expected_items = [
    "roseglass_dagger_v169",
    "nocturne_stiletto_v171",
    "moonwarden_spear_v169",
    "briarwake_trident_v171",
    "gravebell_maul_v170",
    "ashglass_warmaul_v170",
    "eclipse_twinblade_v170",
    "rosemirror_twinblade_v170",
]
assert 'id="v172_armory_wing"' in room
assert 'position = Vector2(2290, 0)' in room
assert 'position = Vector2(3548, 796)' in room
assert "room_right_edge" in wing
assert 'dimensions.x = maxf(dimensions.x' in game
assert "find_children(\"*\", \"Node2D\", true, false)" in game
assert "V172_POSE_SCRIPT.install_attack_frames(body_art)" in player
assert 'script = ExtResource("v172_pose")' in scene
assert 'get_weapon_span' in effect
assert "get_weapon_span" in pose and "_draw_briarwake_trident" in pose and "_draw_nightglass_stiletto" in pose

seen_pickups = re.findall(r'pickup_id = "(v172_armory_[^"]+)"', room)
assert len(seen_pickups) == 8 and len(set(seen_pickups)) == 8
assert room.count('ground_display = true') == 8
for item in expected_items:
    assert (ROOT / "items" / (item + ".tres")).exists(), item
    assert f'v172_armory_{item}' in seen_pickups

for direction in ("front", "back", "left", "right"):
    assert direction in pose
assert 'for weapon_art in ["nocturne_dagger", "briarwake_spear"]:' in pose
assert 'for attack in ["light", "heavy"]:' in pose
assert "for face in [\"front\", \"back\", \"left\", \"right\"]:" in pose
assert 'var axis: Vector2 = tip - grip' in effect

print("v1.72.2 source checks passed: saved pickups, camera, 8 items, weapon pose and glow")
