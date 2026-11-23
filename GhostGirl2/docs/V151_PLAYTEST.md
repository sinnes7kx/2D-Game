# Ghost Girl v1.51 — manual Godot playtest

- Verify the project has original art assets including:
  `assets/ghost/combat_v14/sword_idle_front_00.png`
  `assets/ghost/combat_v14/attack_sword_light_front_00.png`
  Those art sprites were included in the supplied RAR source archive and are
  not duplicated by this script patch.
- Equip a one-handed BLADE in the sword equipment slot (a wand alone does not
  trigger sword highlights). Check idle/walking and normal/heavy/jump attacks
  in front/back/left/right directions. Blade light should be visible, in the
  sword region, not on the face. Guides are authored approximations to tune
  using visual feedback, not pixel-precise masks.
- Equip a different quality and reroll cosmetics. Glow color changes without
  damage/stats changing; saved cosmetic appearances restore the same color.
- Hover items (different slots/classes, socketed items, wands, swords, bows),
  then press/release ALT while remaining still. Hover tooltips should expand
  and collapse live, revealing lore and visual effects only with ALT.
- Press/release CTRL on an item with a different equipped item in its slot:
  comparison should appear/disappear. ALT+CTRL displays advanced and comparison.
- Click an item in the inventory; ALT should also expand/collapse the selected
  item's text. No loot/look seed IDs should appear, even with ALT.
- Ensure popup follows cursor and stays inside viewport boundaries.
- Save/reload a character; item affixes, appearance favorites, equipment, and
  world progression should remain unchanged.

This patch has static checks, **not an in-engine runtime verification**.
