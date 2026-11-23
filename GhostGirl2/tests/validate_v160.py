from pathlib import Path
root = Path('/mnt/data/v160_patch')
checks = {
    'scripts/weapon_prestige_fx.gd': ['align hold-glows', 'Vector2(-23, -5)', 'var head: Vector2 = grip.lerp(tip, 0.94)'],
    'scripts/equipment_visuals.gd': ['dedicated wand-hand overlay', 'wand_visual.show()', 'wand_visual.scale = Vector2(0.11, 0.11)'],
    'scripts/inventory_grid.gd': ['func _display_icon', 'item.visual_signature() not in [4, 5]'],
    'scripts/equipment_panel.gd': ['func _display_icon', 'button.icon = _display_icon(item)'],
}
for fn, reqs in checks.items():
    txt = (root/fn).read_text(encoding='utf-8')
    missing = [r for r in reqs if r not in txt]
    if missing:
        raise SystemExit(f'{fn} missing {missing}')
if not (root/'assets/equipment/wand_hand_overlay.png').exists():
    raise SystemExit('wand overlay asset missing')
print('v1.60 validation passed')
