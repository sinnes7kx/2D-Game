#!/usr/bin/env python3
"""v1.49 offline content/integration validation; not a Godot engine runtime test."""
from pathlib import Path
import re, sys
P=Path(__file__).resolve().parents[1]
checks=[]
def ck(label, value): checks.append((label,bool(value)))
def src(name):
    path=P/'scripts'/name
    ck('exists '+name,path.is_file())
    return path.read_text() if path.exists() else ''
sp=src('impact_spawner_v149.gd')
fx=src('impact_burst_v149.gd')
pool=src('blood_pool_v149.gd')
player=src('player.gd')
hunter=src('gothic_hunter.gd')
warden=src('moor_warden_v132.gd')
cover=src('breakable_cover_v136.gd')
support=src('collapse_support_v135.gd')
debris=src('falling_debris_v135.gd')
crate=src('carryable.gd')
lattice=src('moonroot_lattice_v144.gd')
for token in ['MAX_BURSTS: int = 26','MAX_POOLS: int = 24','func burst(', 'func pool(', 'func rumble(', 'existing[0].queue_free()', 'fx.global_position = where', 'stain.global_position = where']:
    ck('spawner '+token,token in sp)
for token in ['extends Node2D','effect_kind', 'fragments: Array[Dictionary]', 'clouds: Array[Dictionary]', 'wood', 'stone','slam','hurt','flesh','landing','crate','draw_colored_polygon','draw_circle','queue_free()']:
    ck('impact '+token,token in fx)
for token in ['LIFETIME: float = 75.0', 'z_index = -4', 'v149_blood_pools', 'PackedVector2Array', 'ink', 'queue_free()', 'draw_colored_polygon', 'age > LIFETIME - 12.0']:
    ck('blood pool '+token,token in pool)
for token in ['MOVE_ACCELERATION: float = 2020.0','MOVE_BRAKE: float = 2900.0','TURN_ACCELERATION: float = 2170.0','landing_recoil_left', 'camera_push','on_world_impact','PHYSICAL_FEEL.burst','sprint_dust_time','jump_attack_active','candidate.call("hit", power','hitstop_left = (0.105','hurt_recoil_left = 0.19']:
    ck('player '+token,token in player)
ck('slam FX only after confirmed contact', player.index('if jump_attack_active:\n\t\t\tPHYSICAL_FEEL.burst')>player.index('candidate.call("hit", power'))
ck('jump whiff not giving confirmed camera impact', 'camera_kick = maxf(camera_kick, 4.4)' not in player)
ck('normal landed impact not forcing damage', 'PHYSICAL_FEEL.burst(root, global_position + Vector2(0, -6)' in player)
ck('world impacts attenuate by distance', 'if distance > 750.0:' in player and 'strength * falloff' in player)
ck('one enemy death', hunter.count('func _begin_enemy_death()')==1 and hunter.count('PHYSICAL_FEEL.pool(')==1)
ck('enemy injury is confirmed hit', hunter.index('PHYSICAL_FEEL.burst(')>hunter.index('hp = maxf(0.0, hp - applied_damage)'))
ck('boss pool on defeat only', warden.index('PHYSICAL_FEEL.pool(')>warden.index('func _defeat()'))
for s,name in [(cover,'cover'),(support,'support'),(debris,'debris'),(crate,'crate'),(lattice,'lattice')]:
    ck(name+' smoke', 'PHYSICAL_FEEL.burst(' in s)
    ck(name+' spatial impact', 'PHYSICAL_FEEL.rumble(' in s)
ck('destructible animation preserved', '_drop_perched_enemies()' in support and 'chain' in debris and '_set_collision()' in lattice)
ck('creatures avoid humanoid blood pool', 'PHYSICAL_FEEL.pool' not in src('moor_creature_v129.gd'))
for name in ['player.gd','gothic_hunter.gd','moor_warden_v132.gd','breakable_cover_v136.gd','collapse_support_v135.gd','falling_debris_v135.gd','carryable.gd','moonroot_lattice_v144.gd','impact_burst_v149.gd','blood_pool_v149.gd','impact_spawner_v149.gd']:
    s=src(name)
    ck('no merge markers '+name,'<<<<<<<' not in s and '>>>>>>>' not in s)
    ck('no mixed indentation '+name,re.search(r'^ +\t|^\t+ +\S',s,re.M) is None)
    # New imports must all resolve in the overlay tree.
    for p in re.findall(r'preload\("(res://scripts/[^\"]+_v149\.gd)"\)',s):
        ck(name+' preload '+p,(P/p[6:]).is_file())
    ck('no new damage in cosmetic '+name,not(name in ['impact_burst_v149.gd','blood_pool_v149.gd','impact_spawner_v149.gd'] and ('receive_damage(' in s or '.call("hit"' in s)))
errors=[l for l,v in checks if not v]
print(f'v1.49: {len(checks)-len(errors)}/{len(checks)} offline integration checks passed')
for label in errors[:70]: print('FAIL',label)
sys.exit(1 if errors else 0)
