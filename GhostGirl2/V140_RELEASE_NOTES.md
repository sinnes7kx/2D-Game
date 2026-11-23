# Ghost Girl v1.40 — The Elemental Wilds

**Apply after v1.39.** This is an incremental source patch, not a complete project.

## Changes

- **Fire:** Fire arrows ignite dry moonroots. After a short delay, flame spreads to nearby flammable roots, older v1.39 burnables, and breakable wooden barricades. Each object ignites only once per chain to avoid runaway recursion or repeated enemy damage. Burned moonroots retain their state in saved discovery flags; temporary barricades are regenerated on room revisit as before.
- **Ice:** Frostglass arrows now intersect the **actual editor-authored WaterPolygon** of any `GhostWaterBody`. Their physical arrow path creates a temporary ice strip, up to about 300 px long, for 10 seconds. That strip restores normal movement speed over shallow water; the pre-existing water is already traversable at reduced speed, so this does not yet turn an impassable chasm into a walkable bridge. Moonfall's old circular ice patches still work, including if an arrow-made strip is present.
- **Light:** Luminous arrows reveal special hidden moonmarks when their single physical arrow passes within reveal radius. This does not create additional hitboxes or multiply damage. Previously shipped v1.39 secrets also respond to nearby light now. Once revealed, each new moonmark unlocks an ordinary save-compatible reward chest.
- **World content:** 12 dry-root objects and 4 hidden moonmarks in Hollow Veil Moor, 4 dry-root objects and 1 moonmark in Moonthorn Woods, and 3 dry-root objects and 1 moonmark in Blackbrick Court. Total: **19 burnable props, 6 new hidden caches**, plus existing v1.39 devices and wooden cover.
- **Bug fix:** Two leftover `#` comments in `blackbrick_court.tscn` were changed to Godot `.tscn` `;` comments to avoid a resource parse error.

## How to try

1. Equip a bow whose saved arrow element is **Emberfire**, **Frostglass**, or **Luminous**. The sample bows from Moonwake Crypt (v1.38) remain available.
2. Fire an Emberfire arrow into the small code-drawn dry branches; nearby branches and destructible barricades can catch.
3. Shoot a Frostglass arrow **at the edge of an actual pond**; a temporary icy crossing forms in the direction of the shot and removes the normal water movement penalty until it melts.
4. Search wooded paths and the moor's darker banks with a Luminous arrow. A moonmark can reveal a hidden treasure chest without requiring a direct hit on an exact rune target.

## Technical notes

- Editor-editable placements live under `Gameplay/V140ElementalWorld` in the three changed rooms.
- Existing `Game._bind_room()` now restores v1.40 discoveries after chest states, using the existing inventory save file.
- No new damage projectiles, changes to drop odds, item-stat rerolls, or original character-art changes.
- Run `python tests/validate_v140.py` for offline resource/scene checks.
- **No Godot executable is available in the build environment:** live F5 gameplay, water-strip alignment, and gameplay feel remain unverified.
