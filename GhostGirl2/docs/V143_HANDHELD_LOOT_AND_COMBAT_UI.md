# Ghost Girl v1.4.3 — Handheld Loot & Combat UI

### Install
Close Godot. Back up the entire project and its `user://` saves. Extract the patch into the folder containing `GhostGirl_Act1_RPGDraft` and replace matching files. Open `project.godot` in Godot 4 and let imports complete. This patch assumes v1.4.2 or later is already installed.

### Item interactions
- **I / Tab / C:** toggle the combined equipment + inventory screen.
- **Left-click an item:** attach a ghosted version of that item to the cursor; it remains in the backpack until committed.
- **Left-click an empty backpack area:** place it at that cell. The entire item footprint must fit. Turn pages while holding an item to move it to another page.
- **Left-click outside both panels:** drop the exact item near Ghost Girl in the world. If almost no world is visible, close the inventory with I while carrying it, then click the ground.
- **DROP TO GROUND:** alternative button when the panels fill the screen.
- **Esc or right-click while holding:** cancel and keep the item in its original backpack position.
- **Right-click a backpack item when not holding one:** equip it, as before.
- **E next to the dropped treasure:** collect the same item (with the same rolls/sockets). Cannot pick up when the backpack is full.
- **Quest items cannot be dropped.** Equipped items will automatically unequip on ground drop. Nothing is permanently destroyed by cancelling a move.

### Changes
- Eliminated the oversized sword icon drawn over the character; the blade is baked into the sword attack and sword-ready sprites. Wand overlays are hidden for the same reason.
- Wings and pendants follow Ghost Girl's AnimatedSprite2D transform rather than being placed in independent world space.
- Removed the extra procedural swing arc that doubled the slash drawn in attack frames.
- Normalized 59 sword/unarmed strike frames that touched or exceeded safe sprite margins. Added eight sword-ready animation tracks for facing and movement, with 256×220 individual frames.
- Added optional 2048×1760 atlases in `art_sources/combat_v143` for direct row-based import.
- Item inspector now uses larger colored names, smaller rarity metadata, mid-sized descriptions, and legible 16px affix stats. The equipped delta appears first in the side-by-side tooltip. Tooltip scrollbars never change inventory panel size.
- Player-dropped items use a separate `user://ghost_girl_ground_loot_v1.json` file; existing character inventory and world save formats are not modified.

### Limitations
- Sword walk/idle poses are made from the baked sword-ready art, with subtle pose movement, as a temporary fix to prevent floating inventory-icon weapons. Fully hand-illustrated sword locomotion would improve the look further.
- World ground drops are restored by room, but no physics simulation or throw-arc is applied to ordinary loot.
- This update has only been statically checked. It must still be imported and playtested in Godot.
