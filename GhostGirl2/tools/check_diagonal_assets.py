"""Verify the exact v249 repair art and optionally require it to be tracked.

Run from anywhere: python GhostGirl2/tools/check_diagonal_assets.py --tracked
No external packages; does not modify the repository.
"""
import argparse
import hashlib
from pathlib import Path
import struct
import subprocess

PROJECT = Path(__file__).resolve().parents[1]
ASSETS = {
    "ghost_diagonal_v249.png": "9e7de8d90df531f5c6e945d80e4dfeed5a1f7ec293ea427aecaad2511d8db9e2",
    "ghost_diagonal_actions_v249.png": "81315cffbfc77de16f676e3a43ec1c404b2e0582bfa800dc7e57df6cf29e4a98",
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tracked", action="store_true", help="Also require both files in the Git index")
    args = parser.parse_args()
    errors = 0
    for name, expected in ASSETS.items():
        relative = Path("assets/ghost/skins") / name
        path = PROJECT / relative
        if not path.is_file():
            print(f"MISSING: {path}")
            errors += 1
            continue
        data = path.read_bytes()
        valid = (
            len(data) >= 33 and data[:8] == b"\x89PNG\r\n\x1a\n"
            and data[12:16] == b"IHDR"
            and struct.unpack(">IIBB", data[16:26]) == (2048, 1760, 8, 6)
        )
        digest = hashlib.sha256(data).hexdigest()
        if not valid or digest != expected:
            print(f"DIFFERENT ART: {path}; expected original repair PNG and hash {expected}; got {digest}")
            errors += 1
            continue
        if args.tracked:
            result = subprocess.run(
                ["git", "-C", str(PROJECT), "ls-files", "--error-unmatch", "--", relative.as_posix()],
                capture_output=True, check=False,
            )
            if result.returncode:
                print(f"NOT TRACKED: {path}")
                errors += 1
                continue
        print(f"OK: {name} (2048x1760 RGBA, matching SHA256)")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
