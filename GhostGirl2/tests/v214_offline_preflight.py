#!/usr/bin/env python3
"""Scythe FX regression guard requiring no Godot installation or Actions.

Run from repo root:
  python3 GhostGirl2/tests/v214_offline_preflight.py

Structural/source checks only. Does not validate GPU rendering or player saves.
"""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]


def check(name: str, needed: tuple[str, ...], forbidden: tuple[str, ...] = ()) -> list[str]:
    path = ROOT / name
    if not path.is_file():
        return [f"Missing: {name}"]
    data = path.read_text(encoding="utf-8")
    return ([f"{name}: missing {token!r}" for token in needed if token not in data] +
            [f"{name}: obsolete {token!r}" for token in forbidden if token in data])


def main() -> int:
    issues = []
    issues += check("scripts/scythe_rig_v190.gd", (
        "SCYTHE.draw_scythe(self, points[0], points[1], profile, look, colors, phase, side, true)",
        'scythe_glow.call("clear_pose")',
    ), ("phase, side, false)",))
    issues += check("scripts/collector_lens_model_v179.gd", (
        "SCYTHE.draw_scythe(self, Vector2(-12, 20), Vector2(-12, -56), p, look, gradients, elapsed, 1.0, glow_enabled)",
        '"set_pose", item,',
    ), ("elapsed, 1.0, false)",))
    issues += check("scripts/scythe_glow_layer_v211.gd", (
        "var last_fx_revision: int = -1",
        "last_fx_revision == FX_LEVEL.revision",
        "last_fx_revision = FX_LEVEL.revision",
        "var widths: Array[float] = [22.0, 13.0, 5.5]",
        "alpha * 0.86",
        "if int(digest[0]) < 179:",
    ))
    issues += check("scripts/collector_lens_v179.gd", (
        'scythe_glow_choices.add_item("Rolled aura")',
        "Blade highlights + rolled aura",
        "Blade highlights + preview aura",
    ))
    issues += check("tests/v214_scythe_effects_smoke.gd", (
        "SCYTHE.draw_scythe(self,",
        "FX_LEVEL.set_intensity(",
        "inv._serialize_item(",
    ))
    issues += check("tools/run_smoke_suite.sh", ("v214_scythe_effects_smoke.gd",))
    if issues:
        for issue in issues:
            print("FAIL:", issue, file=sys.stderr)
        return 1
    print("PASS: independent scythe edge + rolled aura structural checks (F5 still required)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
