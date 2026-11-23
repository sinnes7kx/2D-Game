"""v1.13 static integration and backward-compatibility checks.
Does not substitute for an actual Godot engine run.
"""
from pathlib import Path
import json, re, wave
ROOT=Path(__file__).resolve().parents[1]
errors=[]
def check(condition,label):
    if not condition:
        errors.append(label)
def src(path):
    p=ROOT/path
    check(p.is_file(),f'missing {path}')
    return p.read_text() if p.is_file() else ''

lib=src('scripts/weapon_fx_library.gd')
check('class_name GhostWeaponFXLibrary' in lib,'fx class registration')
for title in ('Rose Dust','Moon Sparks','Frost Motes','Vesper Cinders','Lace Shimmer','Thorn Halo','Astral Petals','Silver Runes','Aurora Ghostfire','Eclipse Shards'):
    check(title in lib,f'missing motif {title}')
for title in ('Moon Orb','Comet','Twin Wisps','Orbiting Sigil','Triune Stars','Moonlight Beam','Prismatic Lattice'):
    check(title in lib,f'missing wand form {title}')
check('"rare": return 6' in lib and '"set", "unique": return 7' in lib,'prestige quality gating')
item=src('scripts/item_instance.gd')
generator=src('scripts/item_generator.gd')
save=src('scripts/inventory.gd')
for key in ('weapon_fx_style_index','weapon_fx_color_index','wand_cast_style_index'):
    for text,path in ((item,'item_instance'),(generator,'item_generator'),(save,'inventory')):
        check(key in text,f'{key} missing in {path}')
    check(f'"{key}": item.{key}' in save,f'not saved: {key}')
    check(f'saved.get("{key}", item.{key})' in save,f'older saves default to seeded rolls: {key}')
check('user://ghost_girl_treasures_v2.json' in save,'save location changed')
check('absi(seed_value) + 1131101' in lib and 'absi(seed_value) + 1131103' in lib and 'absi(seed_value) + 1131109' in lib,'random streams are not independent')
formatter=src('scripts/item_rich_text.gd')
check('GhostWeaponFXLibrary.motif_name' in formatter and 'GhostWeaponFXLibrary.spell_form_name' in formatter,'inventory effects are not visible')
spell=src('scripts/moon_spell.gd')
check('spell_form >= 5' in spell and 'BEAM_FADE: float = 0.36' in spell,'beam missing fade')
check('wall_ray.collision_mask = 6' in spell,'projectile bypasses destructible crates')
check('victim.call("hit", damage' in spell and spell.count('victim.call("hit", damage')==1,'spell has more than one damage call')
check('func _resolve_beam()' in spell and 'beam_resolved = true' in spell,'beam can retrigger')
check('spell_form == 2' in spell and 'spell_form == 4' in spell and 'spell_form == 6' in spell,'wisp/star/lattice variants missing')
game=src('scripts/game.gd')
for key in ('bolt.effect_motif','bolt.effect_color','bolt.spell_form','bolt.effect_seed','wand_glimmer'):
    check(key in game,f'game does not wire {key}')
player=src('scripts/player.gd')
for key in ('"ready"','"riposte"','SPECTACLE','RIPOSTE_SFX','backstep_counter_armed','counter_window = 0.62','hitstop_left = (0.105 if counter_hit'):
    check(key in player,f'counter feedback missing {key}')
check('for candidate in get_tree().get_nodes_in_group("enemies")' in player,'free-aim dodge counter unsupported')
spec=src('scripts/weapon_spectacle.gd')
check('RIPOSTE!' in spec and 'COUNTER READY' in spec,'counter message not drawn')
for f in ('scripts/wand_idle_glimmer.gd','scripts/weapon_animation_layers.gd'):
    check('GhostWeaponFXLibrary' in src(f),f'effect color missing in {f}')
manifest=json.loads(src('resources/weapon_layer_manifest.json'))
check(len(manifest)==32,'weapon animation count changed')
check(all('tip_positions' in entry and len(entry['tip_positions'])==8 for entry in manifest),'frame-aligned tip cosmetics missing')
check(all(all(len(coord)==2 and -128<=coord[0]<=128 and -110<=coord[1]<=110 for coord in entry['tip_positions']) for entry in manifest),'tip coordinates outside sprite cells')
check('weapon_layers_v112/' in manifest[0]['atlas_front'],'v1.12 weapon atlas lost')
path=ROOT/'assets/audio/riposte_chime_v113.wav'
if path.exists():
    with wave.open(str(path)) as w:
        check(w.getnchannels()==1 and w.getnframes()>2000 and w.getframerate()==22050,'riposte audio malformed')
else: errors.append('riposte audio absent')
print(json.dumps({'version':'1.13','status':'FAIL' if errors else 'PASS','weapon_animations':len(manifest),'motifs':10,'colors':10,'wand_forms':7,'old_save_path_unchanged':True,'errors':errors},indent=2))
if errors:
    raise SystemExit(1)
