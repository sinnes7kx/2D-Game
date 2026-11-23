# GhostGirl v0.5.2 — Scene text parser repair

This update is specifically for Godot editor failures while opening `equipment_panel.tscn`, then `hud.tscn` and `main.tscn`.

## What was changed

- `scenes/equipment_panel.tscn` — rewritten as a basic `PanelContainer` with five Button slots and a details Label; no subresources or external scripts in the scene text.
- `scenes/inventory_panel.tscn` — rewritten as a native 24-slot grid and action buttons; no subresources or external scripts in the scene text.
- `scenes/hud.tscn` — repaired the multiline ControlsGuide text representation.

**Unchanged:** ghost character sprite images, animation resources, Moonrose Hook and 450px range, gameplay scripts, inventory data, equipment controllers, seeded loot, gems/runes and save files. Scene controller scripts are attached at runtime by `scripts/hud.gd`, a behavior retained from v0.5.1.

## Apply

1. **Close Godot.** Back up the existing `GhostGirl` folder.
2. If on v0.5.1, extract the three replacement `.tscn` files from the repair patch into your project, keeping the `GhostGirl/scenes/` folder hierarchy.
3. Reopen the Godot project via Project Manager and allow filesystem scanning/import to finish.
4. Try opening `scenes/equipment_panel.tscn`, `scenes/inventory_panel.tscn`, `scenes/hud.tscn`, then `scenes/main.tscn` in that order.
5. If the editor still shows the old error, verify **the exact file in your local project** contains `[gd_scene format=3]` on line 1 of `equipment_panel.tscn`. If not, the patch was extracted into the wrong folder or the old file is still being loaded.

## Known verification limitation

The repair was statically checked against the packaged project, but Godot 4 could not be launched in the build environment. If it still reports an error, copy the first red Output/Debugger line and the complete content of the affected `.tscn`; the upstream parser message does not include enough detail to prove a specific engine-version incompatibility.
