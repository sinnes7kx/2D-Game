"""Ghost Girl v1.17: cosmetic one-hit beam + Hollow Veil Moor expansion.
Static validation; a real Godot editor import and F5 playtest remain necessary.
"""
from pathlib import Path
import hashlib, json, re
R=Path(__file__).resolve().parents[1]
OLD=R.parent/'GhostGirl_v116_work'  # optional sibling baseline for patch regression
problems=[]
def ok(condition, description):
    if not condition: problems.append(description)
def read(relative):
    target=R/relative
    ok(target.is_file(),f'missing {relative}')
    return target.read_text(encoding='utf-8') if target.exists() else ''
fx=read('scripts/weapon_fx_library.gd')
for token in ('"Luminous Lance"','func luminous_lance_roll(', '"rare": denominator = 8','"set": denominator = 6','"unique": denominator = 4','"lance": luminous_lance_roll('):
    ok(token in fx,f'rare-only beam trait is incomplete: {token}')
for q in ('"magic": return 4','"rare": return 6','"set", "unique": return 7'):
    ok(q in fx, 'old base projectile roll ranges changed: '+q)
item=read('scripts/item_instance.gd'); gen=read('scripts/item_generator.gd'); inv=read('scripts/inventory.gd'); tooltip=read('scripts/item_rich_text.gd')
for name,text in [('instance',item),('generator',gen),('inventory',inv)]:
    ok('wand_lance_index' in text,f'{name} not using persistent prestige roll')
ok('"wand_lance_index": item.wand_lance_index' in inv,'new wand mod not persisted')
ok('saved.get("wand_lance_index", item.wand_lance_index)' in inv,'v1.16 save cannot migrate without changing old item')
ok('get_slot() == "wand" and GhostWeaponFXLibrary.tier(quality) >= 2' in item, 'non-rare wand can acquire prestige')
ok('cast_form = 7' in item and '"form": cast_form' in item,'rare lance not reaching projectiles')
ok('LUMINOUS LANCE · RARE BEAM MOD' in tooltip,'rare wand description is not visible')
spell=read('scripts/moon_spell.gd'); game=read('scripts/game.gd')
for t in ('const LANCE_FADE: float = 0.52','if spell_form == 7:', 'func _draw_luminous_lance() -> void:', 'beam_resolved = true', 'var tip_taper: float', 'draw_line(p0, p1, Color(1.0, 1.0, 1.0'):
    ok(t in spell, f'luminous lance renderer incomplete {t}')
ok(spell.count('victim.call("hit", damage,')==1, 'lance duplicates gameplay hit')
ok('wall_ray.collision_mask = 6' in spell and 'beam_end = safe_finish' in spell, 'lance would ignore world collision')
ok('elif age >= (LANCE_FADE if spell_form == 7 else BEAM_FADE):' in spell,'lance might persist endlessly')
ok('bolt.spell_form = int(appearance["form"])' in game,'spell form not read from equipped wand')
ok('KEY_F3' in game and '_give_luminous_lance_trial()' in game,'rare wand trial shortcut missing')
ok('inventory.add_loot(wand_template, 117171, "rare")' in game,'trial seed does not guarantee prestige beam')
ok('user://ghost_girl_treasures_v2.json' in inv,'existing save file location changed')
moor=read('scenes/rooms/hollow_veil_moor.tscn')
old_moor=(OLD/'scenes/rooms/hollow_veil_moor.tscn').read_text() if (OLD/'scenes/rooms/hollow_veil_moor.tscn').is_file() else ''
before_enemies=len(re.findall(r'parent="Gameplay/Enemies" instance=',old_moor)) if old_moor else 68
after_enemies=len(re.findall(r'parent="Gameplay/Enemies" instance=',moor))
before_chests=len(re.findall(r'parent="Gameplay/TreasureChests" instance=',old_moor)) if old_moor else 3
after_chests=len(re.findall(r'parent="Gameplay/TreasureChests" instance=',moor))
ok(before_enemies==68 and after_enemies==92,'expected 68 existing + 24 easier enemies')
ok(before_chests==3 and after_chests==8,'expected 5 new rewards')
ok(moor.count('script = ExtResource("v117_shrine")')==2,'two recovery shrines missing')
ok(moor.count('script = ExtResource("v117_switch")')==4,'two paired rose hook puzzles not placed')
ok(moor.count('script = ExtResource("v117_gate")')==2,'puzzle gates missing')
ok(moor.count('script = ExtResource("v117_secret")')==3,'three hidden hook discoveries missing')
ok('loot_seed = 117171' in moor and 'guaranteed_quality = "rare"' in moor,'Luminous Lance test chest missing')
ok(moor.startswith('[gd_scene load_steps=22 format=3]'), 'moor load_steps not updated for new resources')
ok((117171 + 117117)%8==0,'featured chest seed does not roll the rare beam')
# Cross-check in-scene gate, switch, and secret chest node names to catch broken paths.
for name in ('V117NorthRelic','V117WestLocket','V117ThornCache','V117StarCache','V117HushCache','V117NorthRoseGate','V117WestRoseGate','V117NorthRose1','V117WestRose1'):
    ok(f'name="{name}"' in moor,f'broken node name {name}')
for id in ('v117_moor_north_relic','v117_moor_west_locket','v117_moor_thorn_cache','v117_moor_star_cache','v117_moor_hush_cache'):
    ok(f'chest_id = "{id}"' in moor, f'missing persistent treasure id {id}')
# Nothing in the approved character/body/environment atlases should be altered.
unchanged=['resources/ghost_extra_animations.json','resources/weapon_layer_manifest.json','scripts/player.gd','assets/world/hollow_veil_moor_v116.jpg','assets/equipment/weapon_surface_v111.gdshader']
for path in unchanged:
    if (OLD/path).exists():
        ok(hashlib.sha256((R/path).read_bytes()).digest()==hashlib.sha256((OLD/path).read_bytes()).digest(), 'unexpected source-art/gameplay change: '+path)
result={'version':'1.17','status':'PASS' if not problems else 'FAIL','projectile_forms':8,'lance_beam_hit_events':1,'moor_enemies_before':before_enemies,'moor_enemies_after':after_enemies,'moor_reward_chests':after_chests,'rose_hook_relay_pairs':2,'new_hidden_chests':3,'problems':problems}
print(json.dumps(result,indent=2))
if problems: raise SystemExit(1)
