from pathlib import Path
p = Path('scripts/weapon_prestige_fx.gd')
text = p.read_text(encoding='utf-8')
required = [
    '_draw_wand_hold_cosmetics',
    '_soft_orb',
    'held-wand cosmetics',
    'if item.get_slot() == "wand":',
]
missing = [s for s in required if s not in text]
if missing:
    raise SystemExit('Missing markers: ' + ', '.join(missing))
print('v1.55 validation passed')
