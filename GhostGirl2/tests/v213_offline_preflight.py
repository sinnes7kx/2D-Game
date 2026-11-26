#!/usr/bin/env python3
"""v2.13 local source guard. Zero GitHub Actions minutes or save access.

Run: python3 GhostGirl2/tests/v213_offline_preflight.py
Structural only: actual Godot headless/F5 and listening tests still required.
"""
from pathlib import Path
import sys

GAME = Path(__file__).resolve().parents[1]


def check(path: str, required: tuple[str, ...]) -> list[str]:
    file = GAME / path
    if not file.is_file():
        return [f"Missing: {path}"]
    code = file.read_text(encoding="utf-8")
    return [f"{path}: expected {token!r}" for token in required if token not in code]


def main() -> int:
    errors = []
    errors += check("scripts/v174_dual_swords.gd", (
        "IDLE_BLADE_LENGTH_SCALE: float = 1.34",
        "ATTACK_BLADE_LENGTH_SCALE: float = 1.17",
        "tip = grip + (tip - grip) * extension",
    ))
    errors += check("scripts/v174_dual_sword_blade.gd", (
        "MODULAR.edge_points(blade_root, blade_tip",
        "var steel_width: float = 6.6 if blade_index == 0 else 6.1",
        "FX_LEVEL.alpha(",
    ))
    errors += check("scripts/v172_weapon_pose.gd", (
        "(tip - grip).normalized() * 76.0",
    ))
    errors += check("scripts/weapon_prestige_fx.gd", (
        'item.weapon_style() == "dual_sword"',
        "0.115 if mythic else 0.065",
    ))
    errors += check("scripts/combat_juice_v194.gd", (
        "static func _render_air_sweep",
        "static func _render_soft_contact",
        'if kind in ["hit", "parry"]:',
    ))
    errors += check("scripts/player.gd", (
        "action_sfx.volume_db = -18.0 if stream == HIT_SFX",
    ))
    errors += check("tests/v213_twinblade_audio_smoke.gd", (
        "DUAL.authored_blade_spans(",
        "JUICE._render(cue)",
        "inv._serialize_item(item",
    ))
    errors += check("tools/run_smoke_suite.sh", (
        "v213_twinblade_audio_smoke.gd",
    ))
    if errors:
        for error in errors:
            print("FAIL:", error, file=sys.stderr)
        return 1
    print("PASS: v2.13 static integration guard; Godot rendering/audio unverified")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
