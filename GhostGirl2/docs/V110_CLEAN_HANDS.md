# Ghost Girl v1.10 — Clean Hands (incremental patch for v1.9)

This patch continues the frame-aligned **scythe and halberd** animation system.
It changes only the optional body-animation manifest and adds derived transparent
body frames. **The eight v1.9 front/back weapon overlays are unchanged**, as are
all original canonical Ghost Girl images, inventory equipment, gameplay values,
rooms, player scene, and the existing save format.

## What's improved

- **No duplicate rose-hook** while the scythe or halberd is idle or walking.
  64 separate body frames were exported from the approved character sprites with
  the permanently painted rose-hook removed. The source PNGs are untouched; it
  still appears in Ghost Girl's intentional hook launch/pull animations.
- **No painted magical crescent competing with a weapon** at the hit frame in
  the new two-handed combat animations. The approved follow-through body pose
  is repeated once at frame 4 instead of cutting the magic slash out of her
  hands and hair (which produced destructive clipping in an early test).
- **Heavy attack floor artifacts removed** in 32 standalone body frames by
  excluding detached non-character paint.
- **Fully reversible**, with no edits to original body frames and no altered
  save data, item definitions, physics, or player controls.

## Install

1. **Requires Ghost Girl v1.9** already installed and working. Back up the
   project folder and its saves before installing.
2. Extract this ZIP into the **folder containing `project.godot`** and allow
   `resources/ghost_extra_animations.json` to be replaced.
3. Open `project.godot` in Godot 4 and let the new PNGs import. Press **F5**.
4. Press F7 to get the trial scythe and halberd, open inventory (**I**), equip
   each, then inspect idle, walking and both attack weights in all directions.
   Unequip or use the rose hook to verify that regular and hook animations
   still use their original artwork.

## Known limits

- The impact frame now uses a neighboring unmodified Ghost Girl pose, which
  produces a brief one-frame hold in the attack sequence. It is safer than
  cutting important body pixels out of the image. Bespoke repainted weapon-grip
  frames would be the best future improvement.
- The existing dodge animations have a small baked-in original dagger. We have
  **not** layered the new weapons onto dodge yet, because that would create a
  double-weapon artifact. Dedicated weapon-ready dodge art is still needed.
- No Godot executable was available for an in-engine F5 playtest. Static
  validators can confirm paths, frame geometry, and compatibility, but not
  how the animation looks or feels in a running game.

## Local checks

Run `python tests/validate_v110.py` and, if desired, all previous validation
suites `tests/validate_v15.py` through `tests/validate_v19.py`.
