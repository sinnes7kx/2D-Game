# Ghost Girl v1.9 — Frame-authored weapon overlay upgrade

## Install

Requires the **full v1.8 project** (with v1.5, v1.6 and v1.7 already applied).
Back up your project and your existing saves, then extract the patch at the
folder containing `project.godot`, overwriting matching files. Open `project.godot`
in Godot 4 and let it import new PNGs before pressing F5.

## What changed

- No runtime weapon anchor for the **Rose Reaper scythe** or **Lunar Vigil halberd**.
- All 32 weapon animation tracks use **unchanged Ghost Girl body PNGs** from the
  approved original animation resources (8 frames per track).
- Each weapon receives two independent **RGBA 2048x1760** atlases for each
  animation family (combat and locomotion): `back` and `front`.
- Each pose is authored on the **same 256x220 grid**, with 8 original-order
  frames per row. 256 keyed placements, each split into two planes.
- In `scenes/player.tscn`, `Ghost/WeaponLayers/Back` renders behind the body and
  `Ghost/WeaponLayers/Front` renders in front. Both inherit the exact body
  transform, so bob, leaning, rotation, dodge and hitstop stay synchronized.
- `scripts/weapon_animation_layers.gd` copies body `animation`, `frame` and
  `frame_progress` every render tick. The transparent overlays hide when a
  non-weapon action is playing, avoiding stuck weapons after dodges/hurt/hook.
- Original v1.6 full composite atlases stay in the project for safe reversibility;
  the **body manifest no longer uses those composites** for these two weapons.
- Inventory equipment definitions, combat timing, damage, room scenes, save
  schema, original character PNGs and tint shader are unchanged.

## Re-authoring a frame without editing engine code

Run `python tools/generate_weapon_overlays.py` with Pillow and NumPy installed.
Edit `POSES` at the top of that file. Each row contains eight `(grip_x, grip_y,
head_x, head_y)` pairs measured against the 256x220 body cells; rerunning
regenerates the eight transparent overlay atlases. The master weapon pixels
are isolated from the existing v1.6 painted weapon atlases by subtracting
matching original body frames. The front/back mask is baked when exporting.

You can also replace the exported PNGs with artwork drawn on separate
front/back layers in Aseprite, Krita, Photoshop or other sprite tools, provided
that you keep the original canvas dimensions and frame order. Do NOT need a
runtime `Marker2D` or position offsets for these weapons.

## Known issues / validation

- The original approved **idle/walk** body frames already have the rose-hook
  painted into several poses. That remains visible by her hip, because removing
  it cleanly requires new body artwork; this patch deliberately does not
  inpaint or alter Ghost Girl's approved original character frames.
- Some base *unarmed combat frames* include painted magical slash crescents.
  These remain as combat VFX alongside the weapon, not a second weapon layer.
- The current art is a first per-frame keyed overlay pass, not hand repainted
  bespoke arm poses. Visual cleanup and engine playtesting are still desirable.
- All v1.5–v1.9 static validators pass; no Godot executable was present to
  perform an F5 runtime check in the build environment.
