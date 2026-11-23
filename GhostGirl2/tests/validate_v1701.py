from pathlib import Path
p = Path('/mnt/data/v1701_patch/scripts/weapon_prestige_fx.gd')
t = p.read_text()
checks = [
    'v1.70.1: family-specific secondary illumination',
    'elif style == "dagger":',
    'elif style == "spear":',
    'elif style == "twinblade":',
    'elif style == "maul":',
    'Mythic twinblades',
    'Mythic mauls',
    'Mythic daggers',
    'Mythic spears',
]
for c in checks:
    assert c in t, c
print('v1.70.1 validation passed')
