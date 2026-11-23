# Ghost Girl v1.25 — Moonfall Blizzard

This is a **Godot project patch for v1.24**. No existing saved item, graphics atlas, enemy drop-table, or world-progress file paths are replaced.

## How to play

1. Start in **Moonwake Crypt** and find the **Frost Reliquary** a little north of the start point, between the weapon-testing pedestals.
2. Face it and press **E** once to learn **Moonfall**. This unlock is saved in the inventory's existing `collected_pickups` dictionary as `v125_moonfall_unlocked`.
3. Equip any wand. Aim at the desired area and press **Z** to cast.
4. The storm uses **37 stamina** and a **6.2-second cooldown**. It lasts approximately **4.2 seconds**, dealing fixed damage pulses every **0.70 seconds** and briefly slowing enemies.
5. The spell checks world collision before placement. The individual storm pulses also check walls so enemies on the other side of masonry cannot be struck through it.

## Cosmetic rolls

The existing wand seed determines the storm color and a separate cosmetic frost style. Normal and magic items receive restrained frost styling. Rare/set/unique wands can roll more elaborate appearances. These do not change the storm radius, hit frequency, slow strength or damage.

The item tooltip displays its Moonfall imprint. No new item-save field is required.

## Developer editing

- **Storm duration, radius, tick period, and visuals:** `scripts/moonfall_blizzard.gd` and `scenes/moonfall_blizzard.tscn`.
- **Shrine location and art:** `scenes/rooms/moonwake_crypt.tscn` and `scripts/moonfall_shrine.gd`.
- **Enemy slow response:** `scripts/rose_wraith.gd` and `scripts/gothic_hunter.gd`.
- **Wand cosmetic style selection:** `scripts/weapon_fx_library.gd`.
- **Casting and skill unlock:** `scripts/player.gd` and `scripts/game.gd`.

## Limitations

This release contains Moonfall Blizzard, not the bow weapon family. Bows remain the planned next update and should receive frame-authored four-direction animation rather than a floating hand attachment.

**Validation:** Static tests passed, but this environment does not have a Godot executable. Open the project in Godot 4.7 and playtest the new spell and enemy slowing. If Godot reports an error, send the error text and line number.
