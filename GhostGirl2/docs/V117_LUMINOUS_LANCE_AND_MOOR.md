GHOST GIRL v1.17 — LUMINOUS LANCE & MOOR DISCOVERIES
PATCH BASE: v1.16 CRIMSON MOOR

INSTALL
1. Back up your current v1.16 Godot project and save files.
2. Extract this ZIP directly into the project directory containing project.godot.
   The archive paths already start with scripts/, scenes/, tests/, docs/.
3. Replace matching source files. Unchanged backgrounds, original character
   animation sheets, weapon atlases, and saves are not in the patch.
4. Open project.godot in Godot and press F5 to run.

TRY THE NEW RARE SPELL
- F3 (while the game is running) awards one seeded rare Briar Wand with the
  'Luminous Lance' appearance, if you have room in your backpack. Press I,
  then equip the wand; attack/cast to see the single-hit pearl-white beam.
- This trial is once per save to avoid littering your inventory.
- A naturally obtainable rare wand with the same special roll is also hidden
  behind the ordered north-east rose seals in Hollow Veil Moor.
- F6 (while running) enters Hollow Veil Moor for development testing.
- Q pulls loose crates, F hooks onto rose switches/anchors, E opens chests.

FEATURES
- New item-seeded rare wand-only cosmetic Luminous Lance, separate from
  existing saved projectile form rolls. 1/8 rare, 1/6 set, 1/4 unique.
- Soft broad white luminous lance with a tapered tip, dual-color fringe,
  sparkles and a 0.52s fade. It still hits ONCE, obeys walls/crates, and
  does not add extra damage.
- Hollow Veil Moor: 24 additional weak enemies (now 92 total), two ordered
  rose-relay puzzles, five additional treasure caches (8 total), three
  hidden hook-revealed caches, two rest shrines, six extra movable crates.
- Original moor backdrop and approved Ghost Girl character art unchanged.
- All new seals and caches use the existing persistent inventory progression.

VALIDATION
- tests/validate_v117.py static tests pass.
- v1.13 / v1.14 / v1.15 regression checks passed during development.
- The project-wide legacy validator reports its pre-existing two
  inventory-grid signal-name expectations, not new missing resources.
- Godot executable is not available in the build environment: actual F5/F6
  animation, GPU rendering and play feel still require testing in Godot.
