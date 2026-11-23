"""Independent v1.5 static smoke test. No Godot binary needed."""
from pathlib import Path
from collections import Counter
import json,re
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
errors=[]
assert (ROOT/'project.godot').exists()
assert (ROOT/'scenes/main.tscn').exists()

# Every script and resource path is present, no references to absent frames.
count=0
for f in ROOT.rglob('*'):
    if f.suffix not in ('.tscn','.tres','.gd') or not f.is_file():continue
    content=f.read_text(errors='replace')
    for pattern in [r'path="(res://[^"\n]+)"',r'preload\("(res://[^"\n]+)"\)',r'load\("(res://[^"\n]+)"\)']:
        for ref in re.findall(pattern,content):
            count+=1
            if not (ROOT/ref[6:]).exists():errors.append(f'{f.relative_to(ROOT)} missing {ref}')
    if f.suffix in ('.tscn','.tres'):
        exts=re.findall(r'\[ext_resource[^\]]* id="([^"]+)"\]',content)
        subs=re.findall(r'\[sub_resource[^\]]* id="([^"]+)"\]',content)
        for pattern,existing in [(r'ExtResource\("([^"]+)"\)',exts),(r'SubResource\("([^"]+)"\)',subs)]:
            for used in re.findall(pattern,content):
                if used not in existing:errors.append(f'{f.relative_to(ROOT)} broken resource id {used}')
        if len(exts)!=len(set(exts)) or len(subs)!=len(set(subs)):
            errors.append(f'{f.relative_to(ROOT)} duplicate IDs')

manifest=json.loads((ROOT/'resources/ghost_extra_animations.json').read_text())
for anim in manifest:
    for texture in anim.get('textures',[]):
        if not (ROOT/texture).is_file(): errors.append(f'Missing frame {texture}')
for atlas in (ROOT/'art_sources').rglob('*.png'):
    with Image.open(atlas) as im:
        if ('2048x1760' in atlas.name or '_8x8_' in atlas.name) and im.size!=(2048,1760):
            errors.append(f'Atlas dimension changed: {atlas}')

player=(ROOT/'scripts/player.gd').read_text()
for key in ['buffered_attack_direction','buffered_attack_valid','_combat_aim_direction','func _queue_combat','func _begin_attack','func _begin_dodge']:
    if key not in player:errors.append(f'Melee directional aim missing {key}')

hook=(ROOT/'scripts/rose_hook.gd').read_text()
for key in ['MODE_SWITCH','hook_switch','on_hook_latched','MODE_OBJECT','MODE_ANCHOR']:
    if key not in hook:errors.append(f'Hook interaction missing {key}')

numbers={}
for area,expected in [('blackbrick_court',7),('ashen_causeway',9),('ashglass_vault',8),('bellwether_court',10),('candle_reliquary',5)]:
    s=(ROOT/f'scenes/rooms/{area}.tscn').read_text()
    n=len(re.findall(r'\[node name="[^"]+" parent="Gameplay/Enemies"',s))
    numbers[area]=n
    if n!=expected:errors.append(f'{area} expected {expected} enemies got {n}')
    if 'parent="Gameplay/HookAnchors"' not in s and area in ['blackbrick_court','ashen_causeway']:
        errors.append(f'{area} missing hook anchors')
for area in ['blackbrick_court','ashen_causeway']:
    s=(ROOT/f'scenes/rooms/{area}.tscn').read_text()
    for key in ['RoseSealGate','RoseSealSwitch','v15_switch','v15_gate','gate_path','discovery_id']:
        if key not in s:errors.append(f'{area} missing {key}')

inv=(ROOT/'scripts/inventory.gd').read_text()
if 'ghost_girl_treasures_v2.json' not in inv:errors.append('Inventory save path changed')
if '"quality": item.quality' not in inv:errors.append('Saved item quality serialization missing')
if 'str(saved.get("quality", "normal"))' not in inv:errors.append('Saved quality restoration missing')

result={'status':'PASS' if not errors else 'FAIL','scenes':len(list(ROOT.rglob('*.tscn'))),'resources_checked':count,'animation_tracks':len(manifest),'new_enemy_counts':numbers,'errors':errors}
print(json.dumps(result,indent=2))
if errors:raise SystemExit(1)
