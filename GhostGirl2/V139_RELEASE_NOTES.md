# Ghost Girl v1.39 — The Living Bow

Incremental patch for **v1.38 Elemental Fletching**.

## Bow draw

- **Right mouse button (heavy attack):** press to nock, draw and hold; release to shoot. The attack is no longer fired by a fixed frame timer.
- Full draw takes approximately **0.46 seconds**. Early release fires a normal arrow, while full draw fires a charged arrow (including charged-only puzzle logic).
- The animation pauses on the full-draw pose until the button is released.
- **Left mouse button:** quick ordinary arrow, with short release and recovery.
- **C + RMB:** jump and draw; release while airborne for an airborne charged shot (if fully drawn). Movement during airborne drawing continues until landing.
- New four-direction combat atlases have explicit ready, nock, pull, hold, release and recovery stages, without the old inherited melee crescent. Ghost Girl's original character images were not overwritten.

## Script-generated palettes

- A new deterministic seeded style grammar chooses continuous HSV colors, accent hues, gradient angles, gradient speeds, pulse rates, sparkle geometry, density, sizes, orbital motion and ribbons.
- Transparent bow-only atlas masks let the runtime shader recolor bows independently of Ghost Girl's face/hair/dress, across idle/walk/attack.
- Equipped prestige visuals and physical arrows use the same procedural palette seed; generated color is stable across saves.
- Existing weapon item stats, quality, sockets and item seeds are untouched; the new values are derived from seeds rather than requiring a save migration.
- Rare prestige visuals are still gated by existing quality rules; cosmetic extra arrows remain single-hit.

## Environmental arrow elements

- **Emberfire:** lights dry thornwood, which can ignite nearby destructible props and chained kindling after a short delay. A cache becomes visible when the second piece burns.
- **Frostglass:** temporarily freezes two unstable crossings in Hollow Veil Moor, opening firm footing for about 8–9 seconds. Moonfall can also freeze them.
- **Luminous:** reveals a previously hidden cache when the actual arrow passes the secret sigil.
- Three new waystone hints point toward the interactions. The effects occur at a small number of placed nodes; this is the first reusable world-prop system rather than blanket interaction with all painted scenery.

## Notes

This source-integrated patch was checked structurally, including animation atlases, scene resources, seed handling and patch installation. **It was not playtested in the Godot runtime**, and the bow art remains a carefully realigned composite pass rather than new hand-redrawn arms and fingers.

Install by extracting into the **v1.38 game directory containing `project.godot`**, overwriting the matching files. Keep a backup of your current project and save data.
