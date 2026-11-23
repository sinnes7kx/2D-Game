from pathlib import Path
import json,zipfile,sys
root=Path(__file__).resolve().parents[1]
manifest=root/'resources/ghost_extra_animations.json'
if not manifest.exists(): raise SystemExit('FAIL: animation manifest missing')
data=json.loads(manifest.read_text(encoding='utf8'))
missing=[p for entry in data for p in entry['textures'] if not (root/p).exists()]
print('Base SpriteFrames:',(root/'resources/ghost_girl_frames.tres').exists())
print('Extra tracks:',len(data),'Referenced PNGs:',sum(len(x['textures']) for x in data),'Missing PNGs:',len(missing))
for path in missing[:12]:print('Missing optional animation:',path)
print('Static validation complete; Godot editor parse and gameplay still need testing.')
