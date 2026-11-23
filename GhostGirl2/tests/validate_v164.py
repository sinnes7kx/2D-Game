from pathlib import Path
root = Path('/mnt/data/v164_package/scripts')
checks = {
    'equipment_visuals.gd': ['ambient_particle_sources', '_draw_firefly_cluster', '_rebuild_ambient_sources'],
    'weapon_prestige_fx.gd': ['_draw_ambient_fireflies', 'subtle rarity ambience', 'if rarity_tier < 2 and visual_signature_level <= 0'],
}
for fn, reqs in checks.items():
    txt = (root/fn).read_text(encoding='utf-8')
    missing = [r for r in reqs if r not in txt]
    if missing:
        raise SystemExit(f'{fn} missing {missing}')
print('v1.64 validation passed')
