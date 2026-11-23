# v0.6 -> v0.7 update patch

1. Back up your working `GhostGirl/` Godot project and all local save files.
2. **Close Godot**. Extract this ZIP into the folder containing `GhostGirl/`, overwriting matching files (do not extract the folder into another `GhostGirl/`).
3. Reopen Godot and allow imports to finish. Open `equipment_panel.tscn`, `inventory_panel.tscn`, `hud.tscn`, then `main.tscn`. Press F5.
4. If the editor shows a parse error, capture the **first red error with filename and line**. Static validation passed here but the native Godot editor was unavailable.

No old item definitions, character art, rose hook assets, or inventory save formats were changed. The new `.tres` item definitions are added alongside existing ones, and combat scripts are updated.
