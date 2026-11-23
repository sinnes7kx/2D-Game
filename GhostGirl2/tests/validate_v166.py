"""Static-only validation of the v1.66 incremental overlay; not a Godot playtest."""
from pathlib import Path
import hashlib, json, re
from PIL import Image

root=Path(__file__).resolve().parents[1]
base=Path('/mnt/data/GhostGirl_v1.65_COMPLETE_Rebuilt_Project/GhostGirl2')
assert base.exists(), 'v1.65 base project not present for clean-overlay checks'

for name in ['thornrose','moonveil']:
    path=root/f'assets/equipment/bows_v166/{name}_carry_only_2048x1760.png'
    img=Image.open(path).convert('RGBA')
    assert img.size==(2048,1760)
    a=img.getchannel('A')
    assert a.getbbox() is not None
    for row in range(8):
        assert a.crop((0,row*220,256,(row+1)*220)).getbbox() is not None, (name,row)
    coverage=sum(v>60 for v in a.get_flattened_data())/(2048*1760)
    assert 0.001<coverage<0.08, (name,coverage)
    # Attacks still use previous source files, not this new hold overlay.

for name in ('malady','delirium','exile'):
    icon=root/f'assets/ui/jewels_v166/{name}.png'
    img=Image.open(icon)
    assert img.size==(96,96) and img.mode=='RGBA'
    item=(root/f'items/{name}_jewel.tres').read_text()
    old=(base/f'items/{name}_jewel.tres').read_text()
    for key in ('item_id','display_name','item_class','socket_bonus_id','socket_bonus_value','unique'):
        pat=r'^'+re.escape(key)+r'\s*=\s*.*$'
        assert re.search(pat,item,re.M).group()==re.search(pat,old,re.M).group(),(name,key)
    assert f'res://assets/ui/jewels_v166/{name}.png' in item

bow=(root/'scripts/bow_palette_overlay_v139.gd').read_text()
assert 'BowCarryV166' in bow and 'bow_carry_visual.flip_h' in bow
assert 'source_animation.begins_with("attack_")' in bow
assert 'Bow carry art missing' in bow
fx=(root/'scripts/weapon_prestige_fx.gd').read_text()
assert 'if face == "left":' in fx and 'start_pos.x = -start_pos.x' in fx
assert '_draw_socketed_jewel_echo' in fx
assert 'not ambient_particle_sources.is_empty()' in (root/'scripts/equipment_visuals.gd').read_text()
for j in ('malady_jewel','delirium_jewel','exile_jewel'):
    assert j in fx
markup=(root/'scripts/item_rich_text.gd').read_text()
assert 'UNIQUE JEWEL' in markup and 'if special:' in markup
panel=(root/'scripts/inventory_panel.gd').read_text()
assert 'socketed into' in panel

# Explicit scene node avoids a runtime add_child during child _ready().
scene=(root/'scenes/player.tscn').read_text()
assert '[node name="BowCarryV166" type="AnimatedSprite2D" parent="Ghost"]' in scene
assert scene.count('BowCarryV166')==1
# New res:// paths must resolve after the overlay.
for rel in ('scripts/bow_palette_overlay_v139.gd','items/malady_jewel.tres','items/delirium_jewel.tres','items/exile_jewel.tres'):
    script=(root/rel).read_text()
    for name in re.findall(r'res://([^"\']+)',script):
        if '%' in name or '\\' in name: continue
        assert (root/name).is_file() or (base/name).is_file(), (rel,name)

manifest=json.loads((root/'SHA256_MANIFEST_v166.json').read_text())
for rel,digest in manifest.items():
    assert hashlib.sha256((root/rel).read_bytes()).hexdigest()==digest

print('v1.66: 2 bow overlays (64 frames each), 3 jewels, script wiring, resource links, save-safe item definitions and SHA256: PASSED')
