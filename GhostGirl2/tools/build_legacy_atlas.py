#!/usr/bin/env python3
"""Non-destructive sprite-sheet experiment for legacy Ghost Girl frames.

From repo root:
  python3 GhostGirl2/tools/build_legacy_atlas.py --report
  python3 GhostGirl2/tools/build_legacy_atlas.py --build --output /tmp/ghost-atlases

The active .tres, .tscn and game resources are NEVER rewritten. Pillow is
required only for --build; --report works with stock Python. Generated atlases
remain candidates until verified against authored animation frame mappings.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re

PROJECT = Path(__file__).resolve().parents[1]
FRAME = re.compile(r"^(?P<animation>.+)_(?P<frame>0[0-7])\.png$")


def sequences() -> dict[str, list[Path]]:
    groups: dict[tuple[Path, str], dict[int, Path]] = {}
    for file in (PROJECT / "assets").rglob("*.png"):
        match = FRAME.match(file.name)
        if match:
            key = (file.parent, match.group("animation"))
            groups.setdefault(key, {})[int(match.group("frame"))] = file
    return {
        str(parent.relative_to(PROJECT) / name): [frames[i] for i in range(8)]
        for (parent, name), frames in sorted(groups.items())
        if len(frames) == 8 and all(i in frames for i in range(8))
    }


def build(destination: Path, groups: dict[str, list[Path]]) -> None:
    from PIL import Image
    destination.mkdir(parents=True, exist_ok=True)
    manifest = []
    for name, frames in groups.items():
        source = [Image.open(p).convert("RGBA") for p in frames]
        sizes = {(image.width, image.height) for image in source}
        if len(sizes) != 1:
            print(f"SKIP {name}: inconsistent source dimensions")
            continue
        width, height = source[0].size
        # 8 columns x 1 row, frame rectangles stay exact and unmoved.
        atlas = Image.new("RGBA", (width * 8, height))
        for i, image in enumerate(source):
            atlas.paste(image, (i * width, 0))
        target = destination / (name.replace("/", "__") + "_8x1.png")
        atlas.save(target, optimize=True)
        manifest.append({
            "source_group": name,
            "output": str(target),
            "frame_count": 8,
            "frame_size": [width, height],
            "source_frames": [str(p.relative_to(PROJECT)) for p in frames],
            "regions": [[i * width, 0, width, height] for i in range(8)],
            "integrated": False,
        })
    (destination / "atlas_candidates.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Built {len(manifest)} unlinked atlas candidates in {destination}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", action="store_true")
    parser.add_argument("--build", action="store_true")
    parser.add_argument("--output", type=Path, default=Path("/tmp/ghostgirl-atlas-candidates"))
    args = parser.parse_args()
    groups = sequences()
    originals = sum(len(files) for files in groups.values())
    print(f"Found {len(groups)} full eight-frame sequences ({originals} legacy PNGs)")
    for name in list(groups)[:20]:
        print(" ", name)
    if args.build:
        build(args.output, groups)
    elif not args.report:
        parser.print_help()


if __name__ == "__main__":
    main()
