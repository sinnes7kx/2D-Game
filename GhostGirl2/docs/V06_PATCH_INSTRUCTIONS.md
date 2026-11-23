# Applying v0.6 to an existing GhostGirl master

1. Back up the entire `GhostGirl/` directory and your savegame data.
2. Close Godot. Unzip `GhostGirl_v0_5_2_to_v0_6_Patch.zip` into the **parent directory that contains `GhostGirl/`**. Choose to replace existing files.
3. Open `GhostGirl/project.godot`. Allow the import to finish. The inventory and equipment panels now carry their scripts directly inside their scenes; the previous dynamic HUD script attachment has been removed.
4. Test scenes in order: `scenes/inventory_panel.tscn`, `scenes/equipment_panel.tscn`, `scenes/hud.tscn`, `scenes/main.tscn`, then F5.
5. Press Tab to test the new 10×4 grid, dragging and safe deletion; press C to test equipment. Verify that Q/F, movement, enemy lock and LMB/RMB function.

The patch is intended for the most recent v0.5.2 project (including the direct-script UI repair made in chat). If you have custom modifications to these same scripts or scenes, merge them using Git or a file diff instead of overwriting blindly.

Save compatibility: existing `user://ghost_girl_treasures_v2.json` data is read, with grid positions added on the next save. Make a separate backup of this file if you have valuable equipment.
