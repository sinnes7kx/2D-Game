# Ghost Girl v1.6 — Moonrose Arsenal (incremental patch for v1.5)

This patch installs on the v1.5 Godot project (`GhostGirl_v1.5_Patch_for_v1.4.4.zip` already applied, or the full v1.5 project). It contains **only 17 changed/new game files plus this document and the v1.6 validator**, not the original multi-hundred-megabyte assets.

## Real game changes

- New **Rose Reaper scythe** and **Lunar Vigil halberd** are equippable in the established `sword` equipment slot, keeping existing inventory structure and saves intact. Equipping one still holsters a wand.
- Each weapon has 16 named directional actions: idle, walk, light attack, heavy attack across front, back, left, and right. Eight distinct frames per action are baked into **two 2048×1760 atlases per weapon**: one locomotion sheet (rows 0–3 idle, 4–7 walking) and one attack sheet (rows 0–3 light, 4–7 heavy). The runtime atlas loader creates Godot `AtlasTexture` regions and installs them into `AnimatedSprite2D` `SpriteFrames`.
- The approved Ghost Girl character pixels were **preserved**. These first-pass weapon animations are composites of the original approved directional Ghost Girl body poses and newly illustrated scythe/halberd sprites; they are **not** claimed to be 256 fully redrawn character poses. Their visual polish and hand/weapon alignment should be reviewed in Godot before treating them as final production artwork.
- Weapon-specific timings, stamina costs, strike arcs, stagger, attack distances, and poise distinguish scythe sweeps from the more deliberate precision halberd strikes. Damage rolls, palettes, sockets, rolled affixes and qualities remain with the existing item generation and save code.
- New inventory tooltip labels show weapon family, weapon damage and effective light-attack reach. Comparisons include relative attack reach.
- Two independently persisted new treasure chests have been placed near the entry approaches in **Blackbrick Court** (Rose Reaper) and **Ashen Causeway** (Lunar Vigil). Neither alters or removes the v1.5 rose-gate reward chests. Normal equipment drops can also roll either weapon through the shared loot table.

## Quick test

1. Back up your v1.5 Godot project **and** your `user://ghost_girl_treasures_v2.json` save file. Extract the v1.6 patch directly into the existing Godot project root, accepting changed-file replacements.
2. Open `project.godot` in Godot 4 and run (F5). **F7** adds one of each trial weapon to the backpack if that item type is not already present; open inventory with I, equip by right-click or its Equip button. F7 is a developer test shortcut and is optional.
3. Alternatively **F9** goes to Blackbrick Court, where a new chest contains the scythe. **F11** goes to Ashen Causeway, where a new chest contains the halberd. Test the full game progression without using shortcut keys.
4. Try light/heavy attacks aimed in all four directions, counters, walking, recovering, equipping/unequipping and save/reload. Test with enemies near the front and side of the attack, and behind walls.
5. Run `python tests/validate_v15.py` and `python tests/validate_v16.py` for static smoke checks.

## Compatibility and testing limits

- Requires v1.5 as a base. Do not install this patch directly on v1.4.4.
- Existing v1.5 keys, scenes, rose-switch logic, loot odds, original animation PNGs and background art are not replaced.
- Save format still uses `user://ghost_girl_treasures_v2.json`; newly saved weapons reference the two new `.tres` resources. Older saves do not need migration.
- All resource references and generated atlas geometry passed the static Python tests. This environment could not install or run the Godot executable, so **F5 gameplay, engine import, and rendering have not been tested here**. This is a **development patch**, not a certified playable release.
