# GhostGirl — Blackbrick Court Combat Draft (v0.2)

This update continues the **single `GhostGirl/` master project**. The existing 2D Ghost Girl character, 8×8 animation source, rose hook, carrying/throwing, inventory/equipment, item rolls and socket system are preserved.

## Test the new gameplay quickly

1. Import `GhostGirl/project.godot` in **Godot 4.x** and press **F5**.
2. Press **F9** for the **Blackbrick Court** (developer shortcut; normal entry is via Briar Hollow). Press **F10** for the smaller **Candle Reliquary**.
3. Use **WASD** to move and **Shift** to run. **Left-click** for a quick attack, **right-click** for a strong attack, and **Space** to dodge.
4. Watch enemies: they stop and show a circular/aimed warning before attacking. Dodge out of range or counterattack to stagger them.
5. Dodge and attacks cost stamina (small muted green bar). Stamina returns when you're not performing those moves.
6. When injured, a successful melee hit within about three seconds restores some of the recent damage (**prototype rally**).
7. When a new hunter dies, it drops loot on the ground; press **E** within reach to collect it. The aura indicates the item's rolled rarity. Items use existing deterministic quality, affix, palette and socket rules.
8. Open the inventory with **Tab**, equip items, and use gems/runes to socket as before.

## Other retained controls

- **Q** — Rose hook pulls physical objects.
- **F** — Rose hook grapples fixed scenery or rose anchors (450 px base range, with equipped bonuses).
- **E** — Interact, open chest, collect ground loot.
- **G/R** — Drop or mouse-aim throw a carried object.
- **X** — Wand spell when a wand is equipped.
- **C** — Equipment panel, **H** — optional help.

## New areas

**Blackbrick Court**, 3344×1882 pixels: a new, original black-brick gothic courtyard painting with a large open combat surface, two types of hunter enemies, two seeded chests, hook anchors, and planned secret spaces. A portal connects from **Briar Hollow**. A smaller left-side entrance leads indoors.

**Candle Reliquary**, 2304×1536 pixels: a distinct previously unused, originally authored cathedral-interior illustration, added here as an accessible, smaller room. It has two more enemies, one fixed unique-quality treasure chest, a rune cache, and its own collision and secret markers. It is not a recolored copy of the courtyard.

Both areas use **separately editable** `StaticBody2D`/`CollisionShape2D` boundaries and named `Gameplay/` groups in their `.tscn` files. Enemy instances expose attack speed, windup, damage, archetype, and loot data in the Inspector. Open the room scenes to reposition all elements visually.

## Combat draft design

This is a **Bloodborne-influenced prototype**, not a reproduction or finished combat system. Timing and retaliation matter more than rapid, risk-free hits. The light/strong melee attacks currently reuse the approved throw animation and add a procedural slash effect; bespoke directional attack frames are an art-production follow-up. Enemies are editor-visible drawn placeholders, not final monsters.

## Loot and equipment

The existing **Normal, Magic, Rare, Set and Unique** qualities, numerical affixes, sockets, gems and runes stay intact. New equipment templates `ashbound_wand.tres` and `blackbrick_reliquary.tres` provide additional equipment bases. The game retains seed-based reproducibility for individual item rolls. Set bonuses and Diablo-style runewords are **not implemented yet**.

## Current limitations and safety

- The Godot runtime was not available in the build environment. Archive, resources, image decoding, and approximate path access are checked statically, but **F5 engine behavior has not been confirmed**.
- No Souls-like lock-on, poise system, weapon transformations, parrying firearms, formal checkpoints, or advanced combat animations yet.
- Enemies respawn when reentering their room. Chests are one-time and save through the existing inventory/save system. New enemy drops are collected from the ground but do not persist after leaving the room.
- These outdoor and interior illustrations are large continuous paintings with editable *approximate* collisions, not fully layered foreground tilesets. Keep refining them in the editor as you expand the world.

## Regression tests to perform in Godot

- [ ] Run master project from the Crypt; confirm original Ghost Girl proportions.
- [ ] Hook Q/F at 450 px and confirm no animation changes.
- [ ] F9 enters the new Blackbrick Court; F10 enters Reliquary.
- [ ] Dodge consumes stamina and ignores damage during the roll.
- [ ] Light/heavy attacks strike only enemies in range and in front, blocked by walls.
- [ ] Enemy windup/tell, stagger, damage and death all work.
- [ ] Enemies drop ground loot that can be collected using E.
- [ ] Chests produce saved randomized quality/socket rolls.
- [ ] Tab/C inventory and equipment still work; socket a gem/rune.
- [ ] Backtracking through portals works; no actor is stuck in scenery.
- [ ] Debug → Visible Collision Shapes matches playable floor boundaries.
