"""Ghost Girl v1.27 offline source/resource checks, not an F5 playtest."""
from pathlib import Path
from collections import Counter
import json, re, zipfile
ROOT=Path(__file__).resolve().parents[1]
errors=[]
def check(ok, msg):
    if not ok: errors.append(msg)
def text(rel):
    p=ROOT/rel
    check(p.is_file(),f'missing {rel}')
    return p.read_text() if p.is_file() else ''

project=text('project.godot')
for name,key in [('astral_rain',86),('grasping_roses',84)]:
    match=re.search(re.escape(name)+'=\\{(.+?)\\n\\}',project,re.S)
    check(bool(match),f'{name}: missing input action')
    if match:
        check(f'"physical_keycode":{key}' in match.group(1),f'{name}: incorrect keyboard key')

player=text('scripts/player.gd')
for needle in ('func _begin_spell_cast(heavy: bool = false, moonfall: bool = false)',
    'func _begin_spell_cast_v127(', 'special_spell_kind = new_kind',
    'world.cast_astral_rain(spell_aim_point)', 'world.cast_grasping_roses(spell_aim_point)',
    'astral_cooldown = 7.8','roses_cooldown = 7.1',
    'not world.inventory.has_collected(unlock)', 'BOW_RELEASE_FX',
    'arrow.set("visual_variant", visual_variant)',
    'if rarity >= 2 else -1'):
    check(needle in player,f'player missing {needle}')

game=text('scripts/game.gd')
for needle in ('ASTRAL_SCENE','ROSES_SCENE','func cast_astral_rain(',
    'func cast_grasping_roses(', 'func _v127_aimed_area_point(',
    'trace.collision_mask = 6', 'query.collision_mask = 6',
    '"v127_spell_reliquary"','"v127_astral_rain_unlocked"',
    '"v127_grasping_roses_unlocked"','inventory.save_game()',
    'room_view.get_node("Gameplay/V127SpellReliquaries")'):
    check(needle in game,f'game missing {needle}')

shrine=text('scripts/spell_reliquary_v127.gd')
for needle in ('@tool', 'add_to_group("interactable")', 'restore_from_inventory', 'unlock_id'):
    check(needle in shrine,f'shrine missing {needle}')

area=text('scripts/astral_rain_v127.gd')
rose=text('scripts/grasping_roses_v127.gd')
check(area.count('enemy.call("hit",')==1,'astral rain has duplicate damage paths')
check(rose.count('enemy.call("hit",')==1,'roses has duplicate damage paths')
check('if not hit_ids.has(identity):' in rose and 'hit_ids[identity] = true' in rose,
      'roses does not limit damaging hits to one per enemy per cast')
check('apply_frost_slow' in rose,'roses do not slow enemies')
check('pulse_interval: float = 0.66' in area and 'duration: float = 3.45' in area,
      'astral rain pulse timing changed')
for script in (area,rose):
    check('ray.collision_mask = 2' in script,'area spell ignores stone collision')

arrow=text('scripts/bow_arrow_v126.gd')
release=text('scripts/bow_release_v127.gd')
check('var visual_variant: int = -1' in arrow,'bow visual variants absent')
check('visual_variant >= 0' in arrow,'rare arrow visual branch missing')
check(arrow.count('target.call("hit", damage,')==1,'bow extra projectiles deal damage')
check('no hitbox' in release,'bow FX description missing noncombat constraint')
scene=text('scenes/rooms/moonwake_crypt.tscn')
check(scene.startswith('[gd_scene load_steps=38 format=3]'),'scene resource count outdated')
for needle in ('v127_spells', 'AstralRainReliquary', 'GraspingRosesReliquary',
    'position = Vector2(980, 1060)', 'position = Vector2(1400, 1060)'):
    check(needle in scene,f'crypt missing {needle}')

for path in ('scenes/astral_rain_v127.tscn','scenes/grasping_roses_v127.tscn','scenes/rooms/moonwake_crypt.tscn'):
    t=text(path)
    check(t.count('[node ')>0,f'{path}: no nodes')
    check(not re.search(r'^\s*#',t,re.M),f'{path}: invalid # scene comment')
    resources=re.findall(r'^\[ext_resource[^]]*path="res://([^\"]+)"[^]]*id="([^\"]+)"[^]]*\]',t,re.M)
    ids=[item[1] for item in resources]
    check(len(ids)==len(set(ids)),f'{path}: duplicate ids')
    for r,_ in resources:
        check((ROOT/r).is_file(),f'{path}: missing resource {r}')

save=text('scripts/inventory.gd')
check('user://ghost_girl_treasures_v2.json' in save,'save path changed')
print(json.dumps({'version':'1.27','status':'PASS' if not errors else 'FAIL',
 'spells':['Astral Rain','Grasping Roses'],'reliquaries':2,
 'bow_visual_variants':4,'runtime_tested':False,'errors':errors},indent=2))
if errors:raise SystemExit(1)
