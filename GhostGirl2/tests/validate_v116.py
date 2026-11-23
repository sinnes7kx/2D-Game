"""v1.16 original moor, cosmetic hit effects, save compatibility.
Static tests only; Godot runtime and visual behavior still need F5 playtest.
"""
from pathlib import Path
from PIL import Image
import json,re
R=Path(__file__).resolve().parents[1]
fail=[]
def check(ok,description):
    if not ok: fail.append(description)
def source(path):
    p=R/path
    check(p.is_file(),'missing '+path)
    return p.read_text() if p.is_file() else ''

fx=source('scripts/impact_prestige_v116.gd')
for token in ('func configure(', 'kind == "blood"','"Sanguine Cascade"' if False else 'style == 4', 'kind == "blood"', 'draw_arc(', 'draw_circle(', 'draw_line('):
    check(token in fx, 'impact effect lacks '+token)
check('receive_damage' not in fx and 'candidate.call' not in fx, 'visual effect should never hit enemies')

rolls=source('scripts/weapon_fx_library.gd')
for token in ('BLADE_IMPACTS', 'WAND_IMPACTS', 'Sanguine Cascade', 'Prismatic Shatter', 'rng_impact.seed = absi(seed_value) + 1161931', 'impact_limit(quality)', '"impact": rng_impact.randi_range'):
    check(token in rolls,'impact affix missing '+token)
item=source('scripts/item_instance.gd')
gen=source('scripts/item_generator.gd')
inv=source('scripts/inventory.gd')
for name,text in (('item',item),('generator',gen),('inventory',inv)):
    check('weapon_impact_style_index' in text, name+' missing new field')
check('"weapon_impact_style_index": item.weapon_impact_style_index' in inv,'impact roll not saved')
check('saved.get("weapon_impact_style_index", item.weapon_impact_style_index)' in inv,'old save fallback missing')
check('user://ghost_girl_treasures_v2.json' in inv, 'save path changed')
check('"impact"' in item, 'effect_rolls missing impact')

player=source('scripts/player.gd')
wand=source('scripts/moon_spell.gd')
game=source('scripts/game.gd')
check('candidate.call("hit", power,' in player and '_spawn_blade_blood(candidate.global_position' in player,'blade effect must follow confirmed hit')
check('starburst.call("configure", "wand"' in wand and 'root.add_child(starburst)' in wand, 'wand collision fx not created')
check('bolt.impact_style = int(appearance["impact"])' in game, 'wand cast not receiving item-specific style')
check(wand.count('victim.call("hit", damage,') == 1, 'wand cosmetic forms multiply hits')
check('beam_resolved = true' in wand and 'wall_ray.collision_mask = 6' in wand,'beam wall safety changed')
check('"hollow_veil_moor": preload("res://scenes/rooms/hollow_veil_moor.tscn")' in game,'missing new room in registry')
check('"hollow_veil_moor": "HOLLOW VEIL MOOR"' in game,'missing room title')
check('_enter_room("hollow_veil_moor")' in game, 'F6 test warp missing')

scene=source('scenes/rooms/hollow_veil_moor.tscn')
with Image.open(R/'assets/world/hollow_veil_moor_v116.jpg') as im:
    check(im.size==(4608,3072),'wrong moor dimensions')
check(scene.count('instance=ExtResource("wraith")')+scene.count('instance=ExtResource("hunter")')==68, 'expected 68 enemies')
check(scene.count('is_elite = true')==3,'expected three elites')
check(scene.count('max_health = 12.0')+scene.count('max_health = 15.0') > 35,'regular wraiths not fragile enough')
check(scene.count('max_health = 12.0') + scene.count('max_health = 15.0') + scene.count('maximum_health = 18.0') >= 60,'fewer than 60 easy enemies')
check(scene.count('instance=ExtResource("chest")')==3,'three reward chests expected')
check(scene.count('script = ExtResource("anchor")')>=5,'moor hook anchors missing')
for name in ('briar_hollow','moonthorn_woods'):
    check('destination = "'+name+'"' in scene,'moor return portal missing to '+name)
    check('destination = "hollow_veil_moor"' in source('scenes/rooms/'+name+'.tscn'), 'missing way into moor from '+name)
for dir_ in ('North','South','West','East'):
    check('SubResource("lim'+dir_+'")' in scene,'moor boundary missing '+dir_)
all_res = list(re.finditer(r'\bpath="res://([^"]+)"',scene))
for m in all_res:
    check((R/m.group(1)).is_file(),'new scene missing '+m.group(1))

summary={'version':'1.16','result':'PASS' if not fail else 'FAIL','moor_px':[4608,3072],'enemies':68,'elites':3,'cosmetic_does_not_change_damage':True,'existing_save_path_preserved':True,'problems':fail}
print(json.dumps(summary,indent=2))
if fail: raise SystemExit(1)
