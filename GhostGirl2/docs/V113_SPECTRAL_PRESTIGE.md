# Ghost Girl v1.13 — Spectral Prestige

Incremental patch, install over v1.12. All supplied approved Ghost Girl body sprites, backgrounds, enemies, item definitions, weapon atlases and save file paths remain unchanged.

## Dodge → riposte feedback

- A legitimately timed backstep **against an enemy's telegraphed attack** opens a 0.62s counter window. This also works without an enemy manually locked; it does not auto-lock the target.
- A tiny lavender `COUNTER READY` bloom appears when that window is earned.
- A counter **that actually hits** creates an oversized gold-white/varying weapon-colored riposte rose ring, floating `RIPOSTE!` label, synchronized streaks and sparks, distinct synthesized glass-bell chime, brief 0.105s hitstop, and more pronounced camera kick.
- A miss does not trigger the dramatic confirmation or sound. Damage calculations remain the same as v1.12.

## Deterministic spectral cosmetic affixes

Each sword / scythe / halberd / wand can roll independent `motif`, `effect color`, and `wand cast form` cosmetics. Separate RNG seeds ensure that existing item damage / quality / sockets / stats / existing material palette rolls are unchanged. These cosmetic rolls persist in the existing inventory JSON file; pre-v1.13 saves use deterministic fallback rolls.

- 10 effect motifs: Rose Dust, Moon Sparks, Frost Motes, Vesper Cinders, Lace Shimmer, Thorn Halo, Astral Petals, Silver Runes, Aurora Ghostfire, Eclipse Shards.
- 10 independently rolled effect colors (Rose Quartz, Ice Blue, Moon Pearl, Violet Specter, Sea Glass, Old Gold, Blood Rose, Silver Smoke, Amethyst Flame, Drowned Teal).
- 7 wand cast forms: Moon Orb, Comet, Twin Wisps, Orbiting Sigil, Triune Stars, Moonlight Beam, Prismatic Lattice.
- Rare items can roll the first six wand cast forms. Prismatic Lattice is reserved for set / unique quality. Similarly, rare motifs are gated behind higher-quality loot. Visual richness intensifies with rarity, but does **not** add damage, speed, or extra hit events.
- Item tooltips describe the new visible cosmetic properties; equipped scythe / halberd and wand have subtle seed-colored idle glimmers.

## Wand collision and fairness

- The fading beam resolves a **single**, wall-clipped swept collision query at cast time. It fades over ~0.36s, without repeated damage ticks.
- Twin Wisps and Triune Stars are coordinated *visual formations*, sharing the original projectile hitbox and doing one normal attack's damage.
- Crates (collision layer 4) and walls (layer 2) stop projectiles; a crate takes the impact damage through its existing `receive_damage` function.
- The underlying wand, stamina, affix and combat stats are unchanged.

## Playtest checklist

1. Equip a wand and press left/right mouse (or X) repeatedly; verify orb/comet forms on lower tiers and beam / prismatic only for eligible rare-quality items.
2. In combat, dodge a telegraphed attack; verify `COUNTER READY`, strike during 0.62s, and verify the dramatic `RIPOSTE!` burst and distinct bell sound. A whiff must not play the impact cue.
3. Equip scythe/halberd and check idle glimmer follows weapon-tip animation; hit enemies and check different seed-colors and motifs.
4. Save, reopen, reload; verify every item's cosmetics are unchanged, even older saves.
5. Aim a beam at a wall and at a crate with an enemy behind; verify no damage passes through obstacles.

**Runtime limitation:** The build environment cannot execute the Godot editor or F5 playtests. Static checks, code inspection, ZIP integrity and installation simulation are provided instead. 
