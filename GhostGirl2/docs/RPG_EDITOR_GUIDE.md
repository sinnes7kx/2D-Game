# RPG editor notes — Act I Briar Hollow draft

## Level scene trees

Open `scenes/rooms/briar_hollow.tscn` and `reliquary_path.tscn` in the Godot editor. Both contain the `PaintedRoom` Sprite2D, individual `StaticBody2D` colliders, `SpawnPoints` markers, and the following editable groups under `Gameplay`:

- `Portals`: destinations and arrival routes.
- `TreasureChests`: set `chest_id`, `loot_data`, `loot_seed` and `guaranteed_quality` in Inspector. **Never reuse a chest ID**, because collected IDs are persisted.
- `Enemies`: assign a `GhostItemData` drop template, starting health, chase speed and quality tier. Spawned wraiths are temporary art placeholders.
- `Collectibles`, `Carryables`, `Plates`, `PuzzlePieces`: compatible with earlier Act I exploration.
- `HookAnchors` and `FutureSecrets`: world traversal and later secret-route planning.
- `WaterBodies`: a physical polygon designated as a fishable future water zone, but fishing behavior remains unimplemented.
- `Effects`: fireflies, petals and moon dust.

Edit a collision shape through `Collisions/<named body>/CollisionShape2D`. Use Debug → Visible Collision Shapes during play, and move markers or portal nodes inside the editor to repair pathing. Painting/art assets were not automatically turned into exact collision geometry.

## Item definition pipeline

1. Duplicate `items/briar_wand.tres` or another template and edit `item_id` (unique among templates), `display_name`, `equip_slot`, `max_sockets` and base stat range.
2. Place a `scenes/treasure_chest.tscn` node in a room; set `loot_data` to your resource, `loot_seed` to an integer, and optionally force a quality tier.
3. Modify affix options inside `scripts/item_generator.gd` only when adding a new stat type. Every affix and socket bonus contributes to `get_stat_total()`.
4. Add new stat effects in the relevant gameplay system (`player.gd`, `rose_hook.gd`, `game.gd`) before advertising those stats to players.
5. Gem/rune templates expose `item_class`, `socket_bonus_id`, and `socket_bonus_value`. Currently socketing consumes one component permanently.

## Character animation

Select `scenes/player.tscn` → `Ghost` → `SpriteFrames`, or open `resources/ghost_girl_frames.tres` directly. New wand hold, walk and cast animations are named for front/back/left/right. The original uploaded sheets remain preserved in `assets/ghost/source_*.png`. All new cut sprites are RGBA 158 × 202 with a consistent bottom-foot baseline.

## Equipment and inventory windows

Edit `scenes/inventory_panel.tscn` for the 24-button, six-column backpack grid and socket action; `scenes/equipment_panel.tscn` for five slots; `scenes/hud.tscn` for the compact HUD and damage-only health bar. The root `Inventory` Node of `main.tscn` persists through room transitions.

## Save-data warning

The new v2 save file is stored under Godot's `user://` path. The first launch can migrate from the v1 equipment file; previous items without quality data are preserved as Normal. After testing, do not delete your previous save until you verify migrated items and equipped slots.
