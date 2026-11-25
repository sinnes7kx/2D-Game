#!/usr/bin/env python3
"""Offline preflight for the v2.09 collector card + vault parser fix.

Runs with ordinary Python 3; no GitHub Actions, Godot engine, dependencies,
private inventory files or user:// reads. Structural only, NOT a Godot test.
From repository root:
    python3 GhostGirl2/tests/v209_offline_source_preflight.py
"""
from pathlib import Path
import sys

PROJECT = Path(__file__).resolve().parents[1]


def check(path: str, required: tuple[str, ...], forbidden: tuple[str, ...] = ()) -> list[str]:
    name = PROJECT / path
    if not name.is_file():
        return [f"Missing: {path}"]
    text = name.read_text(encoding="utf-8")
    errors = [f"{path}: required code missing: {snippet}" for snippet in required if snippet not in text]
    errors.extend(f"{path}: invalid old code present: {snippet}" for snippet in forbidden if snippet in text)
    return errors


def main() -> int:
    errors = []
    errors += check(
        "scripts/collection_vault_v181.gd",
        ("FILTERS.filtered(candidates,", "favorites.button_pressed, search.text)", "for item in filtered:"),
        ("if not query.is_empty()",),
    )
    errors += check(
        "scripts/v209_collector_share_card.gd",
        ("static func compose(", "ROLL.current(item)", "not verified ownership or rarity", "ROLL.debug_active(item)"),
    )
    errors += check(
        "scripts/collector_lens_v179.gd",
        ("SHARE_CARD.compose(inspected)", "Copy collector card (offline)", "DisplayServer.clipboard_set(card)"),
    )
    errors += check(
        "tests/v209_collector_share_card_smoke.gd",
        ("func _verify()", "inv._serialize_item(item", "CARD.compose(item)"),
    )
    if errors:
        for error in errors:
            print("FAIL:", error, file=sys.stderr)
        return 1
    print("PASS: v2.09 source preflight (structural checks only, Godot F5 still required)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
