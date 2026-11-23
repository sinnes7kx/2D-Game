# Ghost Girl v1.1 — The Rose's Rhythm

**Base:** The user's uploaded `GhostGirl_v1.0(1).zip` (with the v0.9 Painted Foes work). The distributed v1.1 update is an overlay patch for that exact ZIP: extract the original project first, then copy the changed files over it. The Godot project name and save path are deliberately unchanged.

## Implemented

1. **Distinct, directional combat states.** `Ghost` has 16 additional editor-editable SpriteFrames tracks: `attack_light`, `attack_heavy`, `dodge`, and `hurt`, each with front/back/left/right variants. They reuse the *same approved Ghost Girl source pixels* (existing `idle_*` and `front/back/left/right_*` textures); no replacement character style, flip, recoloring or AI-redrawn body images. These are transitional choreography tracks, not newly drawn sword/sickle poses.
2. **Animation timing follows gameplay timing.** Light and heavy frame playback is synchronized to their stamina/attack-speed dependent attack durations. Backsteps no longer get overwritten by walk frames every physics tick. Hit reactions briefly play their own state, with a muted rose flash. Rose-hook, casting, throw and standard movement states are preserved.
3. **Melee arc follows the actual hit window** more closely rather than flashing too early in the telegraph. Existing reach, damage, backstep counter and hit detection are unchanged.
4. **Backpack SORT is actually accessible again.** The existing deterministic size-prioritized packing function had no button and a commented-out handler; the visible button now invokes it. It does not reindex items, equipment, socketed gems or seeded affixes.
5. **F6 action reference:** `scenes/development/combat_animation_preview.tscn` shows light/heavy/backstep/hurt in all four facing directions; `scenes/development/character_animation_preview.tscn` remains available for walk and idle review.

## Controls (unchanged)

WASD: move | Shift: sprint | LMB: quick attack | RMB: heavy attack | Space: backstep | L: target lock | Q: hook an object | F: grapple an anchor | E: interact | Tab: backpack | C: equipment | V: heal | X: quick wand cast. The backpack header includes a new `SORT` button.

## Playtest checklist

1. Open `project.godot` with Godot 4 and let it reimport all images (the `.godot` cache is intentionally omitted).
2. Press F6 on `scenes/development/combat_animation_preview.tscn` to inspect all 16 tracks. Replace any reused frames with future bespoke combat art inside the SpriteFrames editor without code changes.
3. F5: equip/unequip a wand, walk in every direction, swing LMB/RMB, dodge Space with a locked enemy, grapple and cast. Check no old throwing or walking frame overrides occur while attacking/dodging.
4. Tab > SORT: inspect, equip, move, sort; verify equipment references don't change. Save, exit, reopen, and verify the same items, gems, palettes and equipment.
5. Attack the Blade Hunter and Occultist to check combat timing, hit reactions, enemy recovery, and spell warnings. Confirm entrances, portals and doors still work.

## Limits

These new tracks use **existing source illustrations**. They improve state correctness and timing but cannot substitute for bespoke hand-painted frame-by-frame slash, heavy-attack, stagger and backward-dodge art aligned to the approved Ghost Girl model. No other rooms, map graphics, dialogue or enemy art were changed. The project source and overlay patch were checked with offline static validation; **a live Godot F5/F6 run still needs verification** where a Godot binary is available.
