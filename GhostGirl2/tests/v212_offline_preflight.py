#!/usr/bin/env python3
"""v2.12 offline source checks. No Actions, Godot engine, or save access.

Run from repository root:
  python3 GhostGirl2/tests/v212_offline_preflight.py

These are structural checks only. Real F5 dagger visual alignment is pending.
"""
from pathlib import Path
import sys

GAME = Path(__file__).resolve().parents[1]
REPO = GAME.parent


def verify(file: Path, required: tuple[str, ...], forbidden: tuple[str, ...] = ()) -> list[str]:
    if not file.is_file():
        return [f"Missing: {file}"]
    content = file.read_text(encoding="utf-8")
    return ([f"Missing in {file.name}: {s}" for s in required if s not in content] +
            [f"Obsolete in {file.name}: {s}" for s in forbidden if s in content])


def main() -> int:
    findings = []
    findings += verify(GAME / "scripts/player.gd", (
        'if active_attack_style == "dagger":',
        '"_heavy_pierce_" if heavy else "_pierce_"',
        'dagger_charge_active = heavy and active_attack_style == "dagger"',
        'Input.is_action_pressed("attack_heavy")',
        'attack_duration = 0.94 if heavy',
        'if active_attack_style != "dagger":',
    ))
    findings += verify(GAME / "scripts/collection_vault_v181.gd", (
        "FILTERS.filtered(candidates,",
    ), ("if not query.is_empty()",))
    findings += verify(GAME / "tools/run_smoke_suite.sh", (
        "mode=\"${1:-quick}\"", "v212_dagger_stab_smoke.gd",
        'if [[ "$mode" == full ]]; then',
    ))
    findings += verify(REPO / ".github/workflows/ghostgirl-godot-smoke.yml", (
        "workflow_dispatch:", "default: quick",
        "bash GhostGirl2/tools/run_smoke_suite.sh",
    ), ("  pull_request:", "  push:"))
    findings += verify(GAME / "tools/build_legacy_atlas.py", (
        "def sequences()", "def build(", '"integrated": False',
        'atlas_candidates.json',
    ))
    if findings:
        for line in findings:
            print("FAIL:", line, file=sys.stderr)
        return 1
    print("PASS: v2.12 offline source checks (not Godot rendering verification)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
