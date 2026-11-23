"""v1.32 - Moor Vigil major release, strict offline Godot scene integration checks.
Not a substitute for launching Godot and playtesting; reported separately.
"""
from pathlib import Path
from collections import Counter
import json, re
ROOT = Path(__file__).resolve().parents[1]
errors=[]

def check(value, explanation):
    if not value:
        errors.append(explanation)

def source(path):
    f=ROOT/path
    check(f.exists(),f'missing {path}')
    return f.read_text(encoding='utf-8') if f.exists() else ''

scene=source('scenes/rooms/hollow_veil_moor.tscn')
crypt=source('scenes/rooms/moonwake_crypt.tscn')
hud=source('scenes/hud.tscn')
game=source('scripts/game.gd')
alter=source('scripts/moor_vigil_altar_v132.gd')
warden=source('scripts/moor_warden_v132.gd')
memory=source('scripts/moor_vigil_memory_v132.gd')
forge=source('scripts/relic_attunement_v132.gd')

# Conservative .tscn parser: accidental # comments and broken parent refs
# caused hard project-import failure in v1.20, so check all touched scenes.
for rel, content in [('scenes/rooms/hollow_veil_moor.tscn',scene), ('scenes/rooms/moonwake_crypt.tscn',crypt), ('scenes/hud.tscn',hud), ('scenes/moor_warden_v132.tscn',source('scenes/moor_warden_v132.tscn'))]:
    check(content.endswith('\n'),f'{rel} missing final newline')
    check(not any(l.lstrip().startswith('#') for l in content.splitlines()), f'{rel} has # comments (must use ;)')
    parents=set(['.'])
    for lineno,line in enumerate(content.splitlines(),1):
        if line.startswith('[ext_resource'):
            m=re.search(r'path="res://([^\"]+)"',line)
            check(m is not None, f'{rel}:{lineno} invalid resource tag')
            if m:
                check((ROOT/m.group(1)).is_file(), f'{rel}:{lineno} missing {m.group(1)}')
        if line.startswith('[node'):
            m=re.match(r'\[node name="([^\"]+)".*?parent="([^\"]+)"',line)
            if m:
                name,parent=m.groups()
                check(parent == '.' or parent in parents, f'{rel}:{lineno} unresolved parent {parent} ({name})')
                canonical=name if parent=='.' else parent+'/'+name
                check(canonical not in parents, f'{rel}:{lineno} duplicate node path {canonical}')
                parents.add(canonical)
    for line in content.splitlines():
        if line.startswith('[gd_scene'):
            m=re.search(r'load_steps=(\d+)',line)
            if m:
                declared=int(m.group(1))
                n_ext=len(re.findall(r'^\[ext_resource ', content, re.M))
                n_sub=len(re.findall(r'^\[sub_resource ', content, re.M))
                check(declared==n_ext+n_sub+1, f'{rel} load_steps={declared} vs resources={n_ext+n_sub+1}')
            break

keys=['v132_vigil_willow','v132_vigil_graves','v132_vigil_fen','v132_vigil_ruins']
for key in keys:
    check(scene.count(f'memory_id = "{key}"') == 1, f'expected exactly one memorial {key}')
    check(key in alter and key in game, f'memorial {key} missing from altar/game tracker')
check(scene.count('parent="Gameplay/V132Vigil"')==6, 'four memories + one boss + one altar are not wired under Vigil')
check(scene.count('parent="Gameplay/Enemies" instance=ExtResource("hunter")')>=4, 'elite sentinel pack missing')
check(scene.count('V132VigilWaystone')==5, 'five readable vigil waystones missing')
check('func try_awaken() -> String:' in alter and 'count < MEMORY_IDS.size()' in alter, 'boss encounter missing 4-memory unlock')
check('bonus.call("set_open", progress() >= 2)' in alter, 'midway moonbow reward does not unlock on second memory')
check('var second: Node' in alter and 'second.call("set_open", completed)' in alter, 'second boss reward gate not wired')
check('func refresh_progress() -> void:' in alter and 'refresh_progress' in game, 'midway gate not updated immediately after collecting memory')
for path in ('../V132MoorWarden','../../V132MidwayGate','../../V132WardenGate','../../V132WardenCenserGate'):
    check(f'NodePath("{path}")' in scene, f'path missing {path}')
