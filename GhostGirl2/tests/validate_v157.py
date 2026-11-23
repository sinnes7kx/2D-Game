#!/usr/bin/env python3
"""Static Ghost Girl v1.57 regression checks, not a substitute for Godot F5."""
from pathlib import Path
import sys, hashlib, json
root=Path(sys.argv[1]) if len(sys.argv)>1 else Path(__file__).resolve().parents[1]
checks=0
def require(cond, label):
    global checks
    checks+=1
    if not cond: raise AssertionError(f'v1.57 check {checks}: {label}')
def src(name):
    path=root/'scripts'/name
    require(path.exists(),f'{name} included')
    return path.read_text()
p=src('player.gd')
e=src('gothic_hunter.gd')
b=src('enemy_hex_bolt.gd')
f=src('combat_response_v157.gd')
require('func register_confirmed_evade(attacker: Node2D' in p,'confirmed evade callback')
require('dodge_time_left <= 0.0 or invulnerable_time <= 0.0' in p,'active dodge iframes required')
require('dodge_time_left < DODGE_DURATION - 0.24' in p,'recovery cannot count')
require('precision_evade_registered = true' in p,'once per dodge')
require('backstep_counter_armed and global_position.distance_to(backstep_origin) > 40.0' in p,'retreat check')
require('offers_backstep_counter' not in p,'no speculative proximity credit')
require('world.ui.set_stamina(stamina, MAX_STAMINA)' in p,'stamina visible')
require('_spawn_precision_feedback("riposte", candidate.global_position' in p,'actual contact-only riposte')
require('RIPOSTE_SFX if counter_hit and struck else HIT_SFX' in p,'chime only on hit')
require('counter_window = 0.0' in p,'counter consumed')
require(e.count('girl.call("register_confirmed_evade", self, global_position)')==2,'both melee and lunge hooked')
require(e.count('girl.call("receive_damage", strike_damage, global_position)')==2,'original damage path retained')
require('active_warning_duration = maxf(0.05, windup)' in e,'actual windup duration tracked')
require('_emit_attack_release_cue()' in e,'release VFX integrated')
require('tell_progress * 1.7' in e,'readable winding sweep')
require('strike_done = true' in e,'one-hit gate retained')
require(b.count('target.call("receive_damage", damage, global_position)')==1,'original projectile damage call retained')
require('target.call("register_confirmed_evade", self, global_position)' in b,'projectile collision connected')
require('if not result.is_empty():' in b,'collision gate remains')
require('queue_free()' in f,'transient FX cleanup')
require('CollisionShape2D' not in f and 'receive_damage' not in f,'FX has no combat side effects')
require('"ready"' in f and '"riposte"' in p and '"evade"' in p,'three distinct cues')
require('add_to_group("combat_feedback_v157")' in f,'resource cap group')
require('combat_feedback_v157").size() >= 18' in p and 'combat_feedback_v157").size() >= 18' in e,'transient FX capped')
print(f'v1.57: {checks}/{checks} static integration checks passed')
