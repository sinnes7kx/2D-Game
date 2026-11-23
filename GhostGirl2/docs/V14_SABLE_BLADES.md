# Ghost Girl v1.4 — The Sable Blades

This is a **Godot 4 source project**, not an executable build. Open
`project.godot` in Godot 4, wait for the texture import, and press F5.

## Controls and testing

- **No weapon equipped:** light/heavy attack uses new 4-direction unarmed frames.
- **Sword equipped:** light/heavy attack uses new 4-direction sword frames.
- **Wand equipped:** attack input still casts the existing moon spell.
- Press **I / C** to open the side-by-side backpack and character equipment.
  A **Dusk Needle** is given once to new and existing saves (if there is space).
- In the backpack **right-click Dusk Needle** to equip, or select it and
  press Equip. The Sword slot is on the bottom right of the paper doll.
- Click the Sword slot to unequip and test unarmed attacks again.
- Wands and swords cannot be equipped simultaneously.
- Defeated hunters and wraiths can now roll swords among ordinary loot.

To preview all attacks without fighting, open `scenes/development/combat_v14_preview.tscn` and press **F6**.

## Production sprites

- Art source: `art_sources/combat_v14/`
- Engine-ready frames: `assets/ghost/combat_v14/`
- Two atlases, both exactly **2048 × 1760**, **8 × 8**, **256 × 220** cells
- Each row plays left to right as eight consecutive frames (non-looping):
  0 light front, 1 light back, 2 light left, 3 light right,
  4 heavy front, 5 heavy back, 6 heavy left, 7 heavy right.
- The original approved idle/walk assets are untouched.
- The v1.3 animation resource referred to 64 omitted v1.2 attack PNGs:
  those frames are restored from the original user-approved atlas.
- The new generated combat artwork has been converted from RGB-on-black to
  transparent PNG, preserving black eyes (holes are filled inside the matte).
  It still warrants an in-editor art review to check small silhouette details.

## Loot and save compatibility

- Six new sword bases are defined in `items/`, with distinct blade damage,
  item levels, sockets, portraits, quality and rolled affixes.
- A sword carries its own deterministic blade-damage roll derived from seed,
  in addition to existing melee/attack-speed bonuses.
- The save path remains **user://ghost_girl_treasures_v2.json** and existing
  item indices/positions are preserved. The new Sword slot defaults empty.
- Backup your user save before upgrading if you have valuable progress.

## Comparisons

The inventory details are fixed-size and scroll; comparison text appears
in a separate floating overlay that never participates in inventory layout.
Sword comparisons additionally include blade damage deltas.

## Validation and known limits

Offline static validators check resource paths, row counts, sprite dimensions,
and unchanged save path. A Godot editor/runtime is not installed here, so this
is **not** a verified live gameplay build. Please open in Godot to test clicks,
animation timing, and visuals. If Godot reports an error, include its Output
log and the reported file/line.
