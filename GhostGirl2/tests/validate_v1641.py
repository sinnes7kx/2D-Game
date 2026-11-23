from pathlib import Path
root = Path('/mnt/data/v1641_package/scripts')
checks = {
    'equipment_visuals.gd': ['aura_alpha_mul', 'dress_signature == 4', 'Mythic Radiance dress'],
    'weapon_prestige_fx.gd': ['white-hot laser core', 'traveling glints', 'draw_line(start, endp, Color(1.0, 0.99, 0.99, 0.68 * strength), 1.55, true)'],
}
for fn, reqs in checks.items():
    txt = (root/fn).read_text(encoding='utf-8')
    missing = [r for r in reqs if r not in txt]
    if missing:
        raise SystemExit(f'{fn} missing {missing}')
print('v1.64.1 validation passed')
