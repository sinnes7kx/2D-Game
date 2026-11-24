# Ghost Girl — Development Roadmap

_Last updated: 2026-11-24 · Godot 4 · living plan, not a release promise_

Ghost Girl is a gothic, painterly 2D action RPG with deliberate combat, distinctive weapon animation, equipment and cosmetic variety, exploration, and a rose-hook that changes the world. This roadmap prioritizes **a playable, reliable build** over adding features that cannot be tested.

## Status key
- **Shipped in source** — present in the repository, but may still require an in-engine playtest.
- **Next** — next build / immediate validation priority.
- **Planned** — approved direction; not necessarily implemented.
- **Later** — longer-term direction, after stability and core play feel.

## 0. Stabilize the next playable build — Next (P0)
- [ ] Verify **inventory TestMythic** on an actual Godot launch: older scenes may have a `Button` where the script expects an `OptionButton`. The active `scripts/inventory_panel.gd` now uses `_ensure_effect_dropdown()`, and `scenes/inventory_panel.tscn` declares the proper node type (**shipped in source**). Do not reintroduce the older typed `@onready` assignment.
- [ ] Run `tests/v1921_dropdown_compat_smoke.gd` for current, legacy-Button, and missing-dropdown scenes (**test already present**); verify selecting an effect and resetting it in a debug build. Keep the tester hidden in release exports.
- [ ] Resolve or remove the duplicate `scripts - Copy/inventory_panel.gd` containing unresolved Git merge markers. Do not use it as the live script. Audit the repository for other merge markers.
- [ ] Run the GitHub Actions Godot headless workflow, then perform a manual F5 playtest: game start, inventory open/close, item inspect, equip, socket, drop, destroy, seed controls, scene transitions, combat, and save/reload. A green static or headless check is **not** a substitute for the playable test.
- [ ] Fix remaining parser/runtime errors before any feature-heavy release; triage warnings separately. Attach exact error lines and reproduction steps to any blocker.

**Exit gate:** fresh checkout imports and boots; inventory opens without the `Button` → `OptionButton` error; smoke tests and hands-on flow pass; existing saves still load.

## 1. Animation, presentation, and combat feel — Planned (P1)
- [ ] Keep Ghost Girl's approved face, proportions, silhouette, and gothic painted presentation intact.
- [ ] Confirm directional idle, walk, dodge, attack, bow, wand, scythe, dagger, spear, halberd, and dual-weapon animation transitions in Godot; eliminate wrong-direction attack locking and detached/incorrect weapon layers.
- [ ] Polish deliberate, Bloodborne-inspired attacks, enemy tells, stamina, hitstop, and dodge counters. Play the riposte ring/chime/hitstop only on confirmed counter-hits.
- [ ] Add subtle **blade-following sword glow**, using soft tapered light rather than rectangular beams; cosmetic effects must never add unintended damage.
- [ ] Keep regular enemies numerous but weaker than elites; maintain low loot frequency and rare/unique scarcity.

## 2. Cosmetics, inventory, and item identity — Planned (P1)
- [ ] Provide numbered, reproducible **cosmetic seeds** with save/favorite and restore controls, independent from gameplay-stat rerolls.
- [ ] Allow cosmetic-only rerolls without altering item identity, damage, affixes, or saved equipment.
- [ ] Keep tooltip swatches compact: don't clutter the normal tooltip with seed IDs, motif names, or palette labels; reserve advanced details for an opt-in view.
- [ ] Extend deterministic item-specific color/motif variation to weapons and wands; preserve single-hit spell damage when effects visually show multiple wisps, beams, or projectiles.
- [ ] Regression-test backpack page/slot migration, item persistence, old save loading, and all equipment interactions before changing inventory serialization.

## 3. Rose-hook puzzles and exploration — Planned (P1–P2)
- [ ] Add an **early-room support-beam puzzle**: hook the beam, trigger falling debris, and reveal a persistent floor opening. Ensure collision, visuals, navigation, and saved puzzle state agree.
- [ ] Expand hook interactions with anchors, environmental switches, pullable objects, movable obstacles, enemy staggers, traversal, and secrets.
- [ ] Build larger, genuinely walkable spaces with **original room-specific artwork**. Never treat a mirrored or recolored old background as a new location.
- [ ] Add environmental storytelling, hidden paths, landmarks, meaningful rewards, and restrained on-screen UI without requiring dialogue.

## 4. Equipment depth and replayability — Later (P2)
- [ ] Expand modular equipment silhouettes and accessories (including trinkets and wings) with independent appearance palettes, decorative effects, and randomized stats.
- [ ] Maintain distinct weapon families, readable reach/timings, and authored directional artwork; avoid visually duplicating weapon families with icon-only replacements.
- [ ] Refine unique encounters, elites, bosses, optional challenges, rewards, and exploration loops through playtesting rather than increasing loot quantity.

## 5. Quality, compatibility, and release discipline — Ongoing
- [ ] Build on the **latest verified repository state**, using small incremental patch ZIPs where appropriate; avoid overwriting newer files with legacy copies.
- [ ] Preserve existing `user://` save data and document any migration. Instruct players to back up saves before installing patches or downgrading.
- [ ] Include a short changelog, changed-file manifest, installation instructions, and reproducible validation steps with each patch.
- [ ] Keep regressions for inventory scene compatibility, weapon/animation references, item persistence, cosmetic determinism, hook state, and combat logic.
- [ ] Explicitly distinguish static checks, Godot headless tests, and a successful real F5 playtest in release notes.
- [ ] Track defects with reproduction steps, Godot version, screenshot/log, and affected save or scene when relevant.

## Immediate next-build checklist
1. Confirm the active `TestMythic` dropdown and the legacy-node compatibility regression.
2. Clean the duplicate script's unresolved merge conflicts without replacing the active inventory script.
3. Run existing repository tests and a real in-engine inventory/combat/save playtest.
4. Only then bundle the highest-priority visual, cosmetics, or puzzle change into the next patch.

> Scope and release versions are intentionally flexible. A checkbox means the item needs validation or implementation; it does not negate existing work already present in source. Update the checklist as tests and playtests establish what is actually complete.
