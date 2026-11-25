#!/usr/bin/env python3
"""v2.10 offline structural preflight. No Godot, network or GitHub Actions.

From repository root: python3 GhostGirl2/tests/v210_offline_preflight.py
This does NOT replace F5 review and script parsing in the Godot editor.
"""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]


def check(path: str, required: tuple[str, ...], forbidden: tuple[str, ...] = ()) -> list[str]:
    f = ROOT / path
    if not f.is_file():
        return ["Missing " + path]
    data = f.read_text(encoding="utf-8")
    errors = [f"{path}: missing {token}" for token in required if token not in data]
    errors += [f"{path}: obsolete {token}" for token in forbidden if token in data]
    return errors


def main() -> int:
    errors = []
    errors += check(
        "scripts/inventory_panel.gd",
        ("$Layout/DetailsHeader.hide()", "description.hide()", "_create_cosmetic_radio_panel()",
         "RadioButton.new()", "_radio_preview(", "_radio_natural(", "_refresh_cosmetic_radio_panel("),
    )
    errors += check(
        "scripts/head_cosmetics_v202.gd",
        ("CanvasItemMaterial.BLEND_MODE_MIX", "Vector2(-17.0, -22.0)", "Vector2(17.0, -22.0)"),
        ("Vector2(-19.0, -72.0)",),
    )
    errors += check(
        "scripts/bow_palette_overlay_v139.gd",
        ('"left": Vector2(22.0, 13.0)', '"right": Vector2(-9.0, 5.0)',
         "bow_carry_visual.position = Vector2(3.0, -1.0)"),
    )
    errors += check(
        "scripts/weapon_surface_v190.gd",
        ("0.94 if overlay", "0.16)"),
    )
    errors += check(
        "assets/equipment/weapon_surface_v190.gdshader",
        ("alpha *= clamp(strength, 0.0, 0.98);",),
        ("alpha *= amount * 0.88;",),
    )
    errors += check(
        "scripts/item_rich_text.gd",
        ("[url=visual:%s]", "Special look:", "Glow: ", "Bow colors · whole bow palette"),
        ("[url=visual:%s:%d]",),
    )
    if errors:
        for error in errors:
            print("FAIL:", error, file=sys.stderr)
        return 1
    print("PASS: v2.10 structural preflight; Godot import/F5 still required")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
