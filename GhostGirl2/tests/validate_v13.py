#!/usr/bin/env python3
"""v1.3 tests: deterministic dimensions and layout/animation/save contracts."""
from pathlib import Path
from PIL import Image
import re, json, hashlib

root=Path(__file__).resolve().parents[1]
frames=(root/'resources/ghost_girl_frames.tres').read_text()
player=(root/'scripts/player.gd').read_text()
inv_scene=(root/'scenes/inventory_panel.tscn').read_text()
inventory=(root/'scripts/inventory_panel.gd').read_text()
equipment=(root/'scenes/equipment_panel.tscn').read_text()
popup=(root/'scripts/item_compare_popup.gd').read_text()
hud=(root/'scripts/hud.gd').read_text()
assert 'size_flags_vertical = 3' in inv_scene
assert '[node name="ItemDescription" type="RichTextLabel"' in inv_scene
assert 'fit_content = false' in inv_scene
assert 'tooltip_text = "%s\\n%s"' not in (root/'scripts/inventory_grid.gd').read_text()
assert 'func _difference_lines' in popup and 'DOUBLE_WIDTH' in popup and 'clampf(' in popup
assert 'item_compare_popup = $Overlay/ItemComparePopup' in hud
assert 'inventory_panel.visible = opening' in hud and 'equipment_panel.visible = opening' in hud
assert 'Wings" type="Button"' in equipment and 'Doll" type="TextureRect"' in equipment
assert 'user://ghost_girl_treasures_v2.json' in (root/'scripts/inventory.gd').read_text()
expected={}
for direction in ('front','back','left','right'):
    expected.update({'dodge_'+direction:16, 'hurt_'+direction:8,'attack_light_alt_'+direction:8,'attack_counter_'+direction:8,'attack_sword_'+direction:16})
for direction in ('front','back'):
    expected['hook_launch_'+direction]=16
for name,count in expected.items():
    m=re.search(r'"frames": \[([^]]+)\],\s*"loop": 0,\s*"name": &"'+name+r'"',frames)
    assert m, name
    assert len(re.findall(r'ExtResource\("[^"\n]+"\)',m.group(1)))==count, (name,count)
all_frames=list((root/'assets/ghost/combat_v13').glob('*.png'))
assert len(all_frames)==256, len(all_frames)
for imgfile in all_frames:
    with Image.open(imgfile) as img:
        assert img.size==(256,220), imgfile
        assert img.mode=='RGBA', imgfile
art_sources=root/'art_sources/combat_v13'
assert len(list(art_sources.glob('*8x8*2048x1760.png')))==5
for imgfile in art_sources.glob('*8x8*2048x1760.png'):
    with Image.open(imgfile) as img:
        assert img.size==(2048,1760), imgfile
with Image.open(root/'assets/effects/rose_slash_8x8_2048x1760.png') as img:
    assert img.size==(2048,1760) and img.mode=='RGBA'
assert 'attack_counter_' in player and 'hook_launch_' in player and '_spawn_rose_slash' in player
assert 'if struck:' in player
assert (root/'scenes/development/combat_v13_preview.tscn').exists()
print(json.dumps({'status':'ok','directional_animations':expected,'frame_pngs':len(all_frames), 'sprite_sheets':5, 'tooltip':'floating + bounded','inventory':'side-by-side equipment + backpack'},indent=2))
