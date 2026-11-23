# Ghost Girl v1.4.2 — SpriteFrames Startup Recovery

**Use this patch on top of the v1.4 or v1.4.1 project folder.**

## What caused the failure?

Godot displayed `res://resources/ghost_girl_frames.tres` as a failed startup dependency. The file existed and all 513 referenced textures checked out on disk. The exact editor parse error could not be confirmed without a Godot executable, but the previous repair only replaced files rather than isolating the large SpriteFrames resource.

## What this patch does

- Replaces `ghost_girl_frames.tres` with the original, known-good core animation resource (36 animation tracks; same art).
- Loads all 46 added combat/rose-hook/dodge/sword/unarmed animation tracks from `ghost_extra_animations.json` after the player scene has loaded.
- If an added frame is missing or fails to import, the game can still open with core movement animations, rather than failing to load `main.tscn`.
- Updates the v1.2/v1.3/v1.4 animation workshop previews to use the same optional loader.
- Does not change inventory data, loot or save formats.

## Install

1. **Close Godot.** Back up your game project.
2. Extract this patch into the parent directory containing `GhostGirl_Act1_RPGDraft` (merge files, replace when prompted).
3. The folder must contain `GhostGirl_Act1_RPGDraft/project.godot`, `scenes/`, `scripts/`, `resources/`, and `assets/`.
4. Open `project.godot` in Godot 4, allow import to complete, and open `scenes/main.tscn`.
5. If necessary, close Godot and remove only the project's `.godot` cache directory before retrying. Do not remove save files.

If it STILL fails, please copy the **first red line from the Output panel**, including file path and line number. The dependency dialog alone does not identify a GDScript parse error.

## Notes

The sprite frame assembly now occurs at runtime; loading the first player may take a moment as optional PNGs are imported. A few frames may not animate if the associated PNGs were not included in your previous v1.4 patch. The game should still open and use the core animations.

This patch has passed static reference and ZIP checks but **has not been playtested in Godot**, which was unavailable in the build environment.
