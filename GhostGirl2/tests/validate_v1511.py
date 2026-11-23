from pathlib import Path
import re,sys
root=Path(__file__).resolve().parents[1]
scene=(root/'scenes/inventory_panel.tscn').read_text(encoding='utf-8')
assert re.search(r'^\[node name="SeedDisplay" type="TextureRect" parent="Layout/DetailsWell/DetailsVBox/SeedRow"\]$',scene,re.M)
assert 'custom_minimum_size = Vector2(54, 16)' in scene
print('PASS: inventory swatch TextureRect is in the correct scene path')
