# Act I Wilderness — Godot editor guide

## New areas and how to reach them

Play F5 from `scenes/main.tscn`. Follow `Moonwake Crypt → Waking Garden → Rose Arbor → Moonthorn Woods → Weeping Brook → Broken Rose Bridge → Waking Garden`. The Brook and Bridge connect in both directions. Both outdoor additions are **exploration spaces, not mandatory puzzles**.

## Editing scene objects

Open `scenes/rooms/moonthorn_woods.tscn` or `scenes/rooms/weeping_brook.tscn`. Every gameplay part can be selected individually:

- `PaintedRoom`: new art for the entire 3072×1728 area.
- `ForegroundFoliage`: transparent moonlit vines/petals that render above the character.
- `Collisions`: `StaticBody2D` nodes with editable rectangle shapes. Their layers are 2 for solid architecture and 8 for hook-crossable water gaps.
- `SpawnPoints`: edit arrival positions from the Arbor, Woods, Bridge, etc.
- `Gameplay/Portals`: destination is an exported inspector property. Names are significant to the room manager.
- `Gameplay/HookAnchors`: optional rose anchors; ordinary solid architecture remains hookable by default unless tagged `hook_blocker`.
- `Gameplay/Carryables`: loose physical stones with standard carry/throw/hook behavior.
- `Gameplay/FutureSecrets`: empty `Marker2D` nodes intentionally reserved for future equipment/rare discoveries.
- `Gameplay/WaterBodies`: separate fish-ready `GhostWaterBody` areas, but **fishing is NOT implemented**.
- `Gameplay/Effects`: independent outdoor motes and ambient object animations.

## Water system for a later fishing milestone

The `GhostWaterBody` script (`scripts/water_body.gd`) exposes:

- `water_kind`: stream / river / pond / lake / marsh
- `fishing_enabled`: per-body toggle, default true
- `future_loot_profile`: data key for a future catch table
- `WaterPolygon`: an editable collision polygon; it can cover **any continuous patch of water**. It isn't a manually selected fishing spot.
- `can_cast_to(world_point)`: returns true for a point inside a fishable polygon.

To add another fishable pond later, duplicate a `Gameplay/WaterBodies/UpperRiver` node, drag the `WaterPolygon` corners around the pond, and choose the water type and loot profile in the Inspector. The later fishing rod can query all registered water bodies and valid shoreline casts.

Water is not automatically a walkable floor. There are separate `StaticBody2D` traversal obstacles on collision layer 8; customize these in the editor. Water solids are in `hook_blocker` so hooks don't latch onto invisible water geometry. Their gap layer lets the Rose Hook bypass them while reeling the player to a solid object or anchor.

## Rose Hook test

`F` = pull Ghost Girl to architecture/rose anchor, `Q` = pull loose physics object. In Weeping Brook, stand on the west bank close to the upper river (around x=1330,y=550) and aim toward the far-bank anchor at x=1710,y=550: the ~380px cast is inside the 450px base range. A regular walking route crosses the stone bridge near y=840, avoiding the upper and lower water colliders. Check **Debug > Visible Collision Shapes** during F5 playtesting.

## Art quality notes

**Moonthorn Woods:** new original generated gothic-forest environment painting. **Weeping Brook:** a new, separately composed riverbank/bridge map using painted texture details, with more schematic walkable terrain. It is not a recolor or mirror of an older room; nevertheless, its map art is a **prototype** and deserves a dedicated painterly polish pass before shipping. Foreground vine/petal overlays were separately composed for each new scene. Earlier rooms remain unchanged.

## Status

Static asset/scene reference validation and approximate path reachability passed; the executable Godot engine was not available here. Test live interactions, line-of-sight and fine collision matching in Godot before using this as a stable release. Character sprites, equipment, seeded item generator and saved inventory were not rewritten by this update.
