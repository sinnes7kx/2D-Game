# Ghost Girl v2.78 — Lanternlight & Living Mist

This is a presentation-only update layered over v2.77. Room paintings, collision, saves, enemies, loot and the approved character sprite assets are unchanged.

## Controls
- Shift+F5: World atmosphere — Off / Subtle / Cinematic (default). Saved separately from the character save.
- Shift+F6: Existing color grade — Off / Soft / Gothic / Deep Gothic.
- Shift+F3: Existing performance profile — High / Balanced / Low. The new light pool is bounded to 8 / 6 / 3 lights respectively; Low omits the foreground mist. Existing scene-authored lights are not included in that added-light budget.

## Visual changes
- Existing hearth, lantern and shrine positions emit actual 2D light, with softly changing intensity and localized emissive halos. Existing flame lights are expanded instead of duplicated.
- Two translucent world-coordinate fog layers sit above the floor and over the actors, below the HUD. Wet woods/moor are mistier; warm town/vault rooms are subtler; gardens and the observatory have their own tints.
- Grounded soft contact shadows replace the player's hard ellipse, expanding and fading in the jump arc. Moor lanterns and rest shrines have feathered floor shadows.
- No new physics light occluders, shadow casting, room redraws or extra render-target blur pass. The existing screen-space grade remains independent.

## Manual verification (Godot)
1. Open Lanternhaven, walk past a lantern and the hearth; check that the floor and Ghost Girl receive warm light as she approaches.
2. Enter Moonwake Crypt and Hollow Veil Moor; confirm the mist is world-anchored, the moor is mistier, and the painted foreground remains readable.
3. Jump; confirm the soft shadow remains on the ground, broadens and fades.
4. Cycle Shift+F5 through each preset, Shift+F3 through performance profiles, and Shift+F6 through color grades; check inventory and HUD readability.
5. Re-enter several rooms; no duplicate atmosphere node should remain in the scene tree.
6. Restart and confirm the atmosphere preset survives. Off restores previous light and shadow presentation, independently of the v2.77 grade.

Headless smoke: `godot --headless --path GhostGirl2 --script res://tests/v278_atmosphere_smoke.gd`.

This source update has not been run with a Godot executable. Shader rendering, lighting strength, visual quality and frame rate need live confirmation.
