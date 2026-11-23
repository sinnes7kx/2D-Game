from pathlib import Path
root = Path('/mnt/data/gg_v167_patch/scripts')
checks = {
 'bow_palette_overlay_v139.gd':['func _carry_transform_for_animation', 'rotation_degrees', 'rotation_deg'],
 'inventory_grid.gd':['Keep the real icon in inventory slots'],
 'equipment_panel.gd':['Keep the authored icon intact in equipment slots'],
 'weapon_prestige_fx.gd':['func _draw_mythic_seed_variant', 'Lightning sparks', 'Wisps / petal drift', 'square-ended'],
 'equipment_visuals.gd':['Recast the old wings slot as a delicate tiara/headpiece', 'Vector2(0, -76)'],
}
for rel, reqs in checks.items():
 txt=(root/rel).read_text()
 for r in reqs:
  assert r in txt, f'missing {r} in {rel}'
print('v1.67 validation passed')
