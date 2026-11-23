"""Ghost Girl v1.39 source / resource / pixel checks (not an F5 playtest)."""
from pathlib import Path
from collections import Counter
from PIL import Image
import json, re, hashlib
R=Path(__file__).resolve().parents[1]
errors=[]
def check(cond,message):
    if not cond: errors.append(message)

manifest=json.loads((R/'resources/ghost_extra_animations.json').read_text())
for style in ('thornrose','moonveil'):
    combat=R/f'assets/ghost/bows_v139/{style}_combat_2048x1760.png'
    check(combat.is_file(),f'missing {combat}')
    if combat.is_file():
        img=Image.open(combat).convert('RGBA')
        check(img.size==(2048,1760),f'bad combat size {style}')
        for row in range(8):
            for col in range(8):
                tile=img.crop((col*256,row*220,(col+1)*256,(row+1)*220))
                check(tile.getbbox() is not None,f'blank {style} {row}/{col}')
    for kind in ('combat','locomotion'):
        mask=R/f'assets/ghost/bows_v139/{style}_{kind}_mask_2048x1760.png'
        check(mask.is_file(),f'missing tint mask {mask}')
        if mask.is_file():
            im=Image.open(mask).convert('RGBA')
            check(im.size==(2048,1760),f'incorrect tint mask dimensions {style}/{kind}')
            for row in range(8):
                for col in range(8):
                    tile=im.crop((col*256,row*220,(col+1)*256,(row+1)*220))
                    check(tile.getbbox() is not None,f'blank mask {style} {kind} row {row}, frame {col}')
    names=[e['name'] for e in manifest if e.get('name','').startswith('attack_'+style+'_')]
    check(len(names)==8,f'expected 8 combat animations for {style}, got {len(names)}')
    for e in manifest:
        if e.get('name','') in names:
            check(e.get('atlas','').endswith('/bows_v139/'+style+'_combat_2048x1760.png'),f'outdated bow animation {e.get("name")}')

player=(R/'scripts/player.gd').read_text()
for part in ['BOW_FULL_DRAW_TIME','bow_draw_active','Input.is_action_pressed("attack_heavy")','func _advance_bow_draw(delta: float)','func _release_bow_charge()','body_art.pause()','body_art.set_frame_and_progress(6, 0.0)','_launch_bow_arrow(bow_firing_direction, fully_drawn)']:
    check(part in player,'player lacks '+part)
check(player.index('func _advance_bow_draw')<player.index('func _release_bow_charge'), 'bow draw/hold/release ordering wrong')
check('_launch_bow_arrow(bow_firing_direction, bow_charge)' not in player, 'legacy timer autoshot survived')

for rel in ['scripts/procedural_relic_palette_v139.gd','scripts/bow_palette_overlay_v139.gd','assets/equipment/bow_palette_v139.gdshader','scripts/elemental_flammable_v139.gd','scripts/elemental_ice_bridge_v139.gd','scripts/elemental_light_secret_v139.gd','tools/build_bow_draw_v139.py','tools/build_bow_masks_v139.py']:
    check((R/rel).is_file(), 'missing new source '+rel)
rng=(R/'scripts/procedural_relic_palette_v139.gd').read_text()
for token in ('rng.seed','gradient_angle','pulse_speed','spark_count','geometry','motion','spin','Color.from_hsv'):
    check(token in rng,'RNG missing '+token)
check('rng.randomize()' not in rng,'generator not deterministic')
check('procedural_look' in (R/'scripts/bow_arrow_v126.gd').read_text(), 'arrow does not use procedural look')
check('GhostProceduralRelicV139' in (R/'scripts/weapon_prestige_fx.gd').read_text(), 'equipped prestige effects are not connected')
scene=(R/'scenes/rooms/hollow_veil_moor.tscn').read_text()
for obj in ('DryThornwood','RottedBrazier','WesternIcePassage','NorthernIcePassage','ForgottenLight1','V139FireChest','V139LightChest'):
    check('name="'+obj+'"' in scene,'missing world prop '+obj)
check('Gameplay/V139ElementalWorld' in (R/'scripts/game.gd').read_text(), 'no room persistence binding')
check('Ghost/BowPaletteV139' in (R/'scripts/game.gd').read_text(), 'shader layer not bound to inventory')
check('parent="Ghost"' in (R/'scenes/player.tscn').read_text() and 'BowPaletteV139' in (R/'scenes/player.tscn').read_text(), 'missing equipped bow tint node')
for kind in ['v139_fire','v139_ice','v139_light']:
    check('id="'+kind+'"' in scene, f'missing resource reference {kind}')
# Scan scene comments and external resources: old v1.20 parser failure was a bad # comment.
for line_no,line in enumerate(scene.splitlines(),1):
    check(not line.lstrip().startswith('#'), f'.tscn illegal # comment at {line_no}')
for ref in re.findall(r'\[ext_resource[^\]]*path="res://([^"]+)"',scene):
    check((R/ref).exists(),f'missing scene resource: {ref}')
# Ensure the scene's declared load_steps isn't undercounted (Godot may accept larger counts).
resource_count=scene.count('[ext_resource')+scene.count('[sub_resource')
m=re.search(r'\[gd_scene load_steps=(\d+)',scene)
check(m is not None and int(m.group(1))>=resource_count+1,f'scene load_steps undercount: {resource_count}')

print(json.dumps({'version':'1.39','status':'PASS' if not errors else 'FAIL','new_combat_frames':128,'new_bow_masks':4,'world_nodes':7,'errors':errors},indent=2))
if errors: raise SystemExit(1)
