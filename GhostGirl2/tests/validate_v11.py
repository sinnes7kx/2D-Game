#!/usr/bin/env python3
"""Static regression checks for v1.1 directional actions + backpack restoration."""
import re
import struct
from pathlib import Path

root = Path(__file__).resolve().parents[1]
frames = (root / "resources/ghost_girl_frames.tres").read_text()
player = (root / "scripts/player.gd").read_text()
scene = (root / "scenes/inventory_panel.tscn").read_text()
panel = (root / "scripts/inventory_panel.gd").read_text()
preview = (root / "scenes/development/combat_animation_preview.tscn").read_text()

source_declared = set(re.findall(r'^\[ext_resource[^\n]+ id="([^"\n]+)"\]', frames, re.MULTILINE))
assert len(source_declared) >= 64, "Original directional source frames missing"
new_tracks = {}
for action in ("attack_light", "attack_heavy", "dodge", "hurt"):
    for direction in ("front", "back", "left", "right"):
        name = action + "_" + direction
        match = re.search(r'\"frames\": \[([^]]+)\],\s*\"loop\": 0,\s*\"name\": &\"' + name + r'\"', frames)
        assert match, name + " absent or looped"
        refs = re.findall(r'ExtResource\(\"([^\"]+)\"\)', match.group(1))
        assert len(refs) >= 4, name + " frame count"
        assert all(ref in source_declared for ref in refs), name + " unknown frame"
        assert "animation = &\"" + name + "\"" in preview, name + " preview missing"
        new_tracks[name] = len(refs)

assert '_play_action_frames("dodge_" + facing_name, DODGE_DURATION)' in player
assert '_play_action_frames("hurt_" + facing_name, hurt_recoil_left)' in player
assert ('_play_action_frames(attack_animation + facing_name, attack_duration)' in player
        or '_play_action_frames(attack_animation, attack_duration)' in player)
assert '_play_if_changed("walk_" + facing_name)' not in player
assert 'body_art.play("throw_" + facing_name)' in player  # for real object throwing
assert '"throw_" + facing_name, attack_duration' not in player
assert '[node name="SortBackpack" type="Button"' in scene
assert '\t$Layout/Header/SortBackpack.pressed.connect(_sort_backpack)' in panel
assert 'func sort_backpack()' in (root / "scripts/inventory.gd").read_text()
assert 'user://ghost_girl_treasures_v2.json' in (root / "scripts/inventory.gd").read_text()

# All reused pixels originate in the existing 256 x 220 native PNGs.
for direction in ("front", "back", "left", "right"):
    for prefix in (("idle_" + direction), direction):
        sample = root / "assets/ghost" / (prefix + "_00.png")
        with sample.open("rb") as f:
            data = f.read(24)
        assert data[:8] == b"\x89PNG\r\n\x1a\n", sample
        assert struct.unpack(">II", data[16:24]) == (256, 220), sample

print("Validated", len(new_tracks), "action tracks, inventory SORT, original frame sizes and save path")
