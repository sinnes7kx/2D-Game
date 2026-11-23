# Ghost Girl v1.35 — The Falling World
**Patch base:** v1.34 (The Last Vigil). **No save reset.**

## Core mechanics
Twelve editor-placed, uniquely identified environmental supports appear in Hollow Veil Moor. Supports have small solid collision targets so the rose-hook can actually latch. They can be destroyed permanently; collapsed state is saved under the existing `collected_pickups` dictionary.

The different ways to collapse a support are:

- **F — Rose hook:** aim at its glowing joint and pull. Especially useful if an enemy is perched above or below the fall zone.
- **C + charged bow shot:** airborne charged arrows can strike the suspended bell supports. This uses the same physical arrow; no extra damaging projectile.
- **T — Grasping Roses:** vine-lashed supports react when the spell reaches them without a wall in between.
- **Z — Moonfall Blizzard:** ancient brittle structures can collapse under frost.
- **Z, then F — Frost-then-hook:** certain heavy masonry is too strong for a hook alone. Freeze its cracked joint, then pull.
- **Throw a crate:** a sufficiently fast thrown carryable can break many weakened supports on impact. Frost-bound supports still need the freezing step.

A support can be triggered only once. A source-side enemy standing on it gets knocked off and takes one impact. The fall site has a clearly marked **0.76-second warning circle** before one damage event. After impact, rubble stays as temporary solid cover for roughly 11 seconds; it is not an endlessly damaging area. The player can evade the landing impact by jumping. Debris has a quiet, original creak/impact audio signature.

## Rewards / exploration

- **Western Salvage:** trigger the Widow Beam with F, the Mourning Bell with a charged airborne arrow, and the thorn brace with T. The seal opens to the *Widow's Knot*, a unique hook-enhancing charm.
- **Eastern Salvage:** collapse the Frostwept Shelf with Z, topple the rotten watch-rig with F, and first freeze then hook the Cold Joint. The seal opens to *Rafterfall Moonbow*, a unique bow carrying a throw-force modifier.

The six other environmental hazards offer flexible, optional combat tools. Four waystones and four inscriptions hint at these mechanics without obstructing the main moor route. Twenty-four new low-HP enemies (including eight perched enemies) offer opportunities to test creative environmental attacks.

## Editor guide

Open `scenes/rooms/hollow_veil_moor.tscn` and expand `Gameplay/V135FallingWorld`. Each hazard is an ordinary editable Node2D with a collision child named `HookBody`. The important Inspector exports are `activation`, `material_kind`, `landing_offset`, `collapse_radius`, `damage`, `perch_radius`, and `perched_enemy_path`. The reward seals are children of the same container and expose their `required_sites` and `gate_path`.

To adjust where debris lands, move the support node or edit `landing_offset`; do not move the child hitbox independently. Keep falling circles clear of mandatory portals and main route bottlenecks. Existing scenery paintings and the player's art are unchanged.

## Validation and caveats

- Run `python tests/validate_v135.py` for scene/resource/save wiring checks.
- Godot 4.x is still needed to do an F5 playtest. This patch **has not been engine-runtime tested** here.
- Specifically check the physical crate impact, hook selection near enemies, frost line-of-sight, falling rubble collision, and save/load after clearing each salvage seal.
- An earlier v1.33/v1.34 validator checksums `moonfall_blizzard.gd` and now fails by design because this patch intentionally extends Moonfall. The v1.35 validator checks the new callback explicitly.
