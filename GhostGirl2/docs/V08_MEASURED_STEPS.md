# GhostGirl v0.8 — Measured Steps

**Base:** v0.7 Hunter's Rhythm, with the v0.7 inventory-grid hotfix integrated.
**Godot target:** Godot 4.x, Compatibility renderer.
**Status:** Source-level development build. Tested with offline resource/dependency checks; it has **not** been run inside Godot in this environment.

## What changed

### 1. The inventory-grid repair is now part of the complete master
- `scenes/inventory_panel.tscn` explicitly attaches `inventory_panel.gd` and the custom `inventory_grid.gd` to its `Slots` Control.
- Required signals `item_selected`, `item_activated`, `item_move_requested`, and `set_selected()` are present in that grid script.
- This specifically addresses the earlier `GridContainer` / nonexistent signal errors seen after patching v0.7.

### 2. Diablo-style inventory refinements
- **SORT** button in the inventory header packs larger equipment footprints first, followed by smaller objects, placing all items in the earliest available cells.
- Sort changes only item positions: it never changes item indices, equipment references, quality rolls, affixes, sockets, or seeds. Sorting is saved.
- Dragging keeps the cell of the object where the mouse grabbed it, so moving 2×2 and 2×3 items is less surprising. Releasing outside the grid cancels the drag.
- Destroy confirmation now remembers the *exact item* that was confirmed, avoiding accidental destruction of another selected item if selection changes while the dialog is open.
- The loader now remaps equipped indices if a saved resource was deleted or cannot be loaded. It retains the original v1/v2 inventory save location and JSON item format.

### 3. More earned backstep and enemy recovery
- A counterattack is no longer granted just for pressing Space. Lock onto an enemy, read its windup and backstep during the late warning. A counter window is earned only if Ghost Girl actually retreats more than 40 pixels.
- Successful timing gives a small +9 stamina reward and a 0.62 second counterattack window. A faint amber arc appears around Ghost Girl during the window.
- Enemies display a soft ring during post-attack recovery, when they now receive 16% additional melee damage.
- Previous movement restraint, stamina costs, LMB/RMB melee and wand attacks, 450px rose hook, and 196 approved character PNGs remain unchanged.

## How to test

1. **Back up your working GhostGirl folder and saves.** If you use the patch, extract it into the parent directory containing `GhostGirl/`, and allow matching files to be replaced. The patch is cumulative with the v0.7 inventory hotfix.
2. Reopen `project.godot` using **Godot 4** and wait for import. Check `equipment_panel.tscn`, `inventory_panel.tscn`, `hud.tscn`, and `main.tscn` before F5.
3. Press **Tab**. Select an item, drag it by its bottom-right portion, press **SORT**, and verify equipped items remain equipped. Right-click to equip and use the Destroy button to check the confirmation.
4. Press **F11** for Ashen Causeway or **F8** for Bellwether Court. Press **L** near an enemy to lock on. Wait until a telegraphed attack is about to land, press **Space** to backstep, then hit with **LMB/RMB** during its pale recovery ring.
5. Try a melee and an equipped wand, and quit/reopen the game to verify inventory location and equipment are still preserved.

## Limitations and known risks

- This is an incremental polish build, **not** a new region or a live engine-certified release.
- No Godot binary is installed and network access is unavailable in this environment. There is no claim of F5, parser, gameplay, or integration testing inside the engine.
- Static resource checks cannot catch every GDScript syntax/engine API issue. If errors occur, share the first red error (file and line number).
- Inventory has 8 pages of 10×4 grid cells but retains its 40-item cap; more cells do not mean unlimited item storage.
- The new timed counter checks the locked target's late warning and a successful retreat. Unlocked fights and older enemy types do not receive this new timing bonus.

## Affected runtime files
- `project.godot`
- `scenes/inventory_panel.tscn`
- `scripts/inventory.gd`
- `scripts/inventory_grid.gd`
- `scripts/inventory_panel.gd`
- `scripts/player.gd`
- `scripts/gothic_hunter.gd`

A repeatable Python-only source/resource checker is provided at `tests/validate_static.py`; it does **not** replace running Godot.
