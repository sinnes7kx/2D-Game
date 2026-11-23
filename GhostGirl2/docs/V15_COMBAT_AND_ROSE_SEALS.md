# Ghost Girl v1.5 — Combat & Rose Seals (development build)

Based on the two user-supplied v1.4.4 ZIP parts. No changes to the original approved
Ghost Girl source frames or the existing 2048×1760 source atlases. No save-file path
changes: the inventory continues using `user://ghost_girl_treasures_v2.json`.

## Implemented in the playable project

- Directional melee aim is sampled and locked when attack inputs are buffered, with a
  visible-body cursor dead zone and movement-direction fallback. Facing stays locked
  through the hit/recovery and is reset only at the next action.
- 19 additional, editor-placed fragile wanderers in five combat rooms. Existing
  ordinary combatants have less health and deal less damage. The notable hunter,
  occultist and bell-keeper encounters remain marked as **elites** with stronger
  stagger resistance and more prominent, restrained rings.
- Monsters now drop equipment approximately 14% of the time for standard mobs and
  42% for elites (stable per enemy/seed), instead of every kill. Random item rolls
  are now approximately 80.99% normal, 15% magic, 3.3% rare, 0.55% set,
  0.15% unique. Explicit chest/quest quality, and all loaded saved item quality,
  remain intact.
- The F rose-hook can now operate **persistent, editor-authored spectral rose
  switches**. Aiming at the switch fires the tether without inadvertently pulling
  the girl into the gate. Two rose switches/gates are placed in Blackbrick Court
  and Ashen Causeway. Their activated state is written to existing collected-pickup
  data and restored on entering the room. Each switch also unlocks a nearby
  pre-existing treasure chest (Censer Cache / Iron Rose Chest), giving it a
  tangible reward.
- Existing Q pullable objects, F anchors, enemy hook stagger and hidden ashglass
  secret remain intact.

## Art integration status

The provided project contains sword and unarmed directional attack PNGs but **not**
complete directional scythe or halberd animation atlases. The two reference images
show item icons and four colored poses, not the 8×8 2048×1760 directional sheets.
Accordingly, no duplicate/mirrored/recolored character attack animations have been
fabricated and no new scythe/halberd classes are falsely advertised as complete.
Those two animation integrations remain pending source atlases.

## Test sequence

1. Open `project.godot` with a Godot 4 editor and run the main scene.
2. Enter Blackbrick Court and Ashen Causeway using existing world portals/test paths.
3. Use F aiming at the rose switch next to each spectral gate. Leave and return;
   the gate should remain open.
4. Fight regular enemies and occasional elites, checking density/damage and that
   loot is no longer dropped after every kill.
5. Test light/heavy attacks facing each of the four directions, with cursor far
   away, cursor on the character, locked-on enemies, mid-combo queueing, and dodges.
6. Verify preexisting equipment items, sockets, and collected rewards after restart.

> Static tests can be run with `python tests/validate_v15.py`. A headless Godot
> executable was not present in the execution environment, so engine startup and
> real-time animation validation still require running the project in Godot.
