# GhostGirl v0.4 — Ashglass Secrets (Godot 4)

This update **extends v0.3** as the same `GhostGirl/` master project. It's a mechanics and exploration update, not an unrelated remake. Character sprites and `resources/ghost_girl_frames.tres` are preserved without changes, and the existing Moonrose Hook visuals remain intact.

## What's new

### Combat feel

- Three-strike **light attack chain** (different durations and damage per hit, 16 → 19 → 24). Press LMB during the final recovery of a light attack to queue the next; the chain breaks after the short combo window or after a dodge/heavy attack.
- LMB, RMB, or Space pressed during the late attack recovery can be **buffered**. A dodge can cancel the **last portion** of attack recovery after the attack's hit moment, not the committed windup.
- Stamina regenerates after a brief pause following an attack, dodge, or heal. No permanent sprint lockout; the familiar stamina costs remain.
- Enemy **poise**: a single weak hit doesn't always stagger armored foes. Repeated hits or a heavier blow can break their balance. A short stagger resistance period prevents constant stun-locking.
- Muted procedural hit sparks, floating damage values, slight camera kick and less generous dodge invulnerability. No character body sprites were redrawn or reshaped.
- Re-entering the current room by resting at a lantern shrine **respawns enemies**. Collected items and opened chests remain saved. Loose ground drops reset on rest.
- Melee target lock, rally healing, Ember Dew and wand casting remain.

### Moonrose Hook

- Keep **Q** to pull loose rigid-body objects and **F** to grapple valid fixed geometry or rose anchors.
- **Q can also yank existing enemy CharacterBody2D enemies** within the hook range, briefly interrupting their motion. A small cooldown keeps it from becoming permanent stun-lock. The hook still obeys intervening walls and `hook_blocker` on the hit node or any parent.
- Rose anchors can now implement an `on_hook_latched()` method, allowing designer-authored hidden discoveries without making the entire world a switch puzzle.
- Hook default distance stays **450px** (plus rolled hook-range bonuses from equipment).

### Ashglass Vault — optional new area

- A **new original gothic black-brick environment** with a wide, mostly unobstructed central floor and side alcoves; visually distinct from Ashen Causeway and other areas.
- Reach it from the east of **Ashen Causeway**, around `(2840, 812)`; return through the southern arch. For direct testing use **F12**.
- Two standard hunters and a sturdier Bell Keeper, an ember shrine, three visible loot chests and an additional **hidden coffer**.
- The secret rose sigil near `(1250, 800)` reacts when **F** latches onto it. The coffer becomes interactable and the discovery is stored in existing inventory save data; on return the coffer remains revealed.
- **Gloamglass Locket**: new reproducibly seeded charm item, with hook-range bonuses, quality rolls and up to two sockets. Find its Rare and Unique-quality variants in the vault.
- Editor-first nodes under `Gameplay/` for enemies, chests, secrets, collision, markers, shrine and portals. One original painting is the background, upscaled to the authored room footprint; collisions are broad bounds, not a detailed tile atlas.

## Controls

| Key | Action |
|---|---|
| WASD / arrows | Walk |
| Shift | Run |
| LMB | Quick attack / chain |
| RMB | Heavy attack |
| Space | Dodge, including late recovery dodge |
| L | Lock-on toggle |
| V | Ember Dew heal |
| Q | Pull physics object / yank enemy |
| F | Grapple to solid surface or rose anchor |
| X | Equipped wand spell |
| E | Interact / open chests / collect loot / rest |
| Tab / I | Backpack and socketing |
| C | Equipment |
| G / R | Drop / throw carried object |
| F9 / F10 / F11 / F12 | Testing: Court / Reliquary / Causeway / Vault |

## Recommended F5 playtest

1. Extract the full archive as `GhostGirl/`, or back up v0.3 and merge the v0.3 → v0.4 patch.
2. Import `GhostGirl/project.godot` in **Godot 4** and wait for asset import. Press F5.
3. Press **F12**. Walk around Ashglass Vault; confirm room and return portal, first shrine and each chest are reachable.
4. Fight a Mourner using **LMB → LMB → LMB**. Try a queued RMB and a late Space dodge. Watch stamina regeneration, enemy tells, damage numbers, and hit feedback.
5. Press Q while pointing at an enemy within range with a clear line of sight; confirm the yank, then test Q on a crate in a room containing movable items.
6. Face the faint rose sigil near the **left side of the north-center floor** and press F while pointing at it. A hidden coffer appears. Collect its unique charm and equip it; note the hook range bonus.
7. Exit and return. Secret discovery and chest collection should persist across this room transition and application restart.
8. E at the Ember shrine should heal, refill Ember Dew and **reset enemies** in that room. Check subsequent room transitions.
9. Revisit the older Crypt, Forest, and Garden; check original character proportions, the hook, inventory, seed rolls and animations.

## Technical notes / limitations

- **No engine run was available** during packaging. Static resource-path, PNG-decoding, archive-integrity, sprite-hash and rough walkability checks were performed. The package is not guaranteed F5 error-free until playtested in Godot.
- Enemy art remains procedural placeholder silhouettes. Their attack timing was refined in code; dedicated animated enemy sprites are still needed.
- The original paintings are single large backdrops rather than truly parallax-layered, tileable terrain. This room has generous collision bounds but furniture-level collision still needs a Godot-editor pass.
- Room shrines and story-puzzle flags remain session-only (inventory/equipment/chest discoveries and this hook secret persist in `user://`).
- The item qualities and affixes are prototype mechanics inspired by classic action RPGs; set bonuses, runewords, complete tooltip comparison, and drops-on-ground persistence still need design and playtesting.
- The Moonrose Hook only interacts with physics collision targets and explicit rose anchors. Decorative pixels without colliders cannot be hooked. Set the `hook_blocker` group on a collider or any ancestor to opt it out.
- The extra F9–F12 shortcuts are **developer testing commands**, not intended for final player controls.

## Updating your one master folder

**If your current installed project is v0.3:** back up the `GhostGirl/` folder (or make a Git commit), then merge the patch ZIP's `GhostGirl/` folder into yours. Modified scripts and scenes must be replaced; if you edited those yourself, merge the changes instead of overwriting them blindly. `project.godot` remains in the existing master folder.

For a clean installation, use the **complete v0.4 project ZIP**. It contains the same `GhostGirl/` directory as previous releases.
