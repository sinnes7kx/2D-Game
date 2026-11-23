# First-open and feature regression checks

1. Extract the complete ZIP, including `project.godot`, `assets/`, `scenes/`, `scripts/`, `resources/` and `items/`.
2. Godot 4 > Project Manager > Import > select `GhostGirl/project.godot`.
3. Allow asset import to finish; do not attempt to open a `.tscn` from a ZIP viewer or independently without importing the project.
4. F5: the game should begin in Moonwake Crypt with the 2D silver-haired girl, not a new character model.
5. Move in all four directions and check her exact slim/full-length silhouette in both walk and idle animations. Idle blinks should occur occasionally, not constantly.
6. Q: rose hook loose item, F: hook valid scenery or rose anchor. `hook_blocker` nodes should block.
7. E: pick up key/items; G: drop; R: throw, and check impact effect.
8. Tab: backpack. C: equipment. Equipping a wand must not change her body proportions.
9. X: cast when wand is equipped; explore Briar Hollow and Reliquary for RPG loot and sockets.
10. Optional: open `scenes/development/character_animation_preview.tscn` and use F6 to inspect the four canonical walk cycles.
11. In any dependency error window, copy the exact `res://...` paths and error lines from the Godot Output panel.

Do not delete `resources/` or `scripts/`. The `.godot/` folder is an import cache and can be regenerated.
