# Ghost Girl v1.11 — Moonrose Materials

## Art and alignment

This patch fixes a proven source of weapon cropping in the v1.9 overlays:
several halberd light-combat frames were rasterized against the boundary of a
256×220 cell. `tools/build_safe_weapon_atlases_v111.py` re-renders all 256
authored poses in a larger temporary space and reduces the weapon size around
the grip only when required to retain a four-pixel safety margin. Minimum
scale was 0.82. Both transparent planes have retained alignment; eight
2048×1760 PNG atlases replace paths in `resources/weapon_layer_manifest.json`.

The v1.10 hook-free idle/walk body art is repacked into a single 2048×1760
`weapon_ready_locomotion` atlas and 19 remaining highly saturated magenta
flecks are erased in the old hook's location. All 64 frames are checked; the
head/hair area remains identical to v1.10. Both scythe and halberd animation
tracks load that exact atlas, not a mix of original and clean frames.

The fully padded preview/contact sheets in `docs/v111_previews/` show only
rendered v1.11 frames, not an original/edited comparison that might still
show the old original rose hook.

## Four cosmetic channels per weapon item

1. Existing `palette_index` becomes `weapon_base_index` for color (6 types).
2. `weapon_gradient_index`: gradient color/treatment (6 types).
3. `weapon_detail_a_index`: grain/mineral surface pattern (4 types).
4. `weapon_detail_b_index`: ornamental surface treatment (4 types).

Total combinations: **6 × 6 × 4 × 4 = 576 per weapon silhouette**.
Independent RNG streams use separate seed offsets so item affixes, damage,
rarity and socket rolls are unchanged. The four keys are saved explicitly in
the existing JSON save file; when loading an old save, missing appearance keys
are recomputed from the item's seed. Existing `palette_index` is not removed.

`weapon_surface_v111.gdshader` uses original weapon RGB art to preserve
lighting and detail while applying base color, a position-dependent gradient,
and two tiled monochrome surface overlays derived from the four-panel gothic
texture master. Each equipment layer uses its own material so Ghost Girl's
cloth tint shader does not recolor the weapon. Both front/back layers use the
same item parameters. `Ghost/WeaponLayers.bind_inventory()` refreshes them
when equipment changes.

The inventory tile gains two enamel swatches and material lines appear in the
hover tooltip and `GhostItemInstance.details()`. Existing equipment save IDs,
item stats, world rooms, combat timing and loot tables are not changed.

## Known remaining work

No Godot executable was available for runtime shader testing or in-editor F5
verification. The original painted dagger still appears in the separate dodge
animations, and some inherited heavy-attack *body* frames have top-cut head
silhouettes from earlier source art. These were not redrawn here.

## Validation

`python tests/validate_v111.py` verifies 64 approved body atlas cells, no
remaining saturated rose hook in the old hook location, the 32 mapped overlay
tracks, all eight 8×8 2048×1760 transparent weapon atlases, 512 depth frames
with four-pixel border clearance, and four item roll/persistence channels.
Legacy validators v1.5–v1.10 were updated only where the new atlas format
intentionally supersedes their old file-path expectations.
