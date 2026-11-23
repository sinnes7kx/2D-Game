# Ghost Girl v1.42 — Fletcher's Quiet Light

Incremental patch for v1.41.

## Artwork/FX refinements
- Generated per-frame grip-to-tip glow guides from the four existing bow-only alpha masks (32 directional animation tracks × eight frames = 256 guides).
- Subtle bow prestige effects now follow the actual painted bow during idle, walking, nocking, draw, hold and release. **No re-rendering or recoloring of Ghost Girl herself.**
- Removed the circular charged-shot meter floating over the character and replaced it with a thin, unobtrusive line beneath her feet.
- No changes to item stats, drop rates, particle damage, projectile counts, or saved seed values.

## Practical bow controls
- Right-click draws, holds until release, then fires.
- While holding right-click, press **C** to jump with the bow already charged; release while airborne to fire a charged aerial shot.
- Existing jump first, then draw/shoot behavior remains available.

## Moonwake Crypt target range
Two small practice vanes near the starting gallery: one accepts any physical arrow; the second accepts only a fully drawn airborne shot. They report arrow element and formation in the HUD and are reusable indefinitely. No save format changes or special items are granted.

## Validation limits
Static/source checks, image-mask guide checks and patch-install checks are included. Godot F5 runtime tests have not been completed; exact target placement and feel still need verification in the editor.
