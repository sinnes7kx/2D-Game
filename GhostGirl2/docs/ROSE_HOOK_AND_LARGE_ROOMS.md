# Ghost Girl — Act I: The Moonrose Hook

## What changed

This is a Godot 4 editor-first **2D** Act I expansion with seven **individually painted** gothic environments. Original artwork was authored for each location; no existing room was recolored or mirrored to create another. The 1448 × 1086 paintings are retained under `assets/world/source_paintings/`, while high-quality enlarged `2389 × 1792` copies serve as the actual playable maps. The player and physics props remain their original size, giving rooms roughly **2.7 times the canvas area** of the old 1448 × 1086 prototype. This is level/world enlargement, not an extra zoom applied to the player.

Each room has `PaintedRoom` (art), `ForegroundCanopy` (a transparent, separated foreground portion of its *own* painting), `Gameplay` (doors, puzzles, anchors, objects), `SpawnPoints`, and individually named, artist-adjustable `StaticBody2D` collision shapes. The foreground layer allows flowers and vegetation to appear above Ghost Girl. `MoonlitDust` and per-room moonlight effects are still separate node layers.

The new paintings were generated individually using the gothic-dark-pretty art direction established by the concept sheet; they are not tile-repeat recolors. The source compositions are distinct, though the enlarged versions have been resampled and will benefit from manual painted detailing at native 2389 × 1792 resolution later.

## Rose Hook gameplay

This mechanic adapts the two useful modes of your original `Hook.gd` and `PlayerGrapple.gd` examples, but is newly implemented for the top-down puzzle game.

| Key | Action | Target |
| --- | --- | --- |
| **Q** | Cast the silver-and-rose Moonrose Hook, pull an item toward Ghost Girl | Any nearby unheld **Carryable** RigidBody2D that you point toward |
| **F** | Cast the hook to a moonrose anchor and pull Ghost Girl toward it | A world **HookAnchor** placed by the designer |
| **E** | Pick up / interact | Nearby object in the direction she faces |
| **G** | Drop held object | Ground in front |
| **R** | Throw held object at mouse cursor | Physics arc, landing impact |
| **H** | Show/hide controls | Quiet UI, hidden initially |

Aim with the PC cursor before pressing Q or F. Valid targets are within an approximately 930px range and a narrow aiming cone. World obstacles block the hook ray. Pulling the player uses `move_and_slide()` and respects walls; the hook never teleports her through collision shapes. The release animation completes naturally, then the hook has a short cooldown. Q is useful when an object is across a small gap or far from its seal; F provides a gentle shortcut to authored anchor locations.

**Editor files:**
- `scenes/rose_hook.tscn` — editable `RoseHook` node, `MoonThread` Line2D, `HookTip` AnimatedSprite2D and `ImpactPetals` CPUParticles2D.
- `scripts/rose_hook.gd` — cast → latch → pull → retract state flow, collision-aware target selection.
- `scripts/hook_anchor.gd` — visible, stylized and editor-movable anchor node, stored under `Gameplay/HookAnchors`.
- `resources/rose_hook_frames.tres` — authored SpriteFrames for `cast`, `latch`, `retract` using the rose-hook sprite sheet you loved.
- `resources/ghost_girl_frames.tres` — *32 additional Ghost Girl gesture images* across four directions: `hook_front/back/left/right` (six frames each) and `hook_hold_front/back/left/right` (two frames each). They use the original Ghost Girl base images composited with a small hook to retain her appearance; the body lean and arm reach are animated procedurally during the cast. These are genuine separately editable SpriteFrames, not a static portrait.

## Thrown-object impact

Thrown carryables now produce a briefly animated moon-dust-and-flower burst on a strong wall hit or when their independent fake vertical Z arc first hits the ground. Small CPUParticles2D sparks accompany the 8-frame impact sprite, and a cooldown prevents unlimited repeated bursts.

- `scenes/impact_effect.tscn`, `scripts/impact_effect.gd` — editor-editable one-shot effect.
- `resources/impact_frames.tres` — 8-frame moonlit impact art.
- `scripts/carryable.gd` — RigidBody2D contact handling and ground-impact triggers.

## Environment layout / collision

Every original room painting is still used as its own room, now larger. Portals and puzzle objects have been moved to locations matching the new composition. Static colliders around fountains, trees, pews, water, flower beds and ruined masonry are deliberately **conservative blocking proxies** rather than per-pixel art tracing.

Open any `scenes/rooms/<room>.tscn`, then edit the existing `StaticBody2D/CollisionShape2D` children, `Gameplay/...` positions, `HookAnchors`, and the `SpawnPoints` markers. The current camera follows the player through the larger world and limits itself to the full `2389 × 1792` room.

The observatory's beam now reads five **Marker2D** nodes (`LightPath/Source`, `MirrorWest`, `MirrorNorth`, `MirrorEast`, `Star`) rather than hard-coded coordinates, so you can adjust the light route in the editor.

## Visual philosophy

- Delicate gloomy gothic structures, slate-purple stone, moonlight, warm amber lanterns, roses, lilies, dark water and mist.
- Distinct room paintings. **No recoloring existing rooms as substitutes for new areas.**
- Large clear floors and navigable side paths, so puzzles have breathing room.
- No dialogue. Emotion portrait only for significant moments: the lost memory, the restored glasshouse and the final star.
- Genuine editor-owned nodes, not interactables built solely at runtime.

## Limits of this iteration

The source paintings were resampled to enlarge their walkable world area; they are not new 2389 × 1792 native-resolution paintings. Some collision edges are approximate and should be refined in Godot with visible collision debug. The rose-hook character gestures are composited from your original 2D Ghost Girl frames, not newly hand-drawn anatomical arm poses. There is no save system or 3D character. Godot is not installed in this build environment, so the output was statically checked but could not be verified by an actual F5 run.
