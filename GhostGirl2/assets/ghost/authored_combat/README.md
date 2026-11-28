# Dedicated combat artwork

This folder is deliberately empty of substitute PNGs. The current game uses staged body poses until approved dedicated artwork is supplied.

## Layout

- Transparent RGBA PNG: exactly 2048 × 1760.
- 8 columns × 8 rows; each frame exactly 256 × 220.
- Row numbering starts at zero; columns 0–7 are the action sequence.
- Keep the original Ghost Girl design, scale, baseline, facing and body silhouette.
- Paint the body without baked equipment for modular weapons. Weapon geometry, colors and effects are rendered separately.
- No mirrored character art as a replacement for a direction.

Register a row in `resources/authored_combat_atlases.json` using version 1. Each row has an exact existing modular attack clip or family parry clip, a PNG path under this directory, row index, near_hand (0=left slot, 1=right slot), and 8 left and 8 right wrist coordinates. Coordinates are full-cell pixels (not cropped sprite bounds); [] means hidden wrist. The near_hand value is constant for a row; never swap paired weapon identities across frames.

Example (illustrative coordinates only, not a finished pose or file):

```json
{
  "atlas": "res://assets/ghost/authored_combat/parry_body.png",
  "clip": "sword_modular_parry_front_right",
  "row": 0,
  "near_hand": 1,
  "left": [[], [], [], [], [], [], [], []],
  "right": [[125,139],[123,134],[121,123],[120,120],[120,120],[121,123],[123,134],[125,139]]
}
```

The importer preserves the original clip's total weighted timing and applies the same per-frame wrist guides to the weapon and its visual effects. Missing or invalid rows keep their fallback. For parry, the physics state controls frame selection and existing contact/counter timing. The authored guard audit and existing combat audit remain separate from fallback presence.

Before merging actual art, inspect every cell and validate all eight facings, paired-hand occlusion, guard recovery, bow charge/release, and inventory preview in Godot. Do not register illustrative coordinate data as production artwork.
