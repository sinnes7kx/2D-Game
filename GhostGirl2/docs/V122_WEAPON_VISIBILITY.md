# Ghost Girl v1.22 — Weapons Finally Visible

Apply **on top of v1.21**. Extract the patch at the project root (where `project.godot` lives). Overwrite matching paths.

## What changed

- The equipped **Rose Reaper scythe** and **Lunar Vigil halberd** are now visibly painted into their matching Ghost Girl animation frames. The hand placement does not depend on a separate animated attachment being synchronized or loaded.
- Four new 2048×1760 animation atlases preserve 256×220 frames, eight frames per directional row, including four-direction idle, walking, light attacks, and heavy attacks.
- Godot's existing `ghost_animation_library.gd` installs those baked atlases under the same 32 animation names. No save file migration, input changes, or item stat changes.
- The old `Ghost/WeaponLayers` node is retained for item-seeded sparkle/glow effects, but its Back/Front sprites are hidden to prevent doubled weapons and missing-overlay warnings.
- The existing item base-palette tint reaches the main character shader; the detailed four-channel surface/engraving shader is **not fully reproduced** on the baked pixels in this pass and remains a future polish task.
- The original approved character source assets and the hook mechanic are unchanged. The original dodge animation may still display its older dagger painting.

## Quick in-game test

1. Open the project and run with **F5**.
2. Press **F7** to receive trial copies of the weapons (if not already present).
3. Open inventory with **I**; equip **Rose Reaper**.
4. Stand and walk facing **front, back, left, right**; light and heavy attacks should show the weapon in Ghost Girl's hand.
5. Equip **Lunar Vigil Halberd** and repeat.
6. If weapons are missing, check Godot's Import tab and verify all four `weapon_baked_v122` PNGs exist, then close/reopen the project so imports refresh.

## Validation

`python tests/validate_v122.py` checks the 32 animation manifest names, rows, four atlas dimensions, all 256 non-empty frames, and FX connections. This is a static/source test. A real Godot F5 rendering/play test is still required.
