# GhostGirl v0.3 — The Hunter's Path

A **single-project update** to GhostGirl v0.2. Gothic-fairytale 2D half-top-down adventure, deliberate melee combat, and seeded loot. No dialogue. Original Ghost Girl character artwork and Moonrose Hook remain untouched.

## What to play

- **New Ashen Causeway:** original blackbrick cathedral plaza painting; 3344 × 1882 pixels, broad open combat floor, west chapel doorway, south return to Blackbrick Court. The Candle Reliquary also connects back into the Causeway, creating a proper exploration loop.
- **Three enemy personalities:** Mourner (fast chase/front strike), Warder (heavy circular sweep), Bell Keeper (telegraphed forward lunge). Positioning, recoveries and collision matter. They use stylized drawn placeholders pending final monster sprites.
- **Lock-on (L):** selects one reachable nearby enemy (within ~620 pixels) with a subtle world marker. Melee and wand spells favor that target. Press L again to release. Line of sight is checked against world geometry.
- **Ember Dew (V):** starts with 3 charges, each restoring 43% of maximum health after a short vulnerable windup. Damage interrupts healing; the charge is spent. A tiny muted HUD readout shows remaining doses.
- **Lantern Shrine (E):** activate the shrine to restore HP, stamina and 3 dew charges, and set the in-session defeat-return point. Defeat returns you there and respawns enemies. The old project start and puzzle progression remain unchanged.
- **Combat tuning:** the Bell Keeper has a distinct lunging tell, enemies stop pursuing once far from their encounter area, enemy line-of-sight matters, and attacking shortly after a dodge gives a modest counterattack damage bonus. The rally mechanic still returns recently lost health when you successfully retaliate.
- **Treasure:** four new individually seeded chests in the Causeway, including a guaranteed Rare *Ash Vigil Charm* and a guaranteed Unique-quality heirloom. The charm adds a **vitality** stat that now raises maximum health; its exact value, quality affixes, sockets and palette remain seed-derived. Runes and gems still socket into eligible equipment.
- **Future secrets:** named empty `Marker2D` locations in the new scene; no secrets are falsely claimed as implemented.

## Controls

| Control | Action |
|---|---|
| WASD / arrows | Move |
| Shift | Run |
| Left mouse | Quick melee strike |
| Right mouse | Heavy strike |
| Space | Dodge (short invulnerable period) |
| **L** | Toggle target lock |
| **V** | Heal using Ember Dew |
| Q | Moonrose Hook pulls a loose rigid object |
| F | Moonrose Hook grapples world geometry or rose anchor |
| X | Cast equipped wand spell |
| E | Collect loot, open chest, enter doorway, rest at shrine |
| Tab / I | Backpack |
| C | Equipment |
| G / R | Drop / mouse-aim throw carried object |
| H | Show/hide controls |

## Quick playtest route

1. Import `GhostGirl/project.godot` into **Godot 4**, wait for the image importer, and press **F5**.
2. Start in Moonwake Crypt as before. For quick testing of this update, **F9** opens Blackbrick Court, **F10** Candle Reliquary, or **F11** Ashen Causeway (development shortcuts).
3. F11: move toward the center; press **E** at the small ember shrine to rest. Note the dew counter.
4. Approach the left Mourner. Press **L** to lock on. Watch its forewarning; Space-dodge, then strike to stagger it.
5. Try **V** after taking damage. The cast has a windup, consumes one charge, and can be interrupted. Return to the shrine to refill.
6. Approach the Bell Keeper near the north gate. Its warned forward lunge should differ from the Warder's circular sweep.
7. Open the western chest to get a Rare Ash Vigil Charm; equip it with C/Tab, verify HP maximum increases after resting. Find a socketable drop and insert a gem or rune with the existing inventory workflow.
8. Enter the small Candle Reliquary from the west side, and return via its added Causeway exit; verify the Blackbrick Court return portal also works.
9. Verify **Q/F** hook mechanics, original directional sprites, movement, throwing, equipment panels and world transitions have not regressed.

## Editor layout

`scenes/rooms/ashen_causeway.tscn` has a separate backdrop and these *editor-owned* node groups: `Collisions` (select individual named RectangleShape2D nodes), `SpawnPoints`, and `Gameplay/` containing `Portals`, `Enemies`, `TreasureChests`, `HookAnchors`, `RestShrines`, `FutureSecrets`, and reserved reusable groups. The original 8×8 character sheet and `resources/ghost_girl_frames.tres` are unmodified; animations were not regenerated.

`ash_vigil_charm.tres` is an ordinary item data resource. `scripts/lantern_shrine.gd` can be reused on any Node2D you create for future checkpoint locations; its exported `shrine_id` can be set in the Godot Inspector.

## Known limitations

- The Godot executable is **not available in the build environment**. Resource paths, image decoding, file integrity, character asset hashes and *approximate* navigability have been statically checked, but the new combat was **not actually run in F5**. Engine-specific parser errors or collision tuning may still need correction.
- Enemy character sprites and melee animations are temporary drawn/procedural effects, **not** finished character animation sheets. Ghost Girl retains her original approved frames; there is no deformation or sprite replacement.
- Checkpoints are **session-only** (unlike the inventory's saved item data). The game begins in Moonwake Crypt on a fresh launch. Chests remain saved between sessions; world loot on the ground is not saved.
- Item quality and socket rolling is a prototype inspired by classic action RPG itemization, not a complete Diablo II equipment-affix/runeword system. Set bonuses and runewords remain future work.
- The new background is a unique original **full-room painting upscaled 2×** for the intended world size, not a layered high-resolution tile atlas. Collision bodies are approximations; use Debug → Visible Collision Shapes to refine.

## Updating the one master folder

1. Back up your current **GhostGirl** folder, or make a Git commit.
2. **Patch installation:** merge all files from the patch ZIP's `GhostGirl/` directory into your existing `GhostGirl/` folder; approve replacements only after your backup. This patch assumes v0.2.
3. **Fresh installation:** extract the full v0.3 ZIP to a new folder, which contains `GhostGirl/project.godot`.
4. Do **not** delete `user://` save data unless you explicitly want a fresh inventory; item saves should remain compatible.
