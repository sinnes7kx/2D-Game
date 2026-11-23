"""Ghost Girl v1.25 — static structural and balance checks.
This validates resource wiring and key combat invariants, NOT runtime animation.
"""
from pathlib import Path
import json, re, zipfile
ROOT = Path(__file__).resolve().parents[1]
problems=[]
def check(cond, msg):
    if not cond: problems.append(msg)
def load(name):
    p=ROOT/name
    check(p.is_file(), f'missing {name}')
    return p.read_text(encoding='utf-8') if p.exists() else ''

player=load('scripts/player.gd')
game=load('scripts/game.gd')
wraith=load('scripts/rose_wraith.gd')
hunter=load('scripts/gothic_hunter.gd')
blizzard=load('scripts/moonfall_blizzard.gd')
shrine=load('scripts/moonfall_shrine.gd')
fx=load('scripts/weapon_fx_library.gd')
tooltip=load('scripts/item_rich_text.gd')
scene=load('scenes/rooms/moonwake_crypt.tscn')
project=load('project.godot')
packed=load('scenes/moonfall_blizzard.tscn')

check('moonfall_blizzard={' in project and 'physical_keycode":90' in project, 'Z input mapping missing')
check('func _begin_spell_cast(heavy: bool = false, moonfall: bool = false)' in player, 'spell state not integrated')
check('world.cast_moonfall(spell_aim_point)' in player, 'spell shot does not route to storm')
check('moonfall_cooldown = 6.2' in player and '37.0 if moonfall' in player, 'resource/cooldown handling absent')
check('spell_is_moonfall = false' in player, 'room transition spell reset missing')
check('has_collected("v125_moonfall_unlocked")' in player and 'has_collected("v125_moonfall_unlocked")' in game, 'skill unlock gate missing')
check('inventory.collected_pickups["v125_moonfall_unlocked"] = true' in game and 'inventory.save_game()' in game, 'saved unlock missing')
check('func cast_moonfall(target_position: Vector2)' in game, 'missing spell spawner')
check('MOONFALL_SCENE: PackedScene = preload("res://scenes/moonfall_blizzard.tscn")' in game, 'missing spell scene reference')
check('trace.collision_mask = 6' in game and 'offset.limit_length(570.0)' in game, 'cast does not respect range/cover')
check('MOONFALL_SCENE.instantiate()' in game and 'removed_room_items.append(storm)' in game, 'storm not cleaned up on room change')
check('func _apply_storm_pulse() -> void:' in blizzard and 'var pulse_left: float = 0.22' in blizzard, 'storm ticks missing')
check(blizzard.count('enemy.call("hit", damage_per_pulse, 0.45)') == 1, 'storm duplicates hit events')
check('storm_radius * storm_radius' in blizzard and 'ray.collision_mask = 2' in blizzard, 'storm radius/wall filter missing')
check('enemy.call("apply_frost_slow", slow_duration, slow_multiplier)' in blizzard, 'storm slow missing')
check('queue_free()' in blizzard, 'storm leak risk')
for code, name in [(wraith, 'wraith'), (hunter,'hunter')]:
    check('func apply_frost_slow(seconds: float, speed_factor: float) -> void:' in code, f'{name} cannot be slowed')
    check('frost_slow_left = maxf(0.0, frost_slow_left - delta)' in code, f'{name} slow does not expire')
    check('frost_speed_factor = 1.0' in code, f'{name} slow never resets')
check('0.72 if is_elite' in hunter, 'elite slow guard missing')
check('func moonfall_style(seed_value: int, quality: String) -> int:' in fx and 'tier_value <= 1' in fx, 'quality gating missing')
check('MOONFALL  %s  ·  VISUAL IMPRINT' in tooltip, 'item tooltip cosmetic trait missing')
check('v125_shrine' in scene and 'name="MoonfallReliquary"' in scene, 'learnable shrine not placed')
check('func restore_from_inventory(inv: Node) -> void:' in shrine, 'shrine persistence missing')
check('res://scripts/moonfall_blizzard.gd' in packed, 'storm scene script reference missing')

# Validate the new tscn formats: resource ids unique, all referenced resources exist.
for relative in ('scenes/moonfall_blizzard.tscn','scenes/rooms/moonwake_crypt.tscn'):
    contents=load(relative)
    resources=re.findall(r'^\[ext_resource[^\]]*path="res://([^"]+)"[^\]]*id="([^"]+)"[^\]]*\]$', contents, re.M)
    ids=[id for path,id in resources]
    check(len(ids)==len(set(ids)),f'{relative}: duplicate resource ID')
    for path, _ in resources:
        check((ROOT/path).exists(),f'{relative}: missing {path}')
    check(not re.search(r'^\s*#\s+', contents, re.M),f'{relative}: invalid # comment in tscn')

result={'version':'1.25','status':'PASS' if not problems else 'FAIL','moonfall_timing':{'duration':4.2,'pulse_seconds':0.70,'start_pulse':0.22,'cooldown':6.2},'skill_unlock':'v125_moonfall_unlocked','spells_damage_projectiles_created':0,'issues':problems}
print(json.dumps(result, indent=2))
if problems: raise SystemExit(1)
