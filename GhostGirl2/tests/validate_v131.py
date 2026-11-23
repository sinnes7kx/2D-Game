"""v1.31 targeted Godot-source validation, not an engine/F5 playtest."""
from pathlib import Path
import re, json, hashlib
R = Path(__file__).resolve().parents[1]
BASE = R.parent / 'GhostGirl_v130_work'
errors = []

def check(ok, note):
    if not ok:
        errors.append(note)

def read(relative):
    path = R / relative
    check(path.is_file(), f'missing {relative}')
    return path.read_text(encoding='utf-8') if path.is_file() else ''

scene = read('scenes/rooms/hollow_veil_moor.tscn')
game = read('scripts/game.gd')
mechanic = read('scripts/moonshot_bloom_v131.gd')
death = read('scripts/enemy_death_burst_v131.gd')
drop = read('scripts/world_drop.gd')
wraith = read('scripts/rose_wraith.gd')
moor = read('scripts/moor_creature_v129.gd')
hunter = read('scripts/gothic_hunter.gd')

# Scene structure; common historical source of actual parse failures.
resources = re.findall(r'^\[ext_resource[^\]]*path="res://([^"]+)"[^\]]*id="([^"]+)"\]', scene, re.M)
subs = re.findall(r'^\[sub_resource[^\]]*id="([^"]+)"\]', scene, re.M)
header = re.search(r'^\[gd_scene load_steps=(\d+)', scene, re.M)
check(header is not None and int(header.group(1)) == len(resources) + len(subs) + 1, 'scene load_steps mismatch')
check(len(set(ref for _,ref in resources)) == len(resources), 'duplicate resource ids')
for rel, ref in resources:
    check((R / rel).is_file(), f'missing resource: {ref} at {rel}')
check(not re.search(r'^\s*#',scene,re.M), 'invalid # comment in .tscn')
check('id="v131_moonbloom"' in scene and 'load_steps=40' in scene,'missing new puzzle resource or wrong scene header')

# Both optional encounters, actual nodes with Godot-valid paths and persistence.
for prefix,stem,seed in [('Willow','willow',131216),('Drowned','drowned',131799)]:
    target = f'V131{prefix}MoonDisc'
    gate = f'V131{prefix}MoonGate'
    chest = f'V131{prefix}MoonChest'
    for name in (target,gate,chest,f'V131{prefix}Waystone'):
        check(f'name="{name}"' in scene, f'missing {name}')
    check(f'gate_path = NodePath("../../{gate}")' in scene, f'bad gate relative path {target}')
    check(f'chest_path = NodePath("../TreasureChests/{chest}")' in scene, f'bad chest relative path {gate}')
    check(f'"v131_{stem}_moonbloom_chest"' in scene, f'missing chest persist id {stem}')
    check(f'"v131_{stem}_moonbloom"' in scene, f'missing puzzle persist id {stem}')
    check(f'loot_seed = {seed}' in scene, f'missing predetermined reward seed {stem}')
    check((seed + 230123) % 11 == 0, f'{stem} rare reward does not have visual prestige roll')
check(scene.count('script = ExtResource("v131_moonbloom")') == 2, 'need two moonshot + rose encounters')
check('"Gameplay/V131MoonshotBloom"' in game and 'restore_secret' in game, 'puzzles not restored on re-entering moor')
check('user://ghost_girl_treasures_v2.json' in read('scripts/inventory.gd'), 'save path changed')
for tok in ('add_to_group("moon_archery_targets")','add_to_group("rose_bloom_relay")', 'func on_bow_hit(charged: bool, airborne: bool) -> bool:', 'func on_grasping_roses() -> bool:', 'func restore_secret(save_data: Node) -> void:', 'inventory.call("save_game")', 'stage = 2', 'gate.call("set_open", activated)'):
    check(tok in mechanic, f'new puzzle incomplete: {tok}')
check('target.call("on_bow_hit", charged, launched_in_air)' in read('scripts/bow_arrow_v126.gd'), 'physical charged arrow not connected')
check('get_nodes_in_group("rose_bloom_relay")' in read('scripts/grasping_roses_v127.gd'), 'Grasping Roses not connected')
check('func _save_step(suffix: String) -> bool:' in mechanic and 'discovery_id + "_" + suffix' in mechanic, 'save keys not stage-specific')

# Death bursts: visual-only, killed once, freed automatically, no loot tables.
for tok in ('const LIFE: float = 0.84','queue_free()', 'var shards: Array[Dictionary]', '"moth":', '"lantern":', '"hunter":', 'var rng: RandomNumberGenerator', 'draw_colored_polygon'):
    check(tok in death, 'death visuals incomplete: '+tok)
for tok in ('receive_damage','call("hit"', 'spawn_world_loot','grant_enemy_loot','add_to_group("enemies")'):
    check(tok not in death, 'death visual accidentally includes gameplay: '+tok)
for src, count in ((wraith,1),(moor,1),(hunter,0)):
    check('enemy_death_burst_v131.gd' in src, 'death effects not imported into all enemy types')
    if count:
        check(src.count('_spawn_death_burst()') == 2, 'death hook missing or duplicate')
check('death_flash.set("elite", is_elite)' in hunter and '_begin_enemy_death()' in hunter, 'elite death flourish missing')
check('max_health: float = 13.0' in moor and 'maximum_health: float = 56.0' in hunter, 'enemy health balance changed')

# Seed-stable rarity gated floor auras; no stat/quality/drop modifications.
for tok in ('var rare_signature: int = -1', 'sample.quality in ["set", "unique"]', 'GhostWeaponFXLibrary.prestige_variant(sample.item_seed, sample.quality) >= 0', 'match rare_signature:'):
    check(tok in drop, 'rarity-gated loot display incomplete: '+tok)
for relative in ['scripts/item_generator.gd','scripts/item_instance.gd','scripts/inventory.gd','scripts/player.gd','scripts/bow_arrow_v126.gd','scripts/moonfall_blizzard.gd','resources/ghost_extra_animations.json','assets/world/hollow_veil_moor_v118.jpg']:
    check(hashlib.sha256((R/relative).read_bytes()).digest() == hashlib.sha256((BASE/relative).read_bytes()).digest(), 'approved mechanics / artwork unexpectedly modified: '+relative)

report = {'version':'1.31','status':'PASS' if not errors else 'FAIL','new_optional_encounters':2,'placed_enemies':len(re.findall(r'^\[node name="[^"]+" parent="Gameplay/Enemies" instance=',scene,re.M)),'death_visual_families':4,'loot_signature_styles':6,'runtime_tested':False,'errors':errors}
print(json.dumps(report,indent=2))
if errors:
    raise SystemExit(1)
