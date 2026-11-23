# GhostGirl v0.6 — Deliberate Combat & Backpack

Godot 4 master project update. **No character sprites, animation frames, RoseHook script, room art, or enemy scripts were replaced.** This update improves the existing melee / wand attack inputs, movement, backstep, and inventory.

## Changes

### Movement & combat
- **WASD/arrows:** Grounded acceleration and stronger braking. Base walk speed 162 px/s, sprint 225 px/s, sprint drains stamina, turning requires a short commitment. Foot animations remain exactly as supplied.
- **Space:** **Always backstep** opposite facing. With lock-on, Ghost Girl faces the opponent and retreats directly away from them, ignoring the movement key held during the dodge. Short invulnerability as before.
- **LMB / RMB:** Quick and heavy weapon attacks. Bare-handed/rose-hook weapon stance uses the existing three-hit melee sequence and heavy arc. **If a wand is equipped:** LMB sends a faster light spell (14 base damage, 18 stamina); RMB channels a larger, slower heavy spell (35 base damage, 38 stamina). Damage scales with existing spell-power equipment rolls.
- **X:** Optional backwards-compatible quick wand attack shortcut.
- **L:** Enemy lock-on stays; Moonrose Hook Q/F stays at its existing 450-pixel range plus item bonuses.
- Existing rally, stagger, item rarity, combat SFX and shrine features remain.

### Diablo-II-inspired backpack
- The backpack uses a genuine **10-column × 4-row spatial grid**. Larger items occupy more cells: dresses 2×3, wings 2×2, wands 1×3, charms/gems/runes/keys 1×1. Existing item resources can override their footprint via `inventory_width`/`inventory_height` in the Inspector.
- There are up to eight pages for older saves / overflow. Use the small left/right page buttons; page 1 is the default. Item capacity is 40 distinct items (vs the older 24). Item count and available cell space are separate limits.
- Left-click selects, right-click equips gear, drag-and-release moves items to free cells on the same page. Empty cells are drawn in dark iron; item borders reflect quality and sockets are shown visually.
- Select an item and choose **DESTROY ITEM** to remove it permanently. A confirmation dialog is mandatory. **Equipped and quest items are protected**: unequip equipment first; quest items cannot be destroyed.
- **SOCKET GEM/RUNE:** Select a socketed item and press the socket button, then click a gem or rune anywhere in your backpack. Its existing permanent socket bonus is applied, and the component is consumed.
- Old `user://ghost_girl_treasures_v2.json` files remain compatible. Grid position keys are added to existing item save entries on the next save. Item seeds and qualities are unchanged.

## Runtime script dependencies (addressing earlier UI parse failures)
`scenes/inventory_panel.tscn` and `scenes/equipment_panel.tscn` each attach their controller script **directly**. `scripts/hud.gd` no longer adds controllers dynamically in `_enter_tree()`. All scene files use native editor nodes, including the backpack's custom Control drawing surface. The original `bind_inventory()` methods remain available.

## Quick playtest in Godot
1. Back up the `GhostGirl` folder; import `project.godot` in Godot 4 and let the import finish.
2. Open `scenes/inventory_panel.tscn` and `scenes/equipment_panel.tscn` before `scenes/main.tscn` to verify the scene dependency chain.
3. F5 starts in Moonwake Crypt. Enter the combat areas or use the existing F8/F9/F11/F12 test shortcuts.
4. Stand still facing an enemy, press **Space**: Ghost Girl should hop backward without turning around. When locked with L, she retreats away from the target while facing it.
5. **LMB/RMB** should use quick and heavy melee attacks. Equip a wand using Tab and right-click it; LMB/RMB should launch light/heavy magic projectiles instead. Hold sprint to see stamina drain.
6. Collect a dress, wand, gem, rune or charm. Open Tab and inspect their different grid footprints. Drag into open cells, try equipping, socketing, and removing a non-quest, unequipped item.
7. Save, close and restart: seeds, sockets, equipped slots and grid locations should persist.
8. Verify that Q/F Moonrose Hook, original sprite proportions and F8/F9/F11/F12 area shortcuts still work.

## Limitations
This is a practical prototype, **not a verified release**. A Godot executable was unavailable during packaging, so gameplay and parser behavior were not engine-tested. Inventory drag currently supports moving within a page only; page boundaries are used for additional storage. Some item icons are placeholders, and precise attack/dodge tuning still needs playtesting.
