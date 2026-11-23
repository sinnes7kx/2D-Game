#!/usr/bin/env python3
"""Verify a fully extracted Ghost Girl Godot source project without launching Godot."""
from pathlib import Path
import re,sys,collections
root=Path(__file__).resolve().parent.parent
exts={'.tscn','.tres','.gd','.godot'}
missing=[]; checked=0; broken=[]
for f in root.rglob('*'):
    if not f.is_file() or f.suffix not in exts: continue
    text=f.read_text(encoding='utf-8-sig',errors='replace')
    # Ignore generated/imported aliases and runtime user://; all literal res:// dependencies are real files.
    for path in re.findall(r'res://([^\"\'\n\r]+)',text):
        # Literal values may include special interpolation or whitespace; keep file-backed paths only.
        if path.endswith(('.png','.jpg','.jpeg','.webp','.svg','.wav','.ogg','.mp3','.tres','.tscn','.gd','.json','.ttf','.otf','.import','.txt','.cfg','.shader','.gdshader','.csv')):
            checked+=1
            if not (root/path).is_file(): missing.append((f.relative_to(root),path))
    if f.suffix in {'.tscn','.tres'}:
        ids=set(re.findall(r'^\[ext_resource[^\n]*id="([^"\n]+)"',text,re.M))
        refs=set(re.findall(r'ExtResource\("([^"\n]+)"\)',text))
        for rid in sorted(refs-ids): broken.append((f.relative_to(root),'Undeclared ExtResource '+rid))
critical=['project.godot','scenes/main.tscn','scenes/player.tscn','resources/ghost_girl_frames.tres','assets/ghost/idle_front_00.png','assets/ghost/combat_v14/attack_unarmed_light_front_00.png','assets/ghost/combat_v14/attack_sword_light_front_00.png','assets/world/moonwake_crypt.png']
for name in critical:
    if not (root/name).is_file(): missing.append(('[critical]',name))
print('Ghost Girl v1.4.1 - install check')
print(f'Project: {root}')
print(f'References inspected: {checked} | missing files: {len(missing)} | bad resource IDs: {len(broken)}')
for a,b in missing[:50]: print('MISSING:',a,'->',b)
for a,b in broken[:50]: print('BROKEN:',a,'->',b)
if missing or broken:
    print('FAIL - all THREE old v1.4 archives must be merged into one folder, or use the single-file v1.4.1 archive.')
    sys.exit(1)
print('PASS - static references are present. This check cannot replace running Godot.')