check('func begin_encounter() -> void:' in warden, 'boss cannot be activated')
check('func _set_corporeal(enabled: bool)' in warden and 'collision_layer = 16 if enabled else 0' in warden, 'dormant boss blocks world collision or arrow rays')
check('_set_storm_rain(0.68)' in warden and '_set_storm_rain(0.38)' in warden, 'boss does not restore weather on defeat')
check('func hit(amount: float, poise_multiplier: float = 1.0)' in warden, 'boss lacks weapon-compatible hit method')
check('func apply_frost_slow(' in warden and 'func on_hook_yank(' in warden, 'boss lacks existing spell/hook integration')
check('if attack_kind == 1 and float(girl.get("jump_time_left")) > 0.0:' in warden, 'shockwave not explicitly jump-dodgeable')
check(warden.count('girl.call("receive_damage", amount, global_position)')==1, 'boss attack has duplicated damage calls')
check('v132_moor_warden_defeated' in warden and 'saved[DEFEAT_ID] = true' in warden, 'boss defeat not saved persistently')
check('loot_template", null' in warden, 'summoned moths could inflate drop rates')
check('func _defeat()' in warden and 'queue_free()' in warden, 'boss defeat/cleanup incomplete')
for key in ('v132_midway_moonbow','v132_warden_reaper_reward','v132_warden_censer_reward'):
    check(scene.count(f'chest_id = "{key}"') == 1, f'missing unique reward chest {key}')
for item_id, resource in [('v132_veilkeeper_reaper','veilkeeper_reaper'),('v132_lament_moonbow','lament_moonbow'),('v132_fourth_bell_censer','censer_of_the_fourth_bell')]:
    text=source(f'items/v132/{resource}.tres')
    check(f'item_id = "{item_id}"' in text and 'unique = true' in text, f'{resource} signature template incomplete')
check('guaranteed_quality = "unique"' in scene and scene.count('guaranteed_quality = "unique"')>=3, 'signature relic reward quality not guaranteed')
check('func try_attune(inventory: Node) -> String:' in forge, 'visual attunement interaction missing')
for stat in ('item.item_seed =','item.affixes =','item.sockets =','item.stat_value =','item.quality ='):
    check(stat not in forge, f'attunement must not modify item stats: {stat}')
for cosmetic in ('weapon_base_index','weapon_gradient_index','weapon_detail_a_index','weapon_detail_b_index','weapon_fx_style_index','weapon_fx_color_index','weapon_fx_accent_index','weapon_fx_trail_index','wand_cast_style_index','weapon_impact_style_index'):
    check(f'item.{cosmetic} =' in forge, f'attunement does not update {cosmetic}')
check('inventory.call("save_game")' in forge and 'inventory.equipment_changed.emit()' in forge, 'attunement visuals not saved/refreshed')
check('func set_vigil_status(' in source('scripts/hud.gd') and '[node name="VigilStatus"' in hud, 'minimal objective HUD missing')
check('if room == "hollow_veil_moor"' in game or 'room == "hollow_veil_moor", count' in game, 'objective HUD not limited to moor')
check('Gameplay/V132Vigil' in game and 'Gameplay/V132Attunements' in game, 'world state restoration incomplete')
check('SAVE_FILE' not in forge, 'attunement should use existing inventory persistence')
result={'release':'v1.32','status':'PASS' if not errors else 'FAIL','memory_count':4,'bosses':1,'new_elites':4,'named_rewards':3,'one_use_attunement_shrines':2,'validation_errors':errors}
print(json.dumps(result,indent=2))
if errors: raise SystemExit(1)
