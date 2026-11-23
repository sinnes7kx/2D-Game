# Ghost Girl — Act I / The Forgotten Treasures

## What's new in this build

This is the first playable step of the equipment roadmap: **6-slot inventory + a separate equipment window + deterministic seeded item variants + visible cosmetic layers + real stat bonuses**. Fishing is not included yet, because catches will need this foundation.

### Controls

| Key | Action |
|---|---|
| E | Pick up a collectible when facing and near it |
| Tab / I | Open / close the existing six-slot keepsake inventory |
| C | Open / close the separate equipment window |
| Click item in inventory | Inspect its seed, palette, pattern, and stat |
| EQUIP | Equip the selected dress / wings / trinket / charm |
| Click equipped item in equipment window | Unequip it (it stays in inventory) |
| Q / F | Rose hook pulls objects / Ghost Girl |
| G / R | Drop / throw physical object |
| H | Toggle help |

### Collectible locations

All pickups are **actual editable room nodes** in `scenes/rooms/*.tscn`, under `Gameplay/Collectibles`. Their seeds are exported in Godot's Inspector; move their `Node2D` positions to reposition them. A pickup can be collected only once per save file.

| Area | Treasure | Seed | Slot / effect |
|---|---|---|---|
| Moonwake Crypt | Moon Rose Key | 101 | Quest key, unchanged |
| Memorial Gallery | Moonwoven Dress | 274613 | Dress / +2–6% move speed |
| Rose Arbor | Rosewing Mantle | 981614 | Wings / +4–10% hook pull speed |
| Rose Arbor | Moonwoven Dress (second roll) | 487155 | Dress / distinct reproducible variation |
| Broken Rose Bridge | Mourning Locket | 380117 | Trinket / +3–9% hook range |
| Waking Garden | Silver Thread Charm | 720613 | Charm / +5–12% throw force |

**The same item template with different seeds can have different color, decorative pattern and stat rolls**. Re-entering a room will not duplicate already collected pickups. Gear remains in the inventory while equipped, so selecting a different dress switches the worn dress without consuming or duplicating items.

### What changes visually

- Dress slot: selective pastel garment-tint shader on the **existing original Ghost Girl frames** (face and hair are left unchanged). This is a prototype mask, not a fully painted dress layer.
- Wings slot: separate, recolorable translucent feather artwork behind the original sprite, animated with a restrained idle sway.
- Trinket / charm: separate recolorable pendant artwork above the character's chest, hidden on rear-facing frames.
- Original movement, directional hook animation, and all other character sprite resources are **untouched**.

For future layered customization (complete new dress silhouettes, wings of many shapes, bows, ribbons, jewelry, lacy hems), add separate *artist-authored sprites or masks* to `scenes/player.tscn → EquipmentVisuals`, rather than recoloring entire character frames. **This build does not create hundreds of complete equipment sprite variations.**

### Stat effects (not just descriptions)

- `move_speed_pct` affects Walk/Sprint speed in `scripts/player.gd`.
- `hook_range_pct` modifies the rose hook's existing 450-pixel base range dynamically in `scripts/rose_hook.gd`.
- `hook_pull_pct` modifies object and character pulling speed in `scripts/rose_hook.gd`.
- `throw_force_pct` modifies thrown object planar velocity in `scripts/carryable.gd`.

The three random variables use **separate deterministic RandomNumberGenerator instances**, so changing garment colors does not reroll gameplay stats.

### Save game

Inventory content, exact seeds, equipment slots, and collected-pickup IDs persist in `user://ghost_girl_treasures_v1.json`. The game reconstructs rolls from each saved definition path + seed, so stored colors/stats are not arbitrarily regenerated on loading.

To start the item-collection demo again, remove this file from Godot's user data directory (**Project > Open User Data Folder**) while the game is closed. The existing room-puzzle completion flags and player position **are still session-only**; a complete story save system is a later milestone.

### Editing and expanding the system

1. Make a new `GhostItemData` resource (`scripts/item_data.gd`) with item ID, icon, equipment slot, stat type, min and max stat. See `items/*.tres` for examples.
2. Duplicate a pickup node in `scenes/rooms/*.tscn → Gameplay/Collectibles`; change `item_data`, `pickup_id` and `item_seed` in the inspector. **Every pickup_id must be unique across the game.**
3. Change palette presets/labels in `scripts/palette_library.gd`. A seed's palette index remains stable unless the palette list/order changes.
4. Customize cosmetics in `scenes/player.tscn → EquipmentVisuals`, or replace the simple dress tint shader at `assets/equipment/dress_palette.gdshader` with art-directed per-frame garment masks.
5. Refine the inventory panel in `scenes/inventory_panel.tscn` and equipment window in `scenes/equipment_panel.tscn` without touching the game orchestrator.

### Known limitations

- **No Godot engine F5 smoke test was possible in the build environment.** Resource links, scene structure, image validity and reachable pickup coordinates were statically checked.
- Palette changes use a deliberately conservative garment-region shader; final detailed layered equipment art still needs a character-art production pass.
- No fishing gameplay in this milestone.
- No dialogue, combat, RPG loot spam or extra giant HUD overlays were introduced.
