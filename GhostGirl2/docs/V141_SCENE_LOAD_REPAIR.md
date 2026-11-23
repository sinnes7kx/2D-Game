# Ghost Girl v1.4.1 — Scene Loading / Dependency Repair

This release fixes a distribution issue in v1.4: the three separate ZIPs scattered the startup scene, player scene, SpriteFrames resource, and the textures referenced by SpriteFrames across different archives. If all three were not extracted into the **same** folder, Godot showed `Load failed due to missing dependencies` for `res://resources/ghost_girl_frames.tres` and `res://scenes/player.tscn`.

## Recommended installation (single archive)

1. Make a backup of your old project folder and your Ghost Girl save if relevant.
2. Extract `GhostGirl_v1.4.1_Complete_One_Zip.zip` to a **new empty parent folder**.
3. You should have `GhostGirl_Act1_RPGDraft/project.godot` and its `assets/`, `scenes/`, `resources/`, `items/`, and `scripts/` folders together.
4. Open Godot **4.7 or later** > Project Manager > Import > select `project.godot`. Allow imports to finish. Press F5.
5. If you copied an old `.godot` import-cache directory into the new project, close Godot and remove **only the `.godot/` cache folder** then re-import. Do not delete `user://` save data.

## Minimal fix if you already have the complete v1.4 three-part extraction

Extract `GhostGirl_v1.4.1_Loading_Repair.zip` into the existing parent folder, and choose merge/replace. It includes the critical scenes, SpriteFrames, SpriteFrames textures, and a verification script. **It cannot replace missing world art or scripts from an incompletely extracted v1.4 project.**

## Verification

Inside `GhostGirl_Act1_RPGDraft`, run `python tools/verify_install.py` (or double-click `CHECK_INSTALL_WINDOWS.bat`). It checks literal res:// resource references and the startup files. A PASS is not a substitute for Godot parsing and running the project; if it still fails, open the Godot Output tab and copy the first parsing error with the line number.

## Changes

- Restored startup dependencies in a single-file project distribution.
- Critical scenes and SpriteFrames now use direct res:// paths without potentially stale imported UID hints.
- The default player animation and autoplay now both point to idle_front.
- No user save files, item definitions, player art, or combat logic were changed.

## Runtime testing limitation

Godot itself was not available in this container, so this build has passed offline reference/ZIP checks, not a live Godot editor import or playtest.
