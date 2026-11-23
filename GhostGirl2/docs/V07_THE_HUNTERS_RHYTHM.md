# GhostGirl v0.7 — The Hunter's Rhythm

## Main changes

- Melee attacks have more deliberate startup and recovery. Stamina recovers a little more slowly after exertion.
- Your backward dodge remains directionally restrained. A counter-hit after dodging now consumes the counter bonus **only on a successful hit**.
- Melee damage, heavy damage, poise breaking, backstep efficiency, stamina regeneration, attack speed, rally healing and cast speed are now equipment-driven stats.
- Wand **LMB** is a fast cast and **RMB** is a charged spell. Charged-wand damage and casting speed respond to gear.
- **Blade Hunter** (a committed forward lunge with a punishable recovery) and **Occultist** (a slower, visibly telegraphed ranged spell that walls can block) are new editable enemy archetypes.
- Three existing open-air areas receive the new encounter types and optional seeded equipment chests, rather than reusing painted backgrounds as new rooms.
- Four new equipment bases: Sable Hunter Dress, Censer Wand, Duelist Rosary, Thorn Vigil Sigil.
- New combat affixes appear only on **new level 7+ item bases**. Existing item bases retain their old seeded affix tables to preserve older saved rolls.

## How to test

1. Import `GhostGirl/project.godot` in Godot 4, allow assets to import, open `scenes/equipment_panel.tscn`, `scenes/inventory_panel.tscn`, `scenes/hud.tscn`, and `scenes/main.tscn` in that order. Press F5.
2. Use **F11** to go to Ashen Causeway, **F8** for Bellwether Court or **F12** for Ashglass Vault. Normal adventure still starts in Moonwake Crypt.
3. **WASD** move, **L** lock on, **Space** dodge backward, **LMB** quick / **RMB** strong attack. **Q** pulls objects/enemies; **F** grapples static scenery. **V** heals; **Tab** opens inventory; **C** opens equipment.
4. In Ashen Causeway find the Sable Duelist and West Occultist. Watch the short forward-lunge tell or longer spell telegraph, dodge or take cover, then strike during their recovery.
5. Obtain the **Censer Wand** from the west coffer, equip it in the backpack, then verify LMB fast cast / RMB charged cast. Test **Sable Hunter Dress** and **Duelist Rosary** in later areas to feel the difference in stamina costs and counterattack damage.
6. Test a rare or unique item drop, grid placement, sockets, deletion confirmation, and reopening saved inventory after restarting.

## Editor

- New enemies are native Godot nodes in `scenes/rooms/ashen_causeway.tscn`, `bellwether_court.tscn`, and `ashglass_vault.tscn` under `Gameplay/Enemies`.
- Their editable archetypes, damage, windup, move speed, loot seed, rarity, and drop base are exported from `scripts/gothic_hunter.gd`.
- Ranged bolt lives at `scenes/enemy_hex_bolt.tscn` and `scripts/enemy_hex_bolt.gd`. No art, sprite frame, profile, or Moonrose Hook resource was changed.
- All item bases are `.tres` files in `items/`; additional affixes are in `scripts/item_generator.gd`.

## Compatibility & known limitations

- v0.6 inventory and world save paths and formats remain unchanged. Back up saves and the project before applying a patch.
- Target lock, combat mechanics, and stage scripts have been statically checked, **not playtested inside Godot in this environment**. If Godot reports a parse/runtime error, capture the first error and line number.
- Enemies are still procedural-silhouette placeholders. Dedicated authored character animation sprites, smart long-range pathfinding, equipment balancing, and persistent enemy deaths are not yet implemented.
- Spawn positions are intended to be accessible on the large open painted areas but require an in-engine collision walk test.
