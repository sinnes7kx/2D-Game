# Ghost Girl v1.7 — Moonrose Resonance (incremental patch for v1.6)

## Features

- **Two ordered rose-switch puzzles** added to Ashglass Vault and Bellwether Court, using editor-placed, independently persisted seals, locked physical rose gates, and individually seeded reward chests. Open them by casting the rose hook **F** on the first rose, then the second. Wrong-order casts produce a brief rose flash/hint and cannot skip puzzle progression.
- Solved switches and opened chests are saved in existing collected-pickups state without changing the inventory save filename or the item serialization format. Saves from v1.5 and v1.6 remain readable.
- Existing v1.5 single-switch puzzles still work with no dependency configured. Existing hooks, anchors, chests and room backgrounds are not replaced.
- **Rose-hook cooldown fix:** switching and player-reeling cast modes no longer lose their original cooldown selection when retracted.
- **Wraith combat:** weaker regular rose-wraiths now pause for a visible 0.52s telegraphed bite, followed by a recovery window. Leaving attack reach or stepping out of its facing arc avoids the bite; a weapon strike or Q-hook yank interrupts it. Damage is no longer instantaneous on touch.
- **Combat responsiveness:** light, heavy and dodge inputs pressed during the brief hitstop now queue into the post-strike sequence instead of being dropped; room reset no longer forces weaponless idle when scythe/halberd is equipped.
- **Inventory comparison:** sword/scythe/halberd detail shows *base* first-light-strike timing and stamina; compare tooltip shows difference in strike time. This does not replace actual item stat rolls or character stats.

## Install

1. Back up the working **v1.6** game and `user://ghost_girl_treasures_v2.json` save.
2. Extract `GhostGirl_v1.7_Moonrose_Resonance_PATCH_for_v1.6.zip` **onto the project folder containing `project.godot`**, allowing overwrites. Do not extract it one folder above or install straight onto v1.4.4.
3. Open Godot, run F5. Use F11 to visit Ashen Causeway and the existing game route to reach the new puzzles in Ashglass Vault and Bellwether Court.
4. Aim at a rose and use **F** to latch it; activate the roses in order, then open the now-unlocked coffer using **E**. Test room exit/re-entry and save/reload.
5. Try Q pulling a normal wraith during its warning; try weapon strikes, dodge, and queued combat input at the instant of a hit.
6. Run `python tests/validate_v17.py`. Earlier v1.5/v1.6 validators should remain passing.

## Scope and limits

This is an **incremental source patch** with no rebuilt original backgrounds, animations, or soundtrack. The original 2048×1760 scythe/halberd atlases from v1.6 stay in place. GDScript and Godot resource structure are statically validated; Godot runtime is not installed in this environment, therefore there is no claim of successful in-engine playtesting. The editor placement, collision clearance, and combat balance should be checked in Godot.
