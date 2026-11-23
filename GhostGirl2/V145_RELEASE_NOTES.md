# Ghost Girl v1.45 — The Listening Moor

**Base:** v1.44 Moonroot Causeways. Incremental Godot 4 patch, not a full project.

## Environmental consequences

- A genuinely collapsed Moonroot lattice, falling support, or shattered barricade sends a local world-disturbance event.
- Nearby Hush Moths, Gloom Lanterns, hunters, and wraiths can investigate the sound for a short time. This does **not** spawn enemies, multiply damage, force an attack, or interrupt a committed attack telegraph. Ordinary aggro remains more important than investigating.
- Collapses produce very faint ground-level threads instead of circular magical overlays.
- Two optional Aftershock Memories in Hollow Veil Moor react to nearby structural destruction and reveal rare reward caches:
  - Western Watchroot, by the v1.44 western lattice (around 3110, 4340)
  - Frostbound Echo, by the eastern frost joint (around 7450, 4880)
- Hints appear on two new waystones.

## Legacy saves

If the relevant v1.44 Moonroot barrier has already been permanently broken in the current save, the associated aftershock reward is unlocked when the moor is loaded. No existing item stats, unlocks or character art are replaced.

## How to test in Godot

1. Back up the v1.44 project and saves.
2. Extract the ZIP into the Godot project root containing `project.godot`, replacing matching files.
3. Open Godot, start the game and use F6 to visit Hollow Veil Moor.
4. Near the western route, collapse the Moonroot barrier by using the rose-hook, fire, Grasping Roses, or an airborne charged arrow. Look for the quiet aftershock and nearby enemies investigating.
5. Near the eastern route, freeze the ironbound joint, then pull it down with the rose-hook. Check for the second memory reward.
6. Save, reload the moor and confirm both rewards remain revealed; check an old save with the supports already destroyed.

## Tests performed

- `tests/validate_v145.py`: scene references, node hierarchy, resources, callbacks, enemy reaction behavior, saved unlocks — PASS.
- Previous targeted `validate_v141.py` through `validate_v144.py`: PASS.
- ZIP extraction, SHA-256 integrity and clean patch-over-v1.44 simulation: checked before publishing.
- **No actual Godot engine/F5 playtest**: the Godot executable is not available in this environment. Steering around the opened routes and final visual timing are therefore unverified.

The v1.44 reference worktree is an incremental-patch working copy, not a rebuilt self-contained original project. This release does not replace missing files from older releases. If resources are missing, install the earlier cumulative dependency repair in the original project first.
