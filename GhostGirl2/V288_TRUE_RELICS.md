# v2.88 — True Relic Abilities

Eight existing unique weapons have new mechanics instead of shared spectral projectiles. Existing IDs, random stats, cosmetic seeds and discovery flags are unchanged.

- Rosemirror Twinblade: Shift + Mouse2 to start; keep Mouse2 held while walking. Both physical blades rotate, with swept angular contacts and a per-target hit interval. 5 stamina to start, 17/s base drain, 74% walking speed.
- Cathedral Thorn Twinblade: same activation, but an expanding mobile cyclone with five visual wind layers, repeated area hits, 25/s base drain and 92% walking speed. Builds over 0.85 s.
- Briarwake Trident: six sequential ground spears, obstruction checks and one hit per enemy per cast.
- Ossuary Poleaxe: four timed ground fissures.
- Gallows Greataxe: one expanding impact ring, not multiple projectile arcs.
- Frostveil Bow: full special draw and release summons aimed Moonfall Blizzard.
- Lunar Vigil Halberd: aimed Astral Rain.
- Rosehook Bearded Axe: aimed Grasping Roses.

The former learned wand area spell shortcuts no longer cast those spells; normal wand attacks remain available. Relic inscriptions preserve previously saved flags. The three area spells require their matching equipped unique weapon and have 6.2, 7.8 and 7.1 second cooldowns. Both channels stop on release, empty stamina, taking damage, dodge, menu opening or action reset. Normal twinblade heavy attacks remain unchanged.

This is the first bespoke conversion pass, not a conversion of every unique. No new save schema. Godot runtime not tested.

Smoke: godot --headless --path GhostGirl2 --script res://tests/v288_true_relics_smoke.gd

Manual QA: equip each unique, test Shift + Mouse2, all directions, move while channeling, release and exhaust stamina, interrupt by enemy hit, open inventory, swap weapons, travel and die. Test that Z/V/T and legacy area calls with a wand cannot spawn area magic. Check obstruction and arena behavior, and whether old puzzles still have suitable access to frost effects. Verify graphics and balance in-engine.
