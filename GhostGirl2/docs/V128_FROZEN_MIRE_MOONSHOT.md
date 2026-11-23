# Ghost Girl v1.28 — Frozen Mire & Moonshot

**Incremental patch for v1.27.** Place the contents directly in the project directory that contains `project.godot`, overwriting matching files. Keep your save backup.

## New environmental mechanics

**Frozen water:** Learn Moonfall in Moonwake Crypt, equip a wand, then press **Z** and aim at a pond in Hollow Veil Moor. The part of the water touched by the spell develops pale ice rings for about 5 seconds. Ordinary shallow water/mire slows grounded walking, while the frozen section provides normal footing until it thaws. Existing fishing metadata and water polygons are not changed.

**Bloom relays:** Learn Grasping Roses and press **T** at the dormant rose relays beside the western mire and Moonlit Basin. The vines wake a one-time seal and unlock a rare treasure chest. Both discoveries persist in the existing save format.

**Moonshot archery:** Equip a bow. At Lantern Steps or Moonlight Crossing, press **C** to jump, then use a **charged shot (right click)** at the glowing moon target beyond the route. The target only activates for a charged arrow released in the air; it uses the existing single arrow's swept path and awards no additional damage. Two rare bow rewards are saved permanently.

## Compatibility and validation

- Four new optional reward chests (two bloom relays, two bow targets).
- New relays and targets are editable scene nodes, not painted into the background.
- No alterations to approved character art, weapon atlases, background or loot odds.
- Original persistent flags and save-file location are preserved.
- The v1.25, v1.26, v1.27 and v1.28 offline validators pass.
- The patch has **not** been tested with Godot F5 in this environment. Verify collision alignment, line of sight and the feel of water movement in the editor.
