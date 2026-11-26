#!/usr/bin/env python3
"""Ensure the local ordered quick/full suites cover every smoke script once."""
from collections import Counter
from pathlib import Path
import re
import sys

PROJECT = Path(__file__).resolve().parents[1]


def audit(runner: str, expected: set[str]) -> list[str]:
    errors = []
    listed = []
    for name in ("quick_tests", "full_tests"):
        matches = re.findall(r"^" + name + r"=\(\s*\n(.*?)^\)", runner,
                             flags=re.MULTILINE | re.DOTALL)
        if len(matches) != 1:
            errors.append(f"Expected exactly one {name} array")
            continue
        for line in matches[0].splitlines():
            entry = line.split("#", 1)[0].strip()
            if entry:
                listed.append(entry)
    counts = Counter(listed)
    errors.extend(f"Missing smoke registration: {x}" for x in sorted(expected - counts.keys()))
    errors.extend(f"Unknown smoke registration: {x}" for x in sorted(counts.keys() - expected))
    errors.extend(f"Duplicate smoke registration: {x}" for x, n in sorted(counts.items()) if n > 1)
    return errors


def main() -> int:
    runner = (PROJECT / "tools/run_smoke_suite.sh").read_text(encoding="utf-8")
    expected = {p.name for p in (PROJECT / "tests").glob("*_smoke.gd") if p.is_file()}
    if not expected:
        print("FAIL: No smoke scripts found", file=sys.stderr)
        return 1
    errors = audit(runner, expected)
    if errors:
        for error in errors:
            print("FAIL:", error, file=sys.stderr)
        return 1
    print(f"PASS: {len(expected)} Godot smoke scripts registered exactly once (not executed)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
