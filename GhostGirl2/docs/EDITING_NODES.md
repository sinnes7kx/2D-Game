# Editing Act I in Godot

## Room nodes (no scripting required to adjust existing props)
1. Open `scenes/rooms/garden.tscn` and expand **Gameplay**.
2. Expand **Carryables** to move the crate; expand **Plates** to move the seal; expand **Portals** to move the gate. Existing scripts reference these nodes by their names.
3. Each room has **SpawnPoints** > `Default` / `From_<room>` Marker2D entries; move markers to change arrival positions.
4. Select an existing `PuzzlePieces` Node2D to edit its exported `kind`, `orientation`, `tint`, and `interaction_name` in Inspector. For bells and flowers, preserve original names if you don't also update the scene orchestrator.
5. Select `VisualClues` nodes to move or change their engraved-symbol type. They are intentionally non-interactive and do not trigger dialogue.
6. Select **StaticBody2D → CollisionShape2D** to move / resize obstacles. Turn on **Debug → Visible Collision Shapes** while playing.

## UI (no large scripted panels)
Open `scenes/hud.tscn`. Under **Overlay** you can edit `LocationLabel`, `ContextHint`, `CarryingHint`, `ExpressionPortrait`, and `ControlsGuide` directly. The portrait is anchored bottom-right and only becomes emotional during specified story events.

## Animation
Open `resources/ghost_girl_frames.tres` or select `scenes/player.tscn → Ghost`. The SpriteFrames resource is already assigned. Animations are named `idle_front`, `walk_front`, `throw_front`, and corresponding left, right and back names. Present throw poses reuse existing frames plus procedural movement; bespoke frames can replace them later.

## Adding a room
Duplicate an existing room `.tscn` as a **starting structure**, but create a unique painted scene for its art. Keep `Gameplay` subgroups and a `SpawnPoints/Default` Marker2D. A new room still needs an entry in the `ROOMS` and `ROOM_TITLES` maps and relevant progression code in `scripts/game.gd`; this is intentionally outside the no-code editing promise.

## Room loop and carried items
Room scenes are instantiated on travel. The game tracks solved puzzles for the session. Items may reset on re-entry; carried and thrown items from the previous room are discarded to prevent accidental cross-room physics and softlocks.

## Testing
Open `scenes/main.tscn` and press F5. The main scene should no longer be an empty root. The initial Garden is instantiated at edit time, and the player sprite and HUD are visible. Verify E, G, R, walking, the seven portals, bell order, flower order, the twin-plate puzzle, and all mirrors. No dialogue or lore panels should appear.
