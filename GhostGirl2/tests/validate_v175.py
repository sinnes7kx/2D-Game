#!/usr/bin/env python3
"""v1.75 source regressions: hook-free approved body, mirrored bow, normal/mythic FX."""
from pathlib import Path
import json
ROOT = Path(__file__).resolve().parents[1]
def read(path):
    return (ROOT / path).read_text(encoding="utf-8")
body = read("scripts/v175_hookfree_weapon_body.gd")
player = read("scripts/player.gd")
bow = read("scripts/bow_palette_overlay_v139.gd")
fx = read("scripts/weapon_prestige_fx.gd")
manifest = json.loads(read("resources/ghost_extra_animations.json"))
animations = {x["name"] for x in manifest}
for facing in ["front", "back", "left", "right"]:
    assert "attack_unarmed_light_" + facing in animations
    for weapon in ["nocturne_dagger", "briarwake_spear"]:
        for attack in ["light", "heavy"]:
            assert "attack_" + weapon + "_" + attack + "_" + facing in animations
    for kind in ["idle", "walk"]:
        assert f"thornrose_{kind}_{facing}" in animations
        assert f"moonveil_{kind}_{facing}" in animations
assert 'const V175_CLEAN_WEAPON_BODY = preload("res://scripts/v175_hookfree_weapon_body.gd")' in player
assert "V175_CLEAN_WEAPON_BODY.install(body_art)" in player
assert player.index("V175_CLEAN_WEAPON_BODY.install(body_art)") > player.index("V174_DUAL_SWORD_SCRIPT.install_animations(body_art)")
assert '"attack_unarmed_light_" + face' in body
assert 'var dual: bool =' in body
assert 'var newer_attack: bool =' in body
assert 'var left_bow: bool =' in body
assert 'frames.remove_animation(anim)' in body
assert 'frames.add_frame(anim, tile)' in body
assert 'bow_carry_visual.flip_h = true' in bow
assert 'mirrored_bow: String = _bow_style_name(item) + "_" + bow_motion + "_right"' in bow
assert 'bow_carry_visual.visible = true' in bow
assert '_should_flip_for_animation(source_animation)' in bow
assert 'func _v175_visible_edge(' in fx
assert 'func _v175_mythic_signature(' in fx
assert '_v175_visible_edge(blade_root, tip, intensity, float(hand_index) * 0.32)' in fx
assert '_v175_visible_edge(a, tip, intensity, float(hand_index) * 0.31)' in fx
assert 'draw_line(root_edge, mid_edge, Color(edge.r, edge.g, edge.b, 0.58' in fx
assert 'draw_line(mid_edge, b, Color(edge.r, edge.g, edge.b, 0.58' in fx
assert 'if item.get_slot() != "wand":' in fx
assert '_v175_mythic_signature(blade_a, blade_b, style, segment_i, attacking)' in fx
for group in ["twinblade", "dual_dagger", "dual_sword", "bow"]:
    assert 'style == "' + group + '"' in fx
assert 'item.mythic_layer_variant()' in fx
assert 'item.visual_seed()' in fx
print("v1.75 source PASS: approved hook-free poses, left mirrored bow,")
print("  3 normal blade-glow families and distinct seeded Mythic signatures")
