# Ghost Girl v1.32 — The Four Laments (major gameplay update)

**Patch base:** v1.31 Eclipse Wake. Extract into the Godot project root (the directory containing `project.godot`), merging directories and overwriting matching files. This is NOT a full project and does NOT modify the original approved Ghost Girl sprite atlases or the moor's painted background.

## New multi-stage exploration quest

- Visit **Hollow Veil Moor**, where the minimal upper-left tracker displays `MOOR VIGIL · 0/4 LAMENTS`.
- Four **editor-placeable memorials** glow in separate parts of the 10,368×6,912 area: Willow (west), Graves (south), Fen (east), and Cathedral (northeast).
- Face a memorial and press **E** to awaken it. Each remains saved if you exit the room.
- After two memorials, a previously sealed **Lament Moonbow** chest unlocks in the southern moor. This is a permanent, guaranteed unique-quality bow.
- After four memorials, visit the **Warden Altar** below the central ruins and press **E**.

## Optional boss — the Moor Warden

- Three visibly telegraphed patterns: a short crescent sweep, a large ground shockwave, and a linear spectral lance.
- **C to jump** over the shockwave, dodge the sweep, and use **Q** to pull/stagger with the rose-hook during a windup.
- At about half health, the Warden summons two very weak Hush Moths. Summons provide no extra loot and disappear on room reload.
- A temporary rainstorm intensifies during the encounter. Defeating the boss restores ordinary rain.
- Defeat is saved once per character, keeping the Warden's two treasure gates permanently unlocked. If you leave the room before the kill, the encounter resets without deleting memorial progress.
- Two signature rewards: **Veilkeeper's Reaper** (unique scythe) and **Censer of the Fourth Bell** (unique wand). They use the game's existing item icon artwork and the existing rarity-gated prestige visuals.

## More challenging optional encounters

- Four elite sentinels near the memorial approaches; each has editable health, attacks, speed and drop template.
- Eleven pre-existing regular monsters are moved to the outside of the Warden arena, rather than removed. This keeps boss combat readable while preserving those enemies.
- Four colored arena lanterns and two additional rest shrines, including one before the boss.
- Five readable waystones explain the route and controls. All main moor entrances, exits, and older side quests remain unchanged.

## New one-time Relic Attunement

- One altar near the **Moonwake Crypt weapon gallery**, and a second one beside the Warden rewards in Hollow Veil Moor.
- **Equip a rare, set or unique bow, blade, scythe, halberd or wand**, face the altar, and press **E**.
- Each altar works **once per save**. Attunement rerolls only its saved cosmetics: primary/accent effect colors, particle motif, trail, impact, wand form and (for weapons) material color, gradient and two surface details.
- It **does not** alter damage, stat values, affixes, sockets, item seed, quality or other save data.
- The Warden shrine requires victory first; the Moonwake shrine is accessible immediately for visual testing.
- Existing unique prestige patterns remain tied to the original item seed, preserving rare visual identity.

## Save & compatibility

Uses existing `Inventory.collected_pickups` flags and serialized item visual indices. No new save-file paths or item serialization schema. Everything is optional; old room progression remains intact.

## Runtime validation limitation

`tests/validate_v132.py` verifies assets, TSCN parent/resource links, all quest IDs, reward gate paths, one-hit boss attacks, item changes and the UI. **No Godot executable is available in the packaging environment**, so this is not an F5-tested build. Test in a backup of your project. If the Godot debugger reports a script/scene parse error, send the exact line number and the screenshot.
