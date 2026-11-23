GHOST GIRL v1.40 — CUMULATIVE DEPENDENCY + PROCEDURAL PALETTE REPAIR

This fixes project installations with missing scripts/items after applying only some of v1.25-v1.40.
For an existing v1.24-or-later project, merge the archive's contents into the folder containing project.godot.
Keep the existing project, assets and saves, but BACK UP your project before overwriting. This patch does not include a new savegame.

It includes the full changed/new-file chain from v1.25 through v1.40, not just the most recent small patch.
It specifically restores scripts/procedural_relic_palette_v139.gd and other dependencies from v1.33 through v1.39
(bellglass, Vesper, collapse supports, chains, bow imprints and elemental effects).
It explicitly preloads the procedural palette in bow_arrow_v126.gd, item_instance.gd and weapon_prestige_fx.gd,
so the renderer no longer relies entirely on Godot's global class_name scan.

After copying, in Godot use Project > Reload Current Project (or close and reopen) to rebuild resource/class registration.
Then open scenes/rooms/hollow_veil_moor.tscn.

This package was ZIP integrity and static dependency checked but NOT run in Godot.
If errors remain, send the exact first parser error, not only the total error count.
