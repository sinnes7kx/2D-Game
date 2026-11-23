# Ghost Girl — master project (v0.1)

This ZIP is the new **single main project**. Extract `GhostGirl/` to one permanent folder and import `GhostGirl/project.godot` in Godot 4.

## Where it came from
- Complete scene/code foundation: the latest previous **Act I Gothic RPG Loot / Sockets / Wand Draft**.
- `WORKING.zip` provided this turn: **not a complete Godot project**. It contains one animation sheet and 16 previously shipped hook/impact effect sprites. They were verified and included.
- Canonical player sprite source: `art_sources/GhostGirl_Walk_Idle_Hook_8x8_256x220.png` from the attached image. These exact character drawings are used for all on-screen body poses.

## Character proportions and animations
- The canonical image is 2048x1760 pixels, divided into 8 columns x 8 rows.
- Native frames are **256x220 RGBA**. Every frame is cropped at its exact grid boundary. **No resizing, stretching, mirroring, recentering or redrawing** is performed.
- First four rows are walk/movement (back, front, left, right), second four rows are idle (back, front, left, right).
- `resources/ghost_girl_frames.tres` now supplies idle, walk, sporadic blink, hook, hook_hold, throw, wand_idle, wand_walk, wand_cast for all four directions. The new hook/throw/cast states reuse different poses from the single authorized image rather than introducing incompatible character art.
- With a wand equipped, a small **separate wand prop layer** appears near her hand. The underlying character artwork NEVER switches to the older, differently proportioned wand sheets.
- The procedural idle/gesture scale is uniform on X and Y, avoiding stretching her body.
- Preview the source-backed animations using `scenes/development/character_animation_preview.tscn`, Run Current Scene (F6).

## Core systems preserved
- Rose hook: **Q** pull objects, **F** pull toward architecture, nominal **450 px** plus equipment modifiers, `hook_blocker` group, dedicated hook projectile/effects.
- Interactions: **E**; object drop **G**, mouse-aimed throw **R**.
- Backpack **Tab** and equipment **C**, seeded item qualities/affixes and sockets, rare loot and wand casting **X**.
- Existing fifteen editor-authored rooms, world transitions, exploration routes and the Moonwake Crypt intro. No dialogue.

## How to use one folder forever
1. Keep one permanent `GhostGirl/` folder on your computer.
2. Make a ZIP backup or Git commit before applying any future patch.
3. Future updates should patch this folder rather than replacing the root project.
4. Don't overwrite hand-edited scenes blindly; merge changes to scripts/scenes when necessary.
5. Do not manually copy `WORKING.zip` over the project: it is only character/VFX assets.
6. Godot regenerates `.godot/` cache on first open, so allow imports to complete before playing F5.

**Save compatibility:** To avoid changing the `user://` save location, the Godot `config/name` setting has been retained from the prior RPG draft; the directory is named `GhostGirl`. Do not rename the Godot config/name until save migration is implemented.

**Validation:** Resource references and archive integrity are checked. This environment has no Godot executable, so a live engine F5 run could not be confirmed. Use `docs/FIRST_OPEN_CHECKLIST.md` and report the exact error path/line if Godot flags a problem.
