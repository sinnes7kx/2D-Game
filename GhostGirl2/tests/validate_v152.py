#!/usr/bin/env python3
"""Static v1.52 overlay and backward-compatibility checks. No Godot engine playtest."""
from pathlib import Path
import sys,re,hashlib

def run(project: Path):
    count=0
    def ok(value,why):
        nonlocal count
        count+=1
        if not value: raise AssertionError(f'v1.52 check {count}: {why}')
    def src(name):
        path=project/name
        ok(path.is_file(),f'{name} exists')
        return path.read_text()
    uid=src('scripts/cosmetic_rng_v152.gd')
    item=src('scripts/item_instance.gd')
    inv=src('scripts/inventory.gd')
    vis=src('scripts/equipment_visuals.gd')
    fx=src('scripts/weapon_prestige_fx.gd')
    game=src('scripts/game.gd')
    scene=src('scenes/player.tscn')
    shaders=src('assets/equipment/dress_palette.gdshader')
    ui=src('scripts/item_rich_text.gd')
    panel=src('scripts/inventory_panel.gd')
    alt=src('scripts/relic_attunement_v132.gd')
    swatch=src('scenes/inventory_panel.tscn')
    ok('generate_random_bytes(16)' in uid, '128-bit CSPRNG')
    ok('hex_encode()' in uid and 'uid.length() != 32' in uid, 'full hexadecimal UID')
    ok('uid.substr(0, 12).hex_to_int()' in uid,'separate bounded GDScript visual arithmetic')
    for name,mod in [('Aether Thorns',1),('Void Eclipse',2),('Astral Seraph',3)]:
        ok(name in uid, f'{name} signature available')
        ok(f'return {mod}' in uid, f'{name} signature roll')
    for odds in [512,4096,32768]: ok(f'% {odds} ==' in uid,f'ultra signature independent odds {odds}')
    for field in ['cosmetic_uid','rare_visual_mod']:
        ok('var '+field+':' in item,field+' item storage')
        ok('"'+field+'": item.'+field in inv,field+' saved')
        ok('item.'+field+' = ' in inv,field+' loaded')
        ok('"'+field+'": '+field in item,field+' snapshot')
        ok(field+' = ' in item,field+' restored')
    ok('def fresh_uid' not in uid,'GDScript-only rng')
    ok('item.apply_cosmetic_uid(GhostCosmeticRNGV152.fresh_uid())' in inv,'new items get ID')
    ok('item.apply_cosmetic_uid(GhostCosmeticRNGV152.fresh_uid())' in alt,'no deterministic altar reseeding')
    ok('item.item_seed' not in alt.split('func try_attune(')[1].split('func _process')[0],'altar leaves stat seed untouched')
    ok('func reroll_cosmetic_seed' in item and 'COSMETIC_RNG.fresh_uid()' in item,'rerolls use new UID')
    ok('func restore_cosmetic_look' in item and 'cosmetic_uid = str(snapshot.get' in item,'saved looks restore ID')
    ok('func visual_signature()' in item,'appearance exposes rare cosmetic-only roll')
    ok('"seed": item.item_seed' in inv,'legacy stat seed remains serialized')
    ok('"cosmetic_seed": item.cosmetic_seed' in inv, 'old cosmetic seed format retained')
    ok('item.cosmetic_uid = str(saved.get("cosmetic_uid", ""))' in inv,'old saves default gracefully')
    ok('item.rare_visual_mod = int(saved.get("rare_visual_mod", -1))' in inv,'old saves have no new visuals by default')
    ok('if not inventory.contents_changed.is_connected(refresh)' in vis,'dress cosmetic event refresh')
    ok('cloth_shader.set_shader_parameter("tint_strength", 1.0 if fabric != null else 0.0)' in vis,'dress tint does not require sword')
    ok('player_art.material = player_art.material.duplicate(true)' in vis,'independent per-instance material')
    ok('if dress_now != last_dress' in vis,'in-place dress palette reroll tracked')
    ok('float cloth_mask' in shaders and 'cloth_mask * tint_strength' in shaders,'dress recolor independent')
    ok('float spectral' in shaders and '* weapon_strength' in shaders,'weapon spectral mask independent')
    ok('id="v152_prestige_fx"' in scene and 'parent="Ghost"' in scene and 'name="EquippedPrestigeFX"' in scene,'static glow node in player scene')
    ok('player.get_node_or_null("Ghost/EquippedPrestigeFX")' in game,'game binds persistent visible node')
    ok('Node2D.new()' not in game.split('var prestige:')[0][-120:],'no legacy dynamic prestige spawn')
    ok('z_index = 4' in scene,'visible glow draw order')
    ok('var visual_signature_level' in fx and 'item.visual_signature()' in fx,'FX derives rare signature from equipped item')
    ok('func _draw_signature' in fx and 'draw_polyline' in fx and 'draw_arc' in fx,'rare appearance actually draws ribbons and arcs')
    ok('animation.begins_with("sword_")' in fx, 'idle and walking blade overlays')
    ok('animation.begins_with("attack_sword_")' in fx, 'attack blade overlays')
    for face in ['front','back','left','right']: ok('"'+face+'":' in fx,face+' frame guides exist')
    ok('18.0, true)' in fx and '8.0, true)' in fx, 'base sword glow broader than v1.51')
    ok('draw_circle(tip, 4.0' in fx,'very rare starflare visible')
    ok('if item.visual_signature() > 0:' in ui, 'rare mod details Alt-only')
    ok('return "\\n".join(out)' in ui,'regular tooltip compact remains')
    ok('cosmetic_uid' not in ui and 'cosmetic_seed' not in ui,'tooltip hides IDs')
    ok('rare_visual_mod' in panel,'favorites distinguish saved rare effects')
    ok('type="TextureRect" parent="Layout/DetailsWell/DetailsVBox/SeedRow"' in swatch, 'v1.51.1 TextureRect hotfix included')
    print(f'v1.52: {count}/{count} static integration checks passed')
    return count

if __name__=='__main__':
    project=Path(sys.argv[1]) if len(sys.argv)>1 else Path(__file__).resolve().parents[1]
    run(project)
