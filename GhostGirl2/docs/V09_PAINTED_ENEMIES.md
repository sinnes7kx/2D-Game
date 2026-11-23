# GhostGirl v0.9 — Painted Foes (first animated enemy pass)

This is a focused enemy-art update on top of the v0.8 master project. The approved Ghost Girl art, rose hook, inventory, equipment, saves and existing areas are unchanged.

## What's included

- **Blade Hunter** — 16 original transparent hand-painted frames, 160 × 144 pixels per frame: `idle`, `walk`, `windup`, `attack`, `hit`, `recover` and `death` animation tracks. Artist source is at `assets/enemies/blade_hunter/animation_atlas.png`.
- **Occultist** — 16 transparent frames at 160 × 144 pixels, extracted and cleaned from generated concept action poses. This is an **early lower-resolution visual pass** for a ranged enemy, not final production art; see `assets/enemies/occultist/animation_atlas.png`.
- SpriteFrames resources at `assets/enemies/{blade_hunter,occultist}/animations.tres`, both Godot-editable.
- Existing enemies using the archetypes `blade_hunter` or `occultist` now automatically use the new AnimatedSprite2D child in `scenes/gothic_hunter.tscn`.
- The three other archetypes (mourner, warder, bell_keeper) retain their current illustrated placeholders for now.
- `scenes/development/enemy_animation_gallery.tscn` lets you open or press **F6** in the Godot editor to preview each animation without fighting enemies.

## How the AI drives animations

`gothic_hunter.gd` selects tracks from combat state:

- Patrol/rest → `idle`
- Pursue/moving → `walk`
- Telegraph → `windup`
- Blade Hunter lunge / Occultist projectile release → `attack`
- Poise break or rose-hook yank → `hit`
- Punishable recovery → `recover`
- HP depleted → `death` (body remains briefly, then fades; loot still drops immediately).

Sprite positions are aligned to the floor near the enemy's CollisionShape2D. Existing attack arcs and projectile warnings remain visible. The enemy combat timings and item generation were not changed.

## Verify in Godot

1. Back up your v0.8 `GhostGirl` folder before applying the patch.
2. Open `project.godot` in Godot 4. Let textures finish importing.
3. Open `scenes/development/enemy_animation_gallery.tscn`, press **F6** and watch the two enemy rows.
4. Open `scenes/rooms/ashen_causeway.tscn`, then run the main game with **F5**, teleport with F11, and find the Blade Hunter and Occultist. Validate their warnings, walking, attacks, staggering and death.
5. The editable enemy nodes are in each room's `Gameplay/Enemies` branch. Click an instance to change its archetype or stats in the Inspector.
6. If a scene has a script/import error, send the **first red Godot error with filename and line**. Static validation alone does not prove engine compatibility.

## Current limitations

- The new enemy sprite animation art currently uses one three-quarter perspective with horizontal mirroring. True front/back/side directional sets still need dedicated animation passes.
- Occultist art is provisional and noticeably softer than Blade Hunter.
- Not all original enemy archetypes have sprite art yet.
- Live Godot 4 engine testing was not available in the build environment. Scene/resources and ZIP integrity were checked statically; **F5/F6 verification is still required**.
