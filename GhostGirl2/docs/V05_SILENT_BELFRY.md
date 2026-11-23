# v0.5 — Silent Belfry: build and playtest notes

## Area design

**Bellwether Court** (`scenes/rooms/bellwether_court.tscn`) provides an unobstructed central combat space surrounded by old brick chapels, a bell porch, a rose-covered iron gate, mourning angels and candlelight. The 3344 × 1882 world image is a proportional 2× upscale of a newly composed 1672 × 941 environment illustration. It is deliberately **not** a reused, mirrored or recolored earlier room. The scale supports larger traversal, but finer native-resolution environment art could be developed later.

The south exit returns to Ashen Causeway, while the western exit connects directly to Ashglass Vault. The reverse portals and `From_bellwether_court` spawn markers are editor-owned in those existing scenes. This creates a loop rather than forcing a single route.

### Encounter locations (editor coordinates)

| Element | Approx. position | Purpose |
|---|---:|---|
| South portal | (1680, 1670) | Return to the causeway |
| West portal | (445, 1120) | Shortcut into Ashglass Vault |
| Ember shrine | (1640, 1180) | Rest and persistent checkpoint |
| Mourner | (1080, 1160) | Light timing encounter |
| Warder | (2200, 1050) | Poise / heavy attack encounter |
| Bell keeper | (1660, 650) | Windup and dodge practice |
| Second mourner | (2400, 630) | Optional encounter |
| Secret bell chain | (2650, 640) | Hook-latch reveal |
| Hidden unique chest | (2740, 480) | Creative exploration reward |

### Edit it in Godot

Open `scenes/rooms/bellwether_court.tscn` and expand `Gameplay`. Move the existing `Portals`, `TreasureChests`, `Enemies`, `HookAnchors`, `RestShrines`, and `FutureSecrets` nodes directly. Under `Collisions`, select the individual `CollisionShape2D` rectangles and resize/replace with polygons. Use **Debug → Visible Collision Shapes** in an F5 test. For a hook exception, add the `hook_blocker` group to that collider (or its parent), as before.

## Mechanics in this pass

**Combat:** input buffer increased to 0.38 s; enemies try lateral steering rays if the direct approach is blocked; enemy windup strikes require line of sight; when Ghost Girl is hit, an approximately 0.19 s recoil interrupts her current attack and casting, leaving the existing post-hit invulnerability intact. Dodge-cancel of late attack recovery now begins movement immediately. L toggles lock-on, mouse wheel cycles visible targets while locked. Distinct enemy archetypes retain their attacks.

**Items:** nearby dropped items display their rolled, quality-colored name. A successful pickup notification inherits the same muted quality color. The existing independently seeded qualities, affixes, item stats, socket data, cosmetic palettes and equipment are preserved.

**Save/load:** a new `user://ghost_girl_world_v1.json` stores quest unlocks and shrine coordinates. It is deliberately separate from `ghost_girl_treasures_v2.json`, preserving seeded equipment and backpack progression for existing characters. No `user://` files are distributed in the patch.

**Sound:** `assets/audio/` contains four short original one-shot WAV sounds (swing, impact, dodge, hook). Select `GhostGirl/ActionSFX` in `scenes/player.tscn` to adjust volume or disable them.

## Required in-engine smoke tests

- [ ] Import `project.godot` in Godot 4, wait for asset import and press F5; check **Output** and **Debugger** for first errors.
- [ ] Travel from Moonwake Crypt normally, and press F8 to play Bellwether Court directly.
- [ ] From Bellwether enter Ashglass Vault and return, then take the Causeway exit and return to Bellwether.
- [ ] E at shrine heals/respawns enemies; relaunch game, rest/defeat should still return to the saved shrine.
- [ ] Attacks can be buffered during late recovery. L locks onto an enemy; scroll wheel cycles targets.
- [ ] Enemy approaches navigate at least around simple obstacles; no wall-through attacks.
- [ ] Q yanks an enemy/loose item; F grapples scenery, and `hook_blocker` still prevents latching.
- [ ] Use F on the subtle bell-chain sigil to reveal the unique hidden chest. Pick it up and revisit; it remains collected.
- [ ] Ground loot labels have the correct quality color and don't cover UI at long range.
- [ ] Test inventory, five equipment slots, wand spell, gem and rune socketing, seeded items and quest rewards.
- [ ] Character proportions, sprite scale and directional animations remain exactly as in v0.4.
- [ ] Listen for subdued audio; turn down ActionSFX if necessary.
- [ ] Test collision shapes around the bell porch and gate; adjust them in the editor if movement catches.

## Known gaps

The Godot engine executable was unavailable in this environment. File and route checks are not a substitute for pressing F5. There is no full navmesh, bespoke hunter animation or complex dungeon boss yet. This release favors improved fundamentals over rapid feature accumulation.
