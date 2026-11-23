# Ghost Girl v1.8 — Weight of Roses

**Small incremental patch; install on top of v1.7 Moonrose Resonance.**

## Gameplay changes

- **Two persistent, physical pressure-plate secrets**, authored as editable Godot nodes:
  - **Blackbrick Court:** a moonstone crate near the southeast ruins opens a rose seal and a magic moon gem coffer.
  - **Ashen Causeway:** a moonstone crate near the southwest path opens another seal and a magic thorn rune coffer.
- Pick up a crate with **E**, drop it with **G** near the circular rose plate, or draw it toward Ghost Girl with **Q**. Only a grounded, released crate sitting on its linked plate activates it. A raised/held crate does not.
- Unlocking a seal persists under `collected_pickups` in the existing `user://ghost_girl_treasures_v2.json` file. The physical gate and coffer stay unlocked when the room reloads, including after restarting the game. The chest keeps its own independent one-time collection ID.
- Contextual UI prompt near an unsolved plate. Works without changing any original world backgrounds, character appearance, animations, or equipment atlas art.
- **Combat:** queued and immediate weapon attacks check the correct scythe/halberd stamina multiplier instead of only the generic base cost. Late dodge inputs can now buffer a follow-up light or heavy strike.
- **Rose-wraith:** a correctly timed retreat against its visible attack windup can arm a counterstrike; hook yank and weapon hits add a short cooldown to prevent an immediate bite. Striking during recovery inflicts a modest bonus.

## Installation

1. Back up the working **v1.7** project and existing Godot user save files.
2. Extract `GhostGirl_v1.8_Weight_of_Roses_PATCH_for_v1.7.zip` **into the folder containing `project.godot`**. Allow file replacement.
3. Start the project in Godot with **F5**. Existing items, equipment and rooms should be preserved.
4. In-game testing: use developer jump **F9** for Blackbrick Court or **F11** for Ashen Causeway. Find the crate and rose plate, then use **E/G** or **Q** to put the crate on the plate. Check the gate, one-time reward, save/reload, dodge counters and weapon stamina.
5. Optional static verification: `python tests/validate_v18.py`, plus the earlier v1.5/v1.6/v1.7 validators.

## Engine-testing limitation

The patch and all older compatibility validators were checked without a running Godot executable. Therefore physical scene collision, UI appearance and real-time combat behavior require **F5 playtesting in the editor**. This is a development patch rather than a certified release. Save data format and filenames are unchanged.
