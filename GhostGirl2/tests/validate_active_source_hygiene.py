#!/usr/bin/env python3
"""M0 active-source safety gate: reject unresolved Git merge markers and stale copies.

Run from any directory:
    python3 GhostGirl2/tests/validate_active_source_hygiene.py
    python3 GhostGirl2/tests/validate_active_source_hygiene.py --self-test

Only active Godot source/resources are scanned; historical documentation may
quote merge markers as explanatory text. Read-only and independent of saves.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import re
import sys

PROJECT = Path(__file__).resolve().parents[1]
EXTENSIONS = {".gd", ".tscn", ".tres", ".gdshader", ".shader", ".godot"}
# A marker must begin a line. A literal operator (<<, >=) is harmless.
START = "<" * 7
DIVIDER = "=" * 7
END = ">" * 7
CONFLICT_MARKER = re.compile(
    r"^(?:" + re.escape(START) + r"(?:\s|$)|" +
    re.escape(DIVIDER) + r"\s*$|" +
    re.escape(END) + r"(?:\s|$))"
)


def find_conflicts(text: str) -> list[tuple[int, str]]:
    return [(line_number, line.strip()) for line_number, line in
            enumerate(text.splitlines(), start=1) if CONFLICT_MARKER.match(line)]


def audit(project: Path) -> list[str]:
    failures: list[str] = []
    duplicate = project / "scripts - Copy"
    if duplicate.exists():
        failures.append(f"Unsafe duplicate script directory exists: {duplicate}")
    for path in sorted(project.rglob("*")):
        if not path.is_file() or path.suffix not in EXTENSIONS:
            continue
        if any(part in {".godot", ".git"} for part in path.relative_to(project).parts):
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            failures.append(f"Unable to read UTF-8 source: {path}")
            continue
        for line, marker in find_conflicts(text):
            failures.append(f"{path.relative_to(project)}:{line}: unresolved marker: {marker}")
    return failures


def self_test() -> None:
    assert len(find_conflicts(START + " HEAD\n" + DIVIDER + "\n" + END + " branch\n")) == 3
    assert find_conflicts("a << 7\nversion >= 7\n# seven equals ======= in prose\n") == []
    assert find_conflicts("    " + START + " HEAD") == []
    print("M0 active-source hygiene self-test: PASS")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
    failures = audit(PROJECT)
    if failures:
        for failure in failures:
            print("ERROR:", failure, file=sys.stderr)
        return 1
    print("M0 active-source hygiene: PASS (no conflict markers or duplicate scripts)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
