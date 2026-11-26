#!/usr/bin/env python3
"""v2.16 offline source preflight. No Godot, network, or Actions needed.

From the repository root:
  python3 GhostGirl2/tests/v216_offline_preflight.py

This does not prove GDScript parses or that visuals align in F5.
"""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
REPO = ROOT.parent


def verify(name: str, required: tuple[str, ...], forbidden: tuple[str, ...] = ()) -> list[str]:
    path = ROOT / name
    if not path.is_file():
        return [f"{name}: file missing"]
    body = path.read_text(encoding="utf-8")
    return ([f"{name}: required source missing: {value}" for value in required if value not in body] +
            [f"{name}: obsolete source present: {value}" for value in forbidden if value in body])


def animation_alias_errors(source: str) -> list[str]:
    """Narrow merge-regression guard, not a GDScript parser."""
    # Strip comments; versioned script aliases are top-level constants.
    code = "\n".join(line.split("#", 1)[0] for line in source.splitlines())
    declared = set(re.findall(r"^const\s+([A-Z][A-Z0-9_]+)\b", code, re.M))
    used = set(re.findall(r"\b([A-Z][A-Z0-9_]*_V\d+)\s*\.", code))
    return sorted(used - declared)


def main() -> int:
    errors = []
    # A merge removed SWORD_V224's preload while leaving its three calls.
    # Check both the exact dependency and other versioned aliases in the
    # three active animation consumers, before the engine import step.
    for name in ("player.gd", "weapon_prestige_fx.gd", "head_cosmetics_v202.gd"):
        path = ROOT / "scripts" / name
        if not path.is_file():
            errors.append(f"{name}: missing animation consumer")
            continue
        source = path.read_text(encoding="utf-8")
        for alias in animation_alias_errors(source):
            errors.append(f"{name}: undeclared versioned animation alias {alias}")
        errors += verify("scripts/" + name, (
            'const SWORD_V224 = preload("res://scripts/sword_attack_frames_v224.gd")',
        ))
    if not (ROOT / "scripts/sword_attack_frames_v224.gd").is_file():
        errors.append("Missing sword animation dependency: sword_attack_frames_v224.gd")
    if animation_alias_errors("SWORD_V224.install(body_art)") != ["SWORD_V224"]:
        errors.append("Animation alias guard failed its missing-declaration self-check")
    if animation_alias_errors('const SWORD_V224 = preload("res://scripts/sword_attack_frames_v224.gd")\nSWORD_V224.install(body_art)'):
        errors.append("Animation alias guard rejected a valid declaration")
    # The halo conversion used amulet in refresh() after deleting its local.
    visuals = (ROOT / "scripts/equipment_visuals.gd").read_text(encoding="utf-8")
    refresh = visuals.split("func refresh() -> void:", 1)[-1].split("\nfunc ", 1)[0]
    declaration = 'var amulet: GhostItemInstance = inventory.get_equipped("trinket")'
    use = '_rebuild_ambient_sources(feather, amulet,'
    if declaration not in refresh or use not in refresh or refresh.index(declaration) > refresh.index(use):
        errors.append("equipment_visuals.gd: refresh() missing local amulet before ambient rebuild")
    errors += verify("scripts/item_instance.gd", (
        "var glow_level_override: int = -1",
        "var bow_glow_mode_override: int = -1",
        "var bow_projectile_style_override: int = -1",
        '"glow_level_override", "bow_glow_mode_override", "bow_projectile_style_override"',
        'snapshot.get("glow_level_override", -1)',
    ))
    errors += verify("scripts/inventory.gd", (
        '"glow_level_override": item.glow_level_override',
        '"bow_projectile_style_override": item.bow_projectile_style_override',
        'saved.get("glow_level_override", -1)',
        'saved.get("bow_glow_mode_override", -1)',
    ))
    errors += verify("scripts/inventory_panel.gd", (
        'glow_editor.name = "EditableGlowV216"',
        "CheckBox.new()", "_set_glow_choice(", "_refresh_glow_editor(",
        "DebugVisualLayersV216", "func _switch_debug_layers(",
        "if not inventory.save_game():",
        "item.set(field, old_value)",
    ), ("RadioButton.new()",))
    errors += verify("scripts/visual_choices_v216.gd", (
        "static func projectile_style(", "ghostgirl-v216-arrow-decoration:",
        "static func effect_scale(", "static func bow_mode(",
        "return 1.0 if level < 0 else GLOW_LEVELS[level]",
    ))
    errors += verify("scripts/scythe_glow_layer_v211.gd", (
        "if item.glow_level_override >= 0:",
        "return clampi(item.glow_level_override, 0, 5)",
    ))
    errors += verify("scripts/weapon_prestige_fx.gd", (
        "CHOICES_V216.effect_scale(item)",
        "_draw_full_bow_aura(", "CHOICES_V216.bow_string_visible(item)",
        "_draw_v216_visible_fallback(",
        'style == "bow" and not CHOICES_V216.bow_body_visible(item)',
        "if CHOICES_V216.bow_string_visible(item) else Vector2.ZERO",
        "WAND_ANCHORS_V216.rendered_span(body, face)",
    ))
    errors += verify("scripts/collector_lens_v179.gd", (
        "func bind_inventory(value: Node)", "owned_inventory.save_game()",
        "inspected.glow_level_override = previous",
        "scythe_glow_choices.select(clampi(value.glow_level_override + 1, 0, 6))",
    ))
    errors += verify("scripts/collector_lens_model_v179.gd", (
        '"BowGlowLayerV216"', "CHOICES_V216.bow_body_visible(item)",
        "FX_LEVEL.intensity > 0.0", "1.0 if mode == 3 else 0.8",
    ))
    errors += verify("scripts/bow_arrow_v126.gd", (
        "var projectile_style: int = 0", "var visual_glow_scale: float = 1.0",
        "if visual_glow_scale <= 0.0:",
        "func _impact(where: Vector2)",
    ))
    errors += verify("scripts/player.gd", (
        'arrow.set("projectile_style", VISUAL_CHOICES_V216.projectile_style(equipped))',
        'arrow.set("visual_glow_scale", VISUAL_CHOICES_V216.effect_scale(equipped))',
        "WAND_ANCHORS_V216.world_tip(self)",
    ))
    errors += verify("scripts/bow_projectile_art_v216.gd", (
        "static func draw_motif(", "1: # Moonthread",
        "2: # Twin Helix", "8: # Wisp Bloom",
    ))
    errors += verify("scripts/arrow_glow_v154.gd", (
        "MOTIF_V216.draw_motif(", "FX_LEVEL.intensity <= 0.0",
    ))
    errors += verify("scripts/scythe_rig_v190.gd", (
        "var show_light: bool = equipped == null or equipped.glow_level_override != 0",
        "style, ashglass, side, show_light, active_item_id",
    ))
    errors += verify("scripts/v174_dual_sword_blade.gd", (
        "var lit: bool = owned == null or owned.glow_level_override != 0",
    ))
    errors += verify("scripts/player.gd", (
        "if VISUAL_CHOICES_V216.effect_scale(equipped) > 0.0:",
    ))
    errors += verify("scripts/wand_anchors_v216.gd", (
        "static func target_grip(", "static func rendered_span(",
        "static func world_tip(", "static func alignment_offset(",
    ))
    errors += verify("scripts/equipment_visuals.gd", (
        "WAND_ANCHORS_V216.rows()", "WAND_ANCHORS_V216.alignment_offset(",
    ))
    errors += verify("scripts/wand_idle_glimmer.gd", (
        "WAND_ANCHORS_V216.rendered_span(", "to_local(body.to_global(points[0]))",
    ))
    errors += verify("scripts/game.gd", (
        "bolt.global_position = WAND_ANCHORS_V216.world_tip(player)",
    ))
    errors += verify("tests/v216_editable_fx_bow_wand_smoke.gd", (
        "inv.save_block_reason =", "CHOICES.projectile_style(", "WAND.target_grip(",
        "v2.16 PASS:", "Bow body/string visibility does not match selected mode",
    ))
    workflow = (REPO / ".github/workflows/ghostgirl-godot-smoke.yml").read_text(encoding="utf-8")
    if "workflow_dispatch:" not in workflow or "  pull_request:" in workflow or "  push:" in workflow:
        errors.append("GitHub Actions must remain manual-only while credits are unavailable")
    if errors:
        for error in errors:
            print("FAIL:", error, file=sys.stderr)
        return 1
    print("PASS: v2.16 source preflight only; Godot parser/F5 still required")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
