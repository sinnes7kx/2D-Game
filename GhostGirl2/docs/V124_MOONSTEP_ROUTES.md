# Ghost Girl v1.24 — Moonstep Routes

**Base:** v1.23 Relic Showcase & Moonstep. This is an incremental gameplay patch, not a complete game.

## Hollow Veil Moor discoveries

- **Lantern Steps** (west, near 3050 × 5140). Three separate jumps across short thorn barriers unlock a seeded, rare **Gloamglass Locket**.
- **Moonlight Crossing** (east, near 6820 × 3010). Three separate jumps unlock a seeded, rare **Briar Wand**.
- **Mire Leap** (near 8250 × 3550). Jump through the lone seal for a seeded, magic-quality **Lunar Vigil Halberd**.
- The two long routes have readable waystones and gentle connected marker rings. Jump fences are on the jump-only collision layer (32); normal walls keep their collision.
- Six additional fragile wraiths guard the wider approaches, not the landing rings.

## Controls and feel

**C:** jump. Hold a movement direction before jumping; the hop continues in that direction. The moonstep sequence requires a *separate jump* for each ring. A soft spectral landing ring appears after a moving jump; it is cosmetic and has no hitboxes or damage.

## Saves

Rewards use the existing `collected_pickups` dictionary and `user://ghost_girl_treasures_v2.json`. Inventory-full trials can be retried, and completed rewards do not reroll on reload. There are no changes to save fields, approved character art, weapons, weather or the moor painting.

## Validation

`python tests/validate_v124.py` checks scene loading references, enemy count, route wiring, jump conditions, save IDs, and room transition retention. `tests/validate_v123.py` and `tests/validate_v122.py` remain applicable and pass. Older v1.21 validators expect exactly 136 enemies, so their fixed-count assertion is obsolete after the new six additions.

**Godot editor runtime playtesting is still needed.** These tests cannot verify collision and jump-feel in the engine.
