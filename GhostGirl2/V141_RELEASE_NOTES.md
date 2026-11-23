# Ghost Girl v1.41 — Quiet Relic Light

**Applies over v1.40 (the cumulative dependency repair is recommended if earlier patch files were skipped).**

This patch is a visual/control refinement, not a combat-balance update.

- Removes oversized rings, orbiting constellations, and floating circular halos from equipped weapons.
- Rare/set/unique prestige gear now uses a **subtle elongated grip-to-tip glimmer**, a slow color transition, and one or two tiny traveling highlights. No additional physics, damage, or projectiles.
- Scythe/halberd glows use their frame-authored tip positions. Swords, bows, and wands use directional weapon spans; exact sprite silhouettes may still require hand adjustment in the Godot editor.
- Disables the redundant large tip-centered weapon-layer FX.
- Wand idle glimmer is now a thin shaft-aligned glow, gated behind the same existing rare prestige-roll rules, instead of a full halo.
- Controls: **C = jump**, **I or Tab = inventory/equipment**, **B = healing dew**, **V = Astral Rain**. The duplicate V mapping was a pre-existing conflict.
- Control guide updated accordingly.
- Original item seeds, equipment, saves, animation images, and gameplay balance untouched.

Files: `scripts/weapon_prestige_fx.gd`, `scripts/weapon_animation_layers.gd`, `scripts/wand_idle_glimmer.gd`, `scripts/hud.gd`, `project.godot`, `scenes/hud.tscn`, and `tests/validate_v141.py`.

Static source tests only; Godot F5 testing is still required. Check all four directions with an equipped sword, scythe, halberd, and wand, and try swapping equipped items during a cast.
