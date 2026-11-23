# GhostGirl v0.5.1 — UI Dependency Repair

## Reported issue
Opening `scenes/main.tscn` produces an error chain through `scenes/hud.tscn` to `scenes/equipment_panel.tscn`. The user also reported trouble opening the inventory and equipment panels independently. The v0.5 archive **does contain** these scene files and their scripts, so an ordinary missing ZIP entry is not the apparent cause.

## What changed

- `scenes/inventory_panel.tscn` and `scenes/equipment_panel.tscn` are now **script-independent, native Godot UI scene layouts**, so they can be opened in the editor without also loading all custom item script classes.
- `scripts/hud.gd` attaches the corresponding controller scripts on entering the running scene tree. Its binding and toggle methods handle controller-load failures gracefully.
- `scripts/inventory_panel.gd` and `scripts/equipment_panel.gd` no longer use the custom `GhostItemInstance` type in their variable annotations. The inventory panel also uses a small built-in stat-name formatter to avoid an unnecessary class dependency.
- The existing `scripts/inventory.gd`, item-generation classes, equipment slots, save paths, gameplay code and scene content are **unchanged**.
- Original character sprites, animations, hook resources and combat scenes are **untouched**.

This is a defensive fix for scene-load dependency fragility. Without the Godot executable and editor logs, the precise root cause of the previous failure could not be reproduced, so **a successful F5 run is not claimed**.

## Installing the repair

### New project (easiest diagnostic)
1. Unzip `GhostGirl_Master_v0_5_1_UI_Repair.zip` into a **fresh** folder, leaving the `GhostGirl` top-level folder intact.
2. In Godot 4, choose **Import** and point to `GhostGirl/project.godot`.
3. Allow Godot to complete file scanning/importing.
4. In this order, open `scenes/equipment_panel.tscn`, `scenes/inventory_panel.tscn`, `scenes/hud.tscn`, and `scenes/main.tscn`.
5. Press F5 to check gameplay. Tab opens inventory, C opens equipment. Ensure both windows populate with items, that the rose hook still works (Q/F), and that player artwork is unchanged.

### Updating the existing v0.5 master
1. Back up the `GhostGirl` folder.
2. Extract `GhostGirl_v0_5_to_v0_5_1_UI_Repair_Patch.zip` **into the parent directory of `GhostGirl`**, allowing replacement of the five existing UI scene/script files and addition of this guide.
3. Close Godot, reopen the project and allow the import to finish.
4. If the editor continues displaying stale missing dependencies, close it, delete *only* the project's generated `.godot/` directory, reimport the same `project.godot`, and inspect the Output/Debugger panel for the first script parse error.

Do **not** delete `resources/`, `items/`, save files, or game sprites. This patch does not reset your persistent save data (`user://`).

## Editor model
The inventory and equipment scenes are visual layouts. Their controller scripts run in the game (attached from `scripts/hud.gd`) but are not attached to the standalone panel scenes in the editor. Move and restyle panel nodes normally; keep the node names used by controller scripts.

## Validation performed
- The repaired project contains both independent UI scene files and their expected controller `.gd` scripts.
- All 40 scenes have valid relative `res://` file references and matching resource IDs; no cycles were found among scene-to-scene dependencies.
- UI scenes can be parsed at the text/resource-graph level without depending on custom item classes.
- Archive integrity and presence of required game resources were verified.
- **No live Godot F5 or actual UI open test was available in the build environment.**

If the error remains, capture the **first red Script Error / Parse Error line** from Godot's Output panel. That line will identify the actual failing script and line number.
