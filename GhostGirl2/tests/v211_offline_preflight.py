#!/usr/bin/env python3
"""v2.11 source-only regression guard. No Godot, Actions, save access or deps.

Usage from repository root:
  python3 GhostGirl2/tests/v211_offline_preflight.py

This verifies wiring and non-destructive invariants; it does not render or
compile the Godot project. F5 and Godot headless tests remain required.
"""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]


def require(path: str, tokens: tuple[str, ...], banned: tuple[str, ...] = ()) -> list[str]:
    target = ROOT / path
    if not target.is_file():
        return [f"{path}: missing"]
    source = target.read_text(encoding="utf-8")
    return ([f"{path}: missing required code {t!r}" for t in tokens if t not in source] +
            [f"{path}: deprecated code still present {t!r}" for t in banned if t in source])


def main() -> int:
    failures = []
    failures += require("scripts/scythe_glow_layer_v211.gd", (
        "const STOPS: Array[float] = [0.0, 0.10, 0.20, 0.30, 0.40, 0.50]",
        'ghost-girl-v211-scythe-aura:',
        "if int(digest[0]) % 100 < 70:",
        "if int(digest[0]) < 179:",
        "CanvasItemMaterial.BLEND_MODE_ADD",
        "SCYTHE.contours(head, axis, profile, side)",
        "draw_line(foot, head, ink",
        "draw_polyline(outer, ink",
        "draw_polyline(inner, ink",
    ))
    failures += require("scripts/collector_lens_model_v179.gd", (
        'const SCYTHE_GLOW = preload("res://scripts/scythe_glow_layer_v211.gd")',
        '"ScytheGlowLayerV211"',
        "str(item.definition.item_id))",
        'scythe_glow.call("set_pose"',
    ))
    failures += require("scripts/scythe_rig_v190.gd", (
        '"WorldScytheGlowV211"', "scythe_glow.call(\"set_pose\"",
        "SCYTHE.draw_scythe(self, points[0], points[1], profile, look, colors, phase, side, false)",
    ))
    failures += require("scripts/collector_lens_v179.gd", (
        '"ScytheGlowPreviewV211"',
        "index - 1", "Preview glow", "not saved",
    ))
    failures += require("scripts/heavy_weapon_art_v192.gd", (
        "FX.draw_edge(canvas, closed, colors, look, phase, 0.60)",
        "BLUNT_V203.draw_blunt(",
    ), ("FX.draw_edge(canvas,rim,colors,look,phase,0.60)",))
    failures += require("scripts/blunt_weapon_family_v203.gd", (
        "static func _rim(", "var spikes: PackedVector2Array",
        "var flanges: PackedVector2Array", "var star: PackedVector2Array",
    ))
    failures += require("scripts/game.gd", (
        "const BLUNT_LOOT_TABLE", "posmod(seed_value, 41)",
        'if OS.is_debug_build():',
        '"res://items/v203_nightchain_flail.tres"',
    ))
    failures += require("tests/v211_blunt_scythe_aura_smoke.gd", (
        "GLOW.rolled_level(", "GLOW.opacity(", "GhostItemGenerator.create(",
        "inv._serialize_item(", "v2.11 PASS",
    ))
    if failures:
        for failure in failures:
            print("FAIL:", failure, file=sys.stderr)
        return 1
    print("PASS: v2.11 source wiring and invariant checks (not a Godot test)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
