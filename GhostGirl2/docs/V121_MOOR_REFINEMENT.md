# Ghost Girl v1.21 — Moor Refinement and VFX Crash Fix

**Base:** Ghost Girl v1.20 Lantern Paths, including its scene parse hotfix if already installed.
Extract this patch **into the project root** (the folder containing `project.godot`) and allow file replacement. The ZIP contains relative project paths without an extra top-level folder.

## World and enemy layout

- Keeps the same 10,368 × 6,912 original gothic grassland background.
- Redistributes **all 136 existing enemy instances** over the whole area in intentionally separated encounters. No extra enemies or loot are created.
- Preserves existing enemy properties, save keys, hooks, treasure, shrines and entry/exit portals.
- Moves tree-trunk and ruin collision shapes onto the painted landmarks; removes 2 phantom tree collisions that had no corresponding trunk in the new image. Leaves open ground traversable.

## Water

The scene's `Gameplay/WaterBodies` node is the organizational container, not a pond. It is reset to the world origin, and contains three independently editable `Area2D` nodes:

- `MoorWater1` — Western Mire
- `MoorWater2` — Moonlit Basin
- `MoorWater3` — Northern Tarn

Each water area has a `CollisionPolygon2D` under `WaterPolygon`. Select and edit `WaterPolygon` in the **2D** editor to change the water outline. The polygons are **detection areas, not blocking walls**. A lightweight `Ripples` node provides subtle surface movement; fishing is not implemented.

## Weather

The scene now has a `MoorRain` node. The configurable `intensity`, `wind`, and `streak_count` Inspector properties control a subdued local shower around the player, so it does not draw rain across the entire 10K×7K map at once. Rain defaults to 0.42 intensity. You can set it to `0.0` to disable it.

## Spectacle crash

The previous error `Invalid call to function 'configure (via call)' in base 'Node2D (weapon_spectacle.gd)'. Expected 5 argument(s)` came from the incompatible fallback invocation. Both the melee and wand spectacle effects now initialize their properties directly, **without calling that method**. The separate correct 7-argument `impact_prestige_v116.gd` calls remain intact.

## Validation and limitations

`tests/validate_v121.py` checks scene formatting and node tree, all new resources, enemy count/distribution, water polygons, and both spectacle paths. It passed on the packaged sources. These are static checks only: a **Godot 4.x editor import and actual gameplay test** are still needed, including performance, collisions, save/load and visuals. The old all-purpose validator still has two pre-existing inventory signal-name assumptions, and one false-positive resource-template check.

**Important:** Replacing the scene will overwrite manual node placement changes you made directly to `hollow_veil_moor.tscn`. Back it up before patching if you want to preserve those edits.
