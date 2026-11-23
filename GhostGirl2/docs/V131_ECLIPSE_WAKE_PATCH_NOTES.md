# Ghost Girl v1.31 — Eclipse Wake

Small additive patch for **v1.30**. Extract into the Godot project root containing `project.godot` and overwrite matching files. Make a backup first.

## Changes

- On death, Hush Moths dissolve into lace-like wings, Gloom Lanterns break into stained-glass fragments, rose wraiths dissipate into spectral motes, and regular/elite hunters get their own short-lived shard effects. These cosmetic bursts do not create hitboxes, modify drops or change damage.
- Very rare prestige-rolled floor weapons/wands and set/unique gear now display six different moving *ground heraldry* styles. Ordinary/magic gear remains restrained. Existing item seeds, qualities, stats and save-format logic are unchanged.
- Two **Moonshot Bloom** discoveries are placed in Hollow Veil Moor. Use a charged shot while jumping (C + right-click) on the floating disc, then cast Grasping Roses (T) nearby. Both steps persist independently; the reward chest unlocks only on completion.
- Willow Moonbloom rewards a rare Thornrose Bow; Drowned Moonbloom rewards a rare Briar Wand. Both fixed reward seeds qualify for the existing deterministic rare-prestige appearance chance; no overall rarity or drop rates change.

## Validation

v1.24–v1.31 static checks passed. Scene resource references and `load_steps`, two distinct puzzle save IDs, and patch paths were checked. No Godot executable is installed in this build environment; **not runtime/F5 playtested**.

## In-game quick test

- Travel to Hollow Veil Moor (F6 development shortcut).
- Follow the **Willow Moonbloom** waystone near `(2240, 1640)` to the disc at `(2480, 1370)`.
- Equip a bow. **Jump with C and fire a charged shot with right-click**, then equip a wand and cast **Grasping Roses with T** next to the awakened disc.
- Check the now-interactable treasure cache. Leave/re-enter the moor and verify both completed stages persist.
- Fight Hush Moths and Gloom Lanterns to inspect the death animation bursts. Find an exceptional ground equipment drop to inspect a heraldry effect.
