"""v1.29 incremental moor creatures + cosmetic hit feedback checks.
Static only: this does not replace a Godot editor/runtime import and playtest.
"""
from pathlib import Path
import re, json, math, hashlib
ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT.parent/'GhostGirl_v128_work'
errors=[]
def require(condition, message):
    if not condition:
        errors.append(message)
def read(rel):
    p=ROOT/rel
    require(p.is_file(), f'Missing {rel}')
    return p.read_text(encoding='utf-8') if p.is_file() else ''

scene=read('scenes/rooms/hollow_veil_moor.tscn')
new_scene=read('scenes/moor_creature_v129.tscn')
creature=read('scripts/moor_creature_v129.gd')

exts=re.findall(r'^\[ext_resource[^\]]*path="res://([^"]+)"[^\]]*id="([^"]+)"\]$',scene,re.M)
subs=re.findall(r'^\[sub_resource[^\]]*id="([^"]+)"\]$',scene,re.M)
require(len(exts)+len(subs)+1 == int(re.search(r'^\[gd_scene load_steps=(\d+)',scene).group(1)), 'moor scene load_steps mismatch')
require(len({id for path,id in exts})==len(exts), 'duplicate external resource ID in moor scene')
for path,_id in exts:
    require((ROOT/path).exists(), f'missing moor dependency {path}')
require('id="v129_creature"' in scene, 'new enemy packed scene not connected')
require(not re.search(r'^\s*#',scene,re.M), 'invalid # comments in .tscn')

nodes=re.findall(r'^\[node name="([^"]+)"[^\]]*parent="Gameplay/Enemies"[^\]]*instance=ExtResource\("v129_creature"\)\]\n(.*?)(?=^\[node |\Z)',scene,re.M|re.S)
require(len(nodes)==24, f'expected 24 v129 creatures, found {len(nodes)}')
require(sum('creature_kind = "hush_moth"' in contents for _n,contents in nodes)==12, 'wrong moth count')
require(sum('creature_kind = "gloom_lantern"' in contents for _n,contents in nodes)==12, 'wrong lantern count')
for n,content in nodes:
    pos=re.search(r'^position = Vector2\(([-\d.]+), ([-\d.]+)\)$',content,re.M)
    require(pos is not None, n+' missing position')
    if pos:
        x,y=map(float,pos.groups())
        require(350<x<10100 and 350<y<6600, n+' placed outside moor')
    health=re.search(r'^max_health = (\d+\.\d+)$', content,re.M)
    require(health is not None and float(health.group(1)) <=20, n+' not weak enough')
# Confirm scene supports world collisions, swept bow hits and spells.
for token in ('collision_layer = 16','collision_layer = 32','collision_mask = 2','shape = SubResource("hurt")'):
    require(token in new_scene, f'enemy scene collision missing {token}')
for method in ('func hit(', 'func apply_frost_slow(', 'func on_hook_yank(', 'func spell_aim_point(', 'func offers_backstep_counter('):
    require(method in creature, f'enemy missing {method}')
require('"hush_moth"' in creature and '"gloom_lantern"' in creature, 'two creature types missing')
require('attack_damage: float = 3.0' in creature and 'else 0.95' in creature, 'difficulty or telegraph changed')
require(creature.count('girl.call("receive_damage",') == 1, 'enemy has multiple damage paths')

bow=read('scripts/bow_arrow_v126.gd')
fx=read('scripts/bow_impact_v129.gd')
require('const BOW_IMPACT_V129' in bow and 'flash.set_script(BOW_IMPACT_V129)' in bow, 'arrow impact missing')
require('flash.call("configure", ink, accent, visual_variant, fx_tier, direction, charged, motif)' in bow, 'bow appearance rolls disconnected')
require(bow.count('target.call("hit", damage,')==1, 'bow gameplay damage duplicated')
require('hit_ids.size() >= 2' in bow, 'pierce hit cap removed')
require('func configure(' in fx and 'rare_variant < 0' in fx and 'rarity < 2' in fx, 'bow impact rarity gating missing')
require('call("hit"' not in fx and 'Area2D' not in fx and 'PhysicsRay' not in fx, 'visual bow impact affects gameplay')

moon=read('scripts/moonfall_blizzard.gd')
require('var pulse_feedback: Array[Dictionary]' in moon, 'frost feedback not retained')
require('pulse_feedback.size() < 8' in moon, 'frost feedback not capped')
require('for imprint in pulse_feedback:' in moon, 'frost hit draw missing')
require(moon.count('enemy.call("hit", damage_per_pulse, 0.45)')==1, 'Moonfall duplicated damage')
require('var life_seconds: float = 4.2' in moon and 'var pulse_seconds: float = 0.70' in moon, 'Moonfall timing changed')

jump=read('scripts/jump_landing_cue.gd')
player=read('scripts/player.gd')
for token in ('var enhanced: bool = false', 'var accent: Color', 'if enhanced:', 'draw_arc('):
    require(token in jump, f'jump landing FX missing {token}')
for token in ('cue.set("enhanced", jump_attack_active)','cue.set("motion", jump_direction)', 'cue.set("accent", GhostWeaponFXLibrary.color'):
    require(token in player, f'jump input feedback disconnected {token}')
require('user://ghost_girl_treasures_v2.json' in read('scripts/inventory.gd'), 'save path altered')
for rel in ('assets/world/hollow_veil_moor_v118.jpg','resources/ghost_extra_animations.json', 'resources/weapon_layer_manifest.json','scenes/rooms/moonwake_crypt.tscn'):
    if (BASE/rel).is_file():
        require(hashlib.sha256((BASE/rel).read_bytes()).digest()==hashlib.sha256((ROOT/rel).read_bytes()).digest(), f'approved background/animation altered: {rel}')

result={'version':'1.29','status':'PASS' if not errors else 'FAIL','new_enemies':len(nodes),'placed_enemies_total':len(re.findall(r'^\[node name="[^"]+" parent="Gameplay/Enemies" instance=',scene,re.M)),'new_enemy_archetypes':2,'rarity_gated_bow_impact':True,'frost_pulse_feedback_cap':8,'runtime_tested':False,'problems':errors}
print(json.dumps(result,indent=2))
if errors:
    raise SystemExit(1)
