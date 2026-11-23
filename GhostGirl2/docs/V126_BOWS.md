# Ghost Girl v1.26 — Thornrose & Moonveil Bows

## Install
Apply to the **complete v1.25 project**, not to a standalone patch folder. Extract
this archive into the folder containing `project.godot`; replace matching files.
Existing saves and equipment slot IDs are unchanged.

## In game
- In Moonwake Crypt, find the **Thornrose Bow** and **Moonveil Bow** pedestals on
  the east side of the existing weapon gallery.
- Collect one with **E**, open inventory (**I**), equip it in the existing weapon
  slot. Unequip your wand if you want bow attacks to take precedence in other UI.
- **Left click**: quick arrow. **Right click**: slower charged arrow. Charged
  arrows can hit up to two *different* enemies, once each; walls and crates stop them.
- **C + attack while airborne**: jump shot. Only one jump shot per leap.
- Bows may also occur among future enemy weapon drops.
- Bow/projectile colors derive from the item's saved seed and quality. Special
  rare wisps are **cosmetic**; they do not create extra hitboxes or extra damage.

## Art
- Two 2048×1760 locomotion atlases (one per bow), and two matching attack atlases.
- 8 rows x 8 frames, each cell 256×220. No external weapon attachment required.
- Generated from existing approved Ghost Girl body frames; those originals are
  untouched. Direction-specific grip artwork is a first pass and should be visually
  verified in the Godot editor, particularly shooting and jump poses.

## Limitations
The static validator and v1.24/v1.25 regression tests pass. **No Godot runtime
F5 playtest** was possible in this environment. Charged bows and jump shooting
are therefore development features subject to in-engine timing and collision checks.
