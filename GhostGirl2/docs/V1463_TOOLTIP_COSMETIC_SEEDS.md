# Ghost Girl v1.46.3 — Cosmetic Seeds, Sword Glints & Ctrl Tooltips

Small incremental source patch for the **uploaded GhostGirl2 v1.46-series project**. This package is **not a full game ZIP**; it overlays the project assembled from `GhostGirl2(1).zip` (scripts/scenes/resources) and `GhostGirl2_part2.rar` (art, other project files). It contains **no original character artwork replacements**.

## Install

1. Back up the project and its Godot user save data (`user://` files). Do not delete your existing project or your saves.
2. Assemble your uploaded `GhostGirl2` project first. The ZIP's `GhostGirl2/` directory contains source scripts and scenes; the RAR contains root-level `assets/`, `project.godot`, etc. They belong together in a single directory containing `project.godot`, `scripts/`, `scenes/`, `resources/`, `assets/`.
3. Extract **this PATCH ZIP directly into that project directory**, allowing it to replace the matching `scripts/` and `scenes/` files. Do not place it in a second nested `GhostGirl2` directory.
4. Open that project in Godot 4 and launch a playable scene. Test on a copy of an existing save before continuing normal play.

## Controls

- Hover over a backpack or equipped item to see **that item** next to the cursor.
- **Hold Ctrl** while hovering an unequipped item to display the equipped item beside it **only when both occupy the same equipment slot**. Release Ctrl to return to the single tooltip without moving the cursor.
- Select an equippable item in the inventory and use **REROLL** in the inspector to generate a new **numbered visual seed** and a changed primary cosmetic color. **SAVE ★** favorites its precise appearance. **SAVED LOOKS** restores any favorite on that same item (up to 16 per item).
- Rerolls save immediately and cannot alter loot seed, item stats, random item affixes, quality, sockets, weapon damage, or existing game progression.

## Visual effect scope

- Swords with the `blade` weapon style gain a restrained attack glint, tinted by their saved cosmetic colors; it follows the existing animation/hand transform, with no new weapon sprite or hitbox. Higher-quality blades receive slightly stronger accents. Existing scythe/halberd weapon-aligned effects remain intact.
- The glow uses the existing short, approximate grip-oriented sword segment. Exact per-pixel blade mask/atlas tracking still requires separate authored directional frame guides; visual review in Godot is advised.
- New visual-seed rerolls also affect existing weapon, wand, and bow cosmetic fields, plus other equipped items' palette/ornament. Altar attunement retains its one-time gameplay restriction and remains cosmetic-only.

## Save and backward compatibility

- Old saves without the new `cosmetic_seed` and `saved_cosmetic_looks` fields keep their original cosmetics (the fallback is the existing item seed). The new `palette_index` and `decoration_index` fields are persisted for the first time to retain fresh rerolls after reloading.
- For items previously altered at an altar, **save the current look before rerolling** if you want to keep its exact previous appearance. Saved favorite snapshots include all item cosmetic channels; reloading a favorite does not regenerate stats.
- The base item/loot seed is still shown separately from the cosmetic look seed in the tooltip.

## Verification / rollback

- `tests/validate_v1463.py` passed static source/scene/save-contract checks against the uploaded source tree.
- Godot engine execution/F5 integration, gameplay, frame alignment, and actual save-load roundtrip were **not** verified in this container (no Godot executable).
- v1.46's older static checker needs a Blackbrick Court PNG held in the separate RAR; it fails against the scripts-only extracted ZIP because that one asset is not physically unpacked, not because the patch removed it. That PNG's membership in the supplied RAR was confirmed.
- Roll back by restoring the overwritten source files from the uploaded ZIP and your backed-up `user://` save data. Do not restore individual files from different versions unless you are checking compatibility deliberately.

This patch intentionally changes only scripts, one existing inventory scene, and documentation/testing; it does not include new sound effects, rewritten animations, or a new game distribution.
