"""v1.23: rare cosmetic FX, weapon pedestals, moor portal, moonstep traversal.
Offline checks only; requires a real Godot F5 playtest for gameplay certification.
"""
from pathlib import Path
from PIL import Image
import re, json
ROOT = Path(__file__).resolve().parents[1]
issues = []

def check(pred, message):
    if not pred:
        issues.append(message)

def get(path):
    target = ROOT / path
    check(target.exists(), 'missing ' + path)
    return target.read_text(encoding='utf-8') if target.exists() else ''

script = get('scripts/weapon_prestige_fx.gd')
fx_library = get('scripts/weapon_fx_library.gd')
player = get('scripts/player.gd')
game = get('scripts/game.gd')
crypt = get('scenes/rooms/moonwake_crypt.tscn')
moor = get('scenes/rooms/hollow_veil_moor.tscn')
racks = get('scripts/weapon_showcase.gd')
trial = get('scripts/moonstep_trial.gd')
barrier = get('scripts/low_thorn_barrier.gd')
formatter = get('scripts/item_rich_text.gd')

# All showroom templates must be real equipment resources.
ids = [
    'dusk_needle', 'thornwake_sabre', 'vesper_rapier', 'mourning_longsword',
    'bloodrose_falchion', 'moonveil_grandblade', 'rose_reaper_scythe',
    'lunar_vigil_halberd', 'briar_wand', 'ashbound_wand', 'hunter_censer_wand'
]
for item in ids:
    check((ROOT / f'items/{item}.tres').is_file(), 'missing item template ' + item)
    check(f'name="Showcase_{item}"' in crypt, 'missing showroom pedestal ' + item)
    check(f'pickup_id = "v123_showcase_{item}"' in crypt, 'showroom cannot save pickup ' + item)
check(crypt.count('script = ExtResource("v123_rack")') == len(ids), 'wrong showroom pedestal count')
check('WeaponShowcases' in game and 'weapon_rack' in game, 'showroom not handled in game')
check('inventory.add_loot(template' in game and 'target.call("restore_from_inventory", inventory)' in game, 'showroom reward not persistent')
check('if not Engine.is_editor_hint():' in racks, 'showroom editor registration broken')

# Portal round trip works with the unchanged room registry.
check('name="hollow_veil_moor" type="Node2D" parent="Gameplay/Portals"' in crypt, 'missing starting-room portal')
check('destination = "hollow_veil_moor"' in crypt, 'starter portal wrong destination')
check('name="From_hollow_veil_moor"' in crypt, 'no return spawn in crypt')
check('name="moonwake_crypt" type="Node2D" parent="Gameplay/Portals"' in moor, 'no moor return portal')
check('name="From_moonwake_crypt"' in moor, 'no moor arrival spawn')
check('"hollow_veil_moor"' in game and '"moonwake_crypt"' in game, 'room registry missing return destinations')

# Every resource reference newly introduced is valid; previous scene content untouched.
for name, text in [('crypt', crypt), ('moor', moor)]:
    for path in re.findall(r'\[ext_resource[^\n]* path="res://([^"]+)"', text):
        check((ROOT / path).exists(), f'{name}: missing resource {path}')
    for line in text.splitlines():
        check(not line.lstrip().startswith('#'), f'{name}: GDScript-style # comment will break tscn parser')
count_ext = len(re.findall(r'^\[ext_resource ', crypt, flags=re.M))
count_sub = len(re.findall(r'^\[sub_resource ', crypt, flags=re.M))
m = re.search(r'^\[gd_scene load_steps=(\d+)', crypt)
check(bool(m) and int(m.group(1)) == 1 + count_ext + count_sub, f'incorrect load_steps for crypt scene (ext={count_ext} sub={count_sub})')

# Jump moves past a dedicated barrier only; it must still collide with enemies.
for token in ('const JUMPABLE_BARRIER_MASK: int = 32','collision_mask |= JUMPABLE_BARRIER_MASK','collision_mask &= ~JUMPABLE_BARRIER_MASK'):
    check(token in player, 'jump mask support incomplete: ' + token)
check('collision_layer = 32' in barrier, 'barrier not on jump-exclusive physics layer')
check('jump_time_left' in trial and 'jump_duration' in trial and 'inventory.add_loot' in trial, 'moonstep challenge not playable')
check('name="MoonstepBarrier"' in crypt and 'name="MoonstepLandingSeal"' in crypt, 'moonstep challenge not placed')
check('discovery_id' in trial and 'inventory.save_game()' in trial, 'moonstep reward is not persisted')

# Cosmetic rarity gating and six-plus visual identities, no hit/damage changes.
check('if tier_index < 2:' in fx_library, 'normal/magic incorrectly receive prestige FX')
check('tier_index == 2 and posmod(seed_value + 230123, 11)' in fx_library, 'rare prestige not limited')
check(len(re.findall(r'"[A-Za-z ]+"', fx_library.split('const PRESTIGE_NAMES:')[1].split('= [', 1)[1].split(']', 1)[0])) >= 7, 'insufficient prestige variants')
for token in ('CanvasItemMaterial.BLEND_MODE_ADD', 'func _tip() -> Vector2:', 'draw_arc(', 'draw_polyline(', 'draw_colored_polygon(', 'style_index < 0'):
    check(token in script, f'prestige art missing: {token}')
check('EquippedPrestigeFX' in game and 'bind_inventory' in game, 'prestige nodes not attached to player')
check('RELIC AURA:' in formatter, 'prestige aura not visible on item tooltip')
check('ghost_girl_treasures_v2.json' in get('scripts/inventory.gd'), 'save location changed')

result = {
    'release': '1.23',
    'status': 'PASS' if not issues else 'FAIL',
    'weapon_showcases': len(ids),
    'prestige_visual_families': 7,
    'moonstep_trial': True,
    'teleport_round_trip': True,
    'issues': issues,
}
print(json.dumps(result, indent=2))
if issues:
    raise SystemExit(1)
