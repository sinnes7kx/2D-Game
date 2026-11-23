# Ghost Girl v1.43 — Moonthread & Quiet Weapon Alignment

This is an incremental patch **for v1.42**. It replaces no original player
artwork, baked weapon atlases, item statistics, loot tables or save files.

## Precise scythe and halberd prestige highlights

- Derived 256 per-frame glow axes (32 tracks, eight frames each) from the
  *weapon-only* front/back v1.12 overlays already used to author the baked
  scythe and halberd sprites. No new body art or weapon attachments.
- The equipped prestige FX follows the actual rendered shaft through idle,
  walking, light and heavy attack frames in all four directions.
- If an animation has no trustworthy guide, the effect is suppressed, not
  drawn at an unrelated hand position. Bow glows also require their frame guide.
- New `effect_intensity` export in the renderer defaults to `0.72`. The glow
  remains subdued, shaft-aligned, and cosmetic-only.
- Avoids drawing a second wand shimmer when its prestige renderer already
  supplies the glow. This prevents a double/offset effect.

## Moonthread Waylights

- Added two editable hanging waylights in Hollow Veil Moor beside existing
  v1.40 hidden moonmarks: a western light near (2350, 4880), and a central
  light near (4370, 2530).
- Strike one with a Luminous arrow **or** pull it with the rose-hook to reveal
  nearby hidden moonmarks. Existing hidden-relic save flags remain authoritative.
- The lamps are reusable and do not cause damage or grant additional loot.
- A waystone hints at the alternative puzzle solution. The visual is a thin
  antique lantern glow, not a floating magic circle.

## Validation and limitations

Run `python tests/validate_v143.py` from the project root to verify source
resources, exact guides and scene references. The v1.32, v1.40, v1.41 and
v1.42 static checks were also run. No Godot executable was available here;
**F5 engine testing remains necessary** to verify effect alignment during
blending, gameplay flow and hook target visibility.
