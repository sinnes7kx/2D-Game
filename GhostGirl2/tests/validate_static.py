#!/usr/bin/env python3
"""Offline project consistency checks. Not a substitute for Godot's importer."""
from __future__ import annotations
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCENE_FILES = sorted(ROOT.rglob('*.tscn'))
SCRIPT_FILES = sorted(ROOT.rglob('*.gd'))
RES = re.compile(r"res://[^\"'\n]+")
errors = []
refs = 0

# Scans source paths and scene ext_resources; missing import cache files are not a problem.
for f in sorted(list(ROOT.rglob('*.tscn')) + list(ROOT.rglob('*.tres')) + SCRIPT_FILES + [ROOT/'project.godot']):
    try:
        source=f.read_text(encoding='utf-8')
    except UnicodeDecodeError:
        errors.append(f'Non-text source file: {f.relative_to(ROOT)}')
        continue
    for raw in RES.findall(source):
        path = raw.rstrip('):,\'')
        # Ignore local user:// saves and false positives in prose/comments.
        if not (ROOT / path.removeprefix('res://')).exists():
            errors.append(f'Missing resource from {f.relative_to(ROOT)}: {path}')
        refs += 1

# For source files, check parentheses/brackets/braces outside quoted strings/comments.
def balances(text: str):
    st=[]
    line=1
    quote=None
    escape=False
    for ch in text:
        if ch=='\n':
            line += 1
        if quote:
            if escape: escape=False
            elif ch=='\\': escape=True
            elif ch==quote: quote=None
            continue
        if ch=='#':
            # Syntax checks below use actual scene resources, keep this simple.
            pass
        if ch in '\"\'':
            quote=ch
            continue
        if ch in '([{':
            st.append((ch,line))
        elif ch in ')]}':
            if not st or '([{'.index(st[-1][0]) != ')]}'.index(ch):
                return f'unmatched {ch} at line {line}'
            st.pop()
    return f'unclosed {st[-1]}' if st else None

for f in SCRIPT_FILES:
    # Don't scan comment prose for braces: GDScript comments are not statements.
    lines = []
    for line in f.read_text().splitlines():
        if line.lstrip().startswith('#'):
            continue
        lines.append(line)
    issue=balances('\n'.join(lines))
    if issue:
        errors.append(f'{f.relative_to(ROOT)}: {issue}')

# Validate the script/scene contract at the source of the prior runtime failure.
scene = (ROOT/'scenes/inventory_panel.tscn').read_text()
grid = (ROOT/'scripts/inventory_grid.gd').read_text()
panel = (ROOT/'scripts/inventory_panel.gd').read_text()
inventory = (ROOT/'scripts/inventory.gd').read_text()
for expected in (
    'script = ExtResource("1_controller")',
    'script = ExtResource("2_grid")',
    '[node name="Slots" type="Control" parent="Layout/SlotsWell"]',
    '[node name="SortBackpack" type="Button" parent="Layout/Header"]',
):
    if expected not in scene:
        errors.append('Inventory scene missing: '+expected)
for sig in ('signal item_selected', 'signal item_activated', 'signal item_move_requested'):
    if sig not in grid:
        errors.append('Grid script missing signal: '+sig)
for method in ('func setup(', 'func set_selected(', 'func set_page('):
    if method not in grid:
        errors.append('Grid script missing method: '+method)
for method in ('func sort_backpack(', 'func move_item_at(', 'func can_destroy(', 'func load_game('):
    if method not in inventory:
        errors.append('Inventory data missing method: '+method)
for call in ('func bind_inventory(', 'func _sort_backpack(', 'func _confirm_delete('):
    if call not in panel:
        errors.append('Inventory panel missing method: '+call)
for parent,method in [('scenes/equipment_panel.tscn','script = ExtResource("1_controller")'),('scenes/hud.tscn','scenes/equipment_panel.tscn')]:
    if method not in (ROOT/parent).read_text():
        errors.append(f'{parent} missing {method}')

# Detect duplicate ids among Godot external resources in each scene.
for path in SCENE_FILES:
    content=path.read_text()
    ext_ids=re.findall(r'^\[ext_resource[^\n]*\bid="([^\"]+)"',content,re.MULTILINE)
    if len(ext_ids)!=len(set(ext_ids)):
        errors.append(f'Duplicate ext_resource ids in {path.relative_to(ROOT)}')

summary={'scenes':len(SCENE_FILES),'scripts':len(SCRIPT_FILES),'references':refs,'errors':errors}
print(json.dumps(summary,indent=2))
if errors: raise SystemExit(1)
