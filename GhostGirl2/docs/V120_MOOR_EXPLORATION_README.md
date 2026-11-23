# Ghost Girl v1.20 — Hollow Veil Moor: Lantern Paths

This cumulative moor update contains the expanded painted background from v1.19 and adds a gameplay pass on top of it. Apply it to a v1.18 or v1.19 project, replacing matching files in the folder that holds `project.godot`.

## What is placed in the scene

- **10368×6912** textured moonlit grassland (more than five times v1.16's area), retaining both entrances and all earlier treasure, shrines, and puzzle states
- **7 editor-owned waystones** marking the Low Lantern Road, Moss Graves, Weeping Crossroads, Sunken Moonwell, Crescent Rise, Silted Lily Fen, and North Watch
- **11 subtle path lanterns** that help guide travel without impassable corridors
- **10 separated packs of 4 weak rose-wraiths**, each with 9–13 health, plus 4 forgiving mourners; **136 enemies total** including the earlier moor's occupants
- **6 additional treasure caches**, including two rose-hook secret coffers and a moonwell weight-seal reward; **14 total caches**
- **2 more rest shrines**, bringing the area to four
- **1 new weight-seal puzzle** using an actual hook-pullable moonstone crate and a persistently unlocked chest
- Fixed the room binding so `weighted_rose_plate.gd` can restore its saved `discovery_id` on re-entry.

## Controls and route hints

- **E** while facing a nearby waystone: read a concise route or detour clue.
- **F** to latch a faint rose-hook secret: reveal its coffer.
- **Q** hooks a movable crate. **E** lifts it; **G** drops it on the rose plate.
- **F6** (existing debug shortcut): jump to Hollow Veil Moor.

Primary route: Briar Hollow (southwest) → Low Road → Moss Graves → Weeping Crossroads → Crescent Rise → North Watch → Moonthorn Woods (northeast). Detours branch toward Sunken Moonwell and Lily Fen, with route signs helping you return. The room remains traversable outside the marked road.

## Files changed in the cumulative patch

- `assets/world/hollow_veil_moor_v118.jpg` — expanded painted base (from v1.19)
- `scenes/rooms/hollow_veil_moor.tscn` — boundary geometry, exits, original content, waystones, lanterns, patrols, rewards, puzzles, shrines
- `scripts/game.gd` — readable waystone prompts and saved weight-seal restore
- `scripts/moor_waystone.gd` — drawable, editable waystones
- `scripts/moor_lantern.gd` — small ambient guides
- `tools/expand_hollow_veil_moor_v120.py` — reproducible scene placement
- `tests/validate_v119.py`, `tests/validate_v120.py`

## Validation limits

Offline v1.18, v1.19 and v1.20 checks pass. Godot itself was not installed in the editing environment, so please open the game in the editor and test the scene. Static checks cannot guarantee that every painting landmark lines up perfectly with walkable collisions, path flow, or rendering performance on your hardware. The additional groups deliberately avoid heavy particle systems.
