# Ghost Girl v1.46 — The Ashglass Watch

**Incremental Godot 4 patch over v1.45 The Listening Moor.**

## New world reactions

- Four existing kinds of burning world objects (dry kindling, thornwood, breakable cover, and timber Moonroot lattices) now temporarily register as active fire hazards.
- Nearby Hush Moths, Gloom Lanterns, hunters, and rose-wraiths receive a short warning when something catches fire.
- Moving enemies steer away from active flames while chasing or investigating; they still respect committed attack telegraphs, lunges, and stagger states. Fire avoidance adds **no new damage ticks** and doesn't spawn additional enemies.
- Fire events expire when a source burns out or breaks. Actual collapses retain the separate v1.45 investigation and Aftershock Memory behavior.
- Both Hollow Veil Moor and the new Blackbrick Court encounters can report world changes. Other rooms benefit from active-flame steering without requiring new scripts in those scenes.

## New location: Blackbrick Court — Ashglass Watch

Two optional, editable environmental devices have been added in **Blackbrick Court**:

1. **Watchroot Ember Signal** (southeastern court): pull it directly with the **F rose-hook**, hit it with an **Emberfire arrow**, or ignite the **existing dry roots** nearby and let the fire spread. The old root chain now has another purpose.
2. **Pale Bell Ashglass** (northwestern court): strike with a **Frostglass arrow**, or prepare it with **Moonfall (Z)** and finish by hooking the glass.

Each device opens its own small solid lattice/shutter, reveals one rare-quality treasure cache, and uses unique persistent save flags. This is optional content; neither shutter blocks the main route. Nearby readable inscriptions hint at both solutions.

The new devices are original code-drawn, slender antique props, with no large circular magical effects or new textures required.

## Saves and combat

- Additive discovery flags only; no existing saves, item statistics, loot rates, animation atlases or approved character artwork are replaced.
- Previously established v1.45 collapses, chainfall sites, Bellroot puzzles and Moonroot causeways are unchanged.
- Fire awareness is steering/AI only. Existing damage and loot behavior remains unchanged.

## Test in Godot

1. Back up the project and saves. Apply the ZIP to **v1.45**, merging into the root that contains `project.godot`.
2. Open **Blackbrick Court**. Find the two inscriptions and use their environmental hints to release the Ashglass shutters.
3. Use a fire bow near the existing dry roots and watch nearby enemies react while the flame spreads. Try pulling the ember signal directly instead.
4. Cast frost on the second signal, pull it with the rose-hook, and open the newly revealed rare cache.
5. Save/reload, re-enter the court, and confirm the two shutters remain open while already-opened chests stay opened. Visit the moor and verify older Aftershock discoveries still work.

## Validation / limitations

- Dedicated `tests/validate_v146.py`: new scripts, world events, fire duration bookkeeping, scene parent/resource links, save flags and two new rewards.
- Regressions: existing v1.32, v1.38, and v1.40–v1.45 targeted static validators.
- Clean incremental patch application and SHA-256 verification.
- **Not an engine-certified release.** Godot/F5 was unavailable in this environment, so actual runtime physics, steering quality, and trigger timing require a playtest.

This patch does **not** include missing older files: if the game reports missing dependencies, install the earlier cumulative repair or restore the correct base project first.
