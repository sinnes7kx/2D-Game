# Ghost Girl v1.29 — Hush Moths & Gloom Lanterns

Incremental patch for **v1.28**.

## New moor inhabitants

- **12 Hush Moths** in four spaced pockets. Light drifting/side-stepping movement; ~13 health, 3 damage, 0.58-second attack warning.
- **12 Gloom Lanterns** in four spaced pockets. Slower approach and broader but slower attack; ~20 health, 4 damage, 0.95-second attack warning.
- All enemies are editor-editable scene instances (`scenes/moor_creature_v129.tscn`) with simple original procedural silhouettes, not hand-painted production sprites yet.
- Both respond to actual melee/bow hits, spells, frost slowing and the rose-hook. No changes to elite strength or to ordinary monster-drop rates. Newly placed creatures have no loot template, so they don't inflate existing drop frequency.
- Hollow Veil Moor now contains **166 placed enemies** in total. Pockets are in optional areas away from the two entry points and special moon targets.

## Readable effects

- **Jumping:** A jump that includes an attack/airborne shot creates a more noticeable colored dust ring and directional sparkle trail on landing. Normal jumps stay subtle.
- **Moonfall:** Each storm pulse briefly marks up to eight confirmed hits with a crystal-fracture ring. This adds no collision and no extra hits.
- **Bows:** Normal impacts get a restrained arrow-specific flash. Rare bow modifiers create rose-comet petals, crescent shards, frost needles, or dusk-helix fragments. The physical projectile remains a single arrow and charged piercing stays capped at two distinct targets.

## Install and verification

Extract directly into the **v1.28 project root** containing `project.godot`, preserving subfolders and replacing existing files. Your saves, original sprite art, room background, and unrelated world scenes are unchanged.

Run `python tests/validate_v129.py` for offline validation. The v1.25–v1.28 validators also passed, but no Godot runtime / F5 playtest was available in this environment. Check moor traversal, creature attack warnings, the jump-attack landing burst, Moonfall hits, and bow impacts in engine before treating this as a stable release.
