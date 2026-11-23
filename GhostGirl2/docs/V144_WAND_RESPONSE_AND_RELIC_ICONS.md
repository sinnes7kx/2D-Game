# Ghost Girl v1.4.4 — Moonlit Precision

- Wand aiming now originates from the muzzle and snaps only if the pointer is within 72 world pixels of an enemy body.
- New SpellHurtbox areas on hunters and wraiths cover painted torsos. The existing feet collision shapes remain unchanged for movement.
- Projectile uses a swept-circle test, with stone walls checked first. Charged shots have a larger radius.
- Confirmed wand hits trigger sound/camera feedback. Acceleration and turning are tighter, with short melee attack steps.
- Original user-supplied equipment illustration cards are sliced into 24 new icon textures (16 relics + 8 weapons) and assigned to existing item templates.
- Item palette rolls remain compatible with old saves. Swords and wands now have a separate six-color spectral palette and item swatch markers.
- Ghost Girl sprite shader selectively dyes violet weapon magic rather than tinting her skin/hair/dress.

## Installation
Close Godot. Extract the patch into the parent folder containing `GhostGirl_Act1_RPGDraft` and merge. Back up save data. Reopen project.godot; let the editor import all textures. Playtest wand shots from all four directions with/without lock-on, near walls, and against each enemy archetype.

## Limitations
Godot runtime is unavailable in the build environment. Test sprite-color masks in-game; the weapon palette shader currently targets spectral weapon highlights and does not guarantee full per-pixel blade recoloring in every hand-painted frame. Palette-specific separated weapon-layer art will improve this later.
