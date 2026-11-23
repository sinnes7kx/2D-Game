from pathlib import Path
root = Path('/mnt/data/v165_work')
checks = {
 'scripts/bow_palette_overlay_v139.gd': ['func _carry_offset_for_animation', 'position = _carry_offset_for_animation', 'glow_power = 0.22'],
 'scripts/weapon_prestige_fx.gd': ['visible_glow_strength: float = 1.95', 'if visual_signature_level >= 4:', 'Bow mythic: unmistakably brighter'],
 'scripts/inventory.gd': ['SPECIAL_JEWEL_MALADY', 'func _resolve_socketable_loot_template', 'posmod(seed_value, 29) != 0'],
 'items/malady_jewel.tres': ['display_name = "Malady"'],
 'items/delirium_jewel.tres': ['display_name = "Delirium"'],
 'items/exile_jewel.tres': ['display_name = "Exile"'],
}
for rel, reqs in checks.items():
    txt = (root/rel).read_text()
    for r in reqs:
        if r not in txt:
            raise SystemExit(f'Missing {r} in {rel}')
print('v1.65 validation passed')
