# Ghost Girl v1.16 — Crimson Moor (incremental patch over v1.15)

## Combat visual additions (cosmetic only)
- Confirmed melee hits generate stylized blood droplets, rose-red sprays and fading arcs.
- Successful wand hits and wall/cover impacts generate item-coloured moon rings, crystal sparks, petals, starbursts or prismatic fragments.
- New `weapon_impact_style_index` is an independent saved item roll; older saves derive the missing value from seed + item quality (without rerolling any stats, other palettes, form, affixes or sockets).
- Normal quality exposes 2 styles; magic adds a third; rare/set/unique unlock more lavish effects. Rare `Sanguine Cascade` adds extra blood, and rare `Prismatic Shatter` adds extra wand shards. Neither changes the hit count or damage.
- Godot source implementation: `scripts/impact_prestige_v116.gd`; instantiated only on confirmed enemy/wall contacts.

## New wilderness: Hollow Veil Moor
- Original 4608 x 3072 terrain painting, not a duplicated/mirrored background from another existing room.
- 68 editor-placed creatures across 16 loose packs: 65 regular (12–18 HP) and 3 elite (~85 HP). Ordinary damage about 3. Compared with older levels, this should make casual encounters much easier.
- Three permanent treasure chests, six rose-hook anchors, four movable crates, and solid borders/landmarks.
- Traversal is connected in both directions to Briar Hollow and Moonthorn Woods. Enter the moor from the south-west side of Briar Hollow near x=850, y=1270; or from Moonthorn Woods near x=2550, y=1340.
- For testing while running the game, F6 changes to the Moor (Godot editor F6 is a *different* shortcut; the test hotkey is intended for the focused running game window).
- The first-pass environment is procedural and visually less developed than the approved painterly room backgrounds. It is intended for playable layout and encounter tuning before bespoke landscape art.
- `tools/build_hollow_veil_moor_v116.py` reproducibly builds the image and scene from its explicit fixed seed.

## Installation
Extract into the **project root containing `project.godot`** from v1.15. Preserve directories, replace files with the same names. Do not extract inside another new folder. Back up saves/project first.

## Validation
`python tests/validate_v116.py` passes, as do v1.12–v1.15 targeted suites in this build. The old broad checker still reports the pre-existing two inventory grid signal-name mismatches (`item_selected`, `item_move_requested`). The environment has no Godot executable, so there is **no verified F5 runtime playtest**. Please test combat and portals in the engine.
