# v1.3 — The Reliquary / Gameplay integration log

## Inventory fixes

The v1.2 `InventoryPanel` used a content-wrapping `Label` in a `VBoxContainer`. Large item descriptions and appended equipped-stat comparisons increased its minimum height and pushed the rest of the inventory around. In v1.3, `ItemDescription` is a **RichTextLabel with fit_content=false inside a bounded DetailsWell**. The `ItemComparePopup` is outside both panels as a sibling of `InventoryPanel` and `EquipmentPanel`, uses a fixed 330px high double/single column with scrolling, follows the pointer while clamping within the viewport, and ignores mouse input, so even a very long item's stats cannot affect the panel layout.

The two inventory scenes remain **editor-authored Control nodes** and are now visible together. The left side has an original Ghost Girl paper doll, five equipment slots, and summarized character stats. The right retains the 10×4 grid across eight pages, drag movement, sort, socket and explicit destruction confirmation. Currency/rarity and content still use the existing item resources. ESC closes the combined overlay.

## Animation frames (256×220 cells, row-major 2048×1760 atlas)

| Atlas name | Row assignments | Used in game |
| --- | --- | --- |
| `dodge_8x8_2048x1760.png` | 0–1 front; 2–3 back; 4–5 left; 6–7 right | All four 16-frame dodge tracks |
| `attack_sword_8x8_2048x1760.png` | 0–1 front; 2–3 back; 4–5 left; 6–7 right | Four 16-frame `attack_sword_*` tracks, workshop preview (weapon slot future) |
| `hook_launch_8x8_2048x1760.png` | 0–1 front; 2–3 back; 4–7 blank | Real front/back 16-frame hook gesture, side uses prior original animation |
| `attack_light_alt_8x8_2048x1760.png` | 0 front; 1 back; 2 left; 3 right; lower rows heavy concept | Second hit in 3-hit light combo |
| `new_hurt_counter_8x8_2048x1760.png` | 0–3 hurt front/back/left/right; 4–7 counter front/back/left/right | Hurt reaction and backstep-counter attack |
| `assets/effects/rose_slash_8x8_2048x1760.png` | 0–3 light effects; 4–7 heavy effects, front/back/left/right | Confirmed melee-hit effects only |

Images and Godot scenes are in the full project. The original eight-sheet pack supplied by the user is not mutated; selected sheets are copied into the new project under `art_sources/combat_v13`. No images are recolored as replacement rooms.

## Validation and limitations

All resource paths are checked against actual files, scene resource IDs checked for duplicates, 256 new combat PNGs tested for exact frame resolution, six 8×8 atlas files checked for 2048×1760 geometry, save path preserved. A Python static check cannot guarantee the Godot engine will load and render flawlessly; inspect `scenes/development/combat_v13_preview.tscn` (F6) and main scene (F5) in Godot.

Potential follow-up: dedicated original left/right hook launch, inventory item hover UX with gamepad, detailed wardrobe/item cosmetics, responsive scaling for sub-1280×720 windows, equipment slot upgrade for the sword animation.
