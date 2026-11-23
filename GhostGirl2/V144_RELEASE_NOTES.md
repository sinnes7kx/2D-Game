# Ghost Girl v1.44 — Moonroot Causeways

**Incremental patch for v1.43**. Extract into the directory containing `project.godot`. It does not replace the approved character sprites, moor painting, item statistics, or save files.

## New exploration gameplay

In Hollow Veil Moor, visit the **Fallen Watchroot** in the western-central moor (around x=3000, y=4400). Two narrow wooden barriers block an optional route. Open the first by pulling it with the rose-hook, igniting it with a fire arrow or nearby burning object, using Grasping Roses, striking it with a fully charged airborne arrow, or smashing it with a thrown heavy object. The neighboring barrier can collapse in the chain reaction. A rare scythe cache lies nearby.

Visit the **Frostbound Lattice** in the eastern moor (around x=7400, y=4850). Freeze the joint using Moonfall or a frost arrow, **then** pull it with the rose-hook. Its frozen state and cleared passage are saved separately. A hidden moonmark beyond it responds to a light arrow or another light-reveal interaction and reveals a rare wand cache.

Both encounters use real `StaticBody2D` collision nodes with editable `CollisionShape2D` children. The barriers cease blocking movement after opening and restore their open state after re-entering the room. Collapses apply one restrained damage/interrupt event to nearby enemies, never damage every frame. No additional mandatory gates or enemy spawns were added to the moor.

## Weapon visual refinement

- Rare sword glints use the moving hand marker with a **shorter** axial highlight, only during sword animations.
- Wand glints appear only during active spellcasting, following the hand rather than hovering over Ghost Girl's face during idle.
- Bows and long weapons retain their existing per-frame guide data. No additional circular effects were added.
- These are conservative geometric corrections, not hand-redrawn sprites or full pixel-precise sword/wand guides.

## Testing

`python tests/validate_v144.py` checks new callback integrations, unique scene IDs, real collision nodes, saved flags and optional rewards. The v1.41, v1.42 and v1.43 regression validators also pass after recovering the original reference artwork and dependencies from the supplied archives. **Godot F5 runtime validation was not available**; please check the three mechanisms and editor import in your project.
