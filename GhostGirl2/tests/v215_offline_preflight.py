#!/usr/bin/env python3
"""v2.15 offline source preflight, no Godot/Actions/save access.

Run: python3 GhostGirl2/tests/v215_offline_preflight.py
Checks wiring only. Interactive pupil alignment and palette art still require F5.
"""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
REPO = ROOT.parent


def check(path: str, required: tuple[str, ...], forbidden: tuple[str, ...] = ()) -> list[str]:
    source = ROOT / path
    if not source.is_file():
        return ["Missing: " + path]
    body = source.read_text(encoding="utf-8")
    return ([f"{path}: required code missing: {needle}" for needle in required if needle not in body] +
            [f"{path}: old code present: {needle}" for needle in forbidden if needle in body])


def main() -> int:
    errors = []
    errors += check("scripts/head_cosmetics_v202.gd", (
        "pose_eye_centers(", "Vector2(9.0, -43.0)", "Vector2(37.0, -43.0)",
        "eye_style_override", "eye_palette_override", "last_eye_pose_key",
        "CanvasItemMaterial.BLEND_MODE_MIX",
    ), ("Vector2(-17.0, -22.0)",))
    errors += check("scripts/item_instance.gd", (
        "var eye_style_override: int = -1", "var eye_palette_override: int = -1",
        '"eye_style_override", "eye_palette_override"',
    ))
    errors += check("scripts/inventory.gd", (
        '"eye_style_override": item.eye_style_override',
        'saved.get("eye_palette_override", -1)',
    ))
    errors += check("scripts/inventory_panel.gd", (
        '"EyeStyleEditorV215"', "eye_editor", "CheckBox.new()",
        "func focus_eye_item(", "if not inventory.save_game():",
        "item.eye_style_override = previous_shape",
    ), ("RadioButton.new()",))
    errors += check("scripts/equipment_panel.gd", (
        "signal edit_eyes_requested(", "EditEyesV215", "edit_eyes_requested.emit(eyes)",
    ))
    errors += check("scripts/hud.gd", (
        "KEY_I, KEY_B", "func _open_eye_editor(",
        'inventory_panel.call("focus_eye_item", item)',
    ))
    errors += check("scripts/collector_lens_model_v179.gd", (
        "ActualBowPaletteMaskV215",
        "bow_painted_mask", "BOW_POSE.idle_hold_pose",
        "bows_v166/%s_carry_only_2048x1760.png",
        "bows_v139/%s_locomotion_mask_2048x1760.png",
        "PAINTED_SURFACE.bow_pigment(item, look)",
        "elapsed, 1.0, glow_enabled)",
    ))
    errors += check("scripts/weapon_prestige_fx.gd", (
        "mask.visible", "carry.visible", "target = carry",
        'item.weapon_style() == "bow"',
    ))
    errors += check("scripts/scythe_rig_v190.gd", (
        "equipped.glow_level_override != 0", 'if not visible or style != "scythe":',
    ))
    errors += check("scripts/scythe_glow_layer_v211.gd", (
        "last_fx_revision == FX_LEVEL.revision",
        "var widths: Array[float] = [22.0, 13.0, 5.5]",
    ))
    errors += check("tests/v215_eyes_bows_input_fx_smoke.gd", (
        "pose_eye_centers(", "inv._deserialize_item(saved)",
        "inv.save_block_reason =", "ActualBowPaletteMaskV215",
    ))
    project = (ROOT / "project.godot").read_text(encoding="utf-8")
    heal = re.search(r"(?m)^use_dew=\{(.*?)\n\}", project, flags=re.S)
    inventory = re.search(r"(?m)^inventory=\{(.*?)\n\}", project, flags=re.S)
    if heal is None or '"physical_keycode":78' not in heal.group(1):
        errors.append("Healing must be mapped to N, not B")
    if inventory is None or '"physical_keycode":66' not in inventory.group(1):
        errors.append("Inventory must have a B key action")
    workflow = (REPO / ".github/workflows/ghostgirl-godot-smoke.yml").read_text(encoding="utf-8")
    if "workflow_dispatch:" not in workflow or "  pull_request:" in workflow or "  push:" in workflow:
        errors.append("Actions must remain manual-only")
    if errors:
        for msg in errors:
            print("FAIL:", msg, file=sys.stderr)
        return 1
    print("PASS: v2.15 source preflight (not a Godot renderer test)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
