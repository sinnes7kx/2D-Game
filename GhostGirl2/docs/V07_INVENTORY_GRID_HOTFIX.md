# GhostGirl v0.7 inventory grid hotfix

This patch repairs a version mismatch when a v0.7 inventory_panel.gd was installed
on top of an older inventory_panel.tscn whose Layout/Slots is a GridContainer.
The v0.7 controller requires the custom Control with inventory_grid.gd attached.

## Install
1. Close Godot. Back up your GhostGirl project and save files.
2. Extract this archive to the directory CONTAINING the GhostGirl folder,
   keeping the GhostGirl/ prefix and allowing the five matching files to overwrite.
3. Check res://scenes/inventory_panel.tscn: Layout/Slots must be Control,
   with its Script set to res://scripts/inventory_grid.gd.
4. Open the scene in Godot, then press F5. Try Tab, selecting an item,
   right-clicking to equip, dragging to move, and deleting with confirmation.

Does not modify saved inventory files, combat scripts, hook or character sprites.
It does replace scripts/inventory.gd and scripts/item_data.gd so the grid and
save format match the UI. Personal edits to these scripts need merging.

Static project-file checks passed; an engine-run F5 test is still needed.
