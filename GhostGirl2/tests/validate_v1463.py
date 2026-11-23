#!/usr/bin/env python3
"""v1.46.3 static smoke checks. Checks source integration; NOT a Godot F5 runtime test."""
from pathlib import Path
import json, re
R=Path(__file__).resolve().parents[1]
errors=[]

def check(statement, message):
    if not statement: errors.append(message)

def src(path):
    p=R/path
    check(p.is_file(),'Missing '+path)
    return p.read_text(encoding='utf-8') if p.is_file() else ''

hud=src('scripts/hud.gd')
popup=src('scripts/item_compare_popup.gd')
instance=src('scripts/item_instance.gd')
inventory=src('scripts/inventory.gd')
ui=src('scripts/inventory_panel.gd')
equipment_ui=src('scripts/equipment_panel.gd')
scene=src('scenes/inventory_panel.tscn')
fx=src('scripts/weapon_prestige_fx.gd')
formatting=src('scripts/item_rich_text.gd')
altar=src('scripts/relic_attunement_v132.gd')
for token in ('hovered_item','Input.is_key_pressed(KEY_CTRL)','hovered_equipped if hover_ctrl_down else null',
              'hovered_equipped if ctrl_now else null','item.get_slot() == equipped.get_slot()'):
    check(token in hud,'CTRL gated tooltip missing: '+token)
check('button.tooltip_text = ("%s' not in equipment_ui, 'Duplicate native equipped tooltip still enabled')
check('var y: float = mouse.y + 20.0' in popup and '_place_popup()' in popup,
      'Hovered popup does not remain near pointer')
check('var comparing: bool = equipped != null and equipped != item' in popup,
      'Equipped panel should only be visible for compared item')
for token in ('cosmetic_seed: int = -1','saved_cosmetic_looks: Array[Dictionary]',
              'func reroll_cosmetic_seed()', 'func save_cosmetic_look()',
              'func restore_cosmetic_look(index: int)', 'func cosmetic_snapshot()',
              'func visual_seed()', 'apply_cosmetic_seed(number)', 'new_color != old_color'):
    check(token in instance,'Cosmetic seed/favorite system missing: '+token)
check('damage_rng.seed = absi(item_seed) + 612746' in instance,
      'Weapon damage must remain tied to original loot seed')
check('func all_stats() -> Dictionary:' in instance and 'for affix in affixes:' in instance,
      'Stat/affix calculations missing')
for token in ('"palette_index": item.palette_index', '"decoration_index": item.decoration_index',
              '"cosmetic_seed": item.cosmetic_seed',
              '"saved_cosmetic_looks": item.saved_cosmetic_looks.duplicate(true)',
              'saved.get("cosmetic_seed", -1)', 'saved.get("saved_cosmetic_looks", [])'):
    check(token in inventory,'Save compatibility missing: '+token)
for node in ('DetailsVBox','SeedRow','SeedDisplay','RerollSeed','SaveSeed','SavedSeeds'):
    check('name="'+node+'"' in scene, 'Inspected item editor control missing '+node)
for token in ('_reroll_selected_seed','_save_selected_seed','_restore_selected_seed',
              'inventory.save_game()','inventory.equipment_changed.emit()'):
    check(token in ui,'Cosmetic UI hook missing: '+token)
for token in ('item.visual_seed()', 'var blade_glow: bool',
              'draw_line(center_a, center_b', 'item.weapon_style() == "blade"'):
    check(token in fx,'Restrained sword glint missing: '+token)
check('item.cosmetic_seed = essence_seed' in altar,
      'Altars need named visual seed separate from gameplay seed')
check('LOOK  #%d' in formatting and 'LOOT SEED' in formatting,
      'Tooltips should show both loot seed and cosmetic seed')
# Validate the editor-authored hierarchy and the relocated ItemDescription path.
paths=set()
for line in scene.splitlines():
    if not line.startswith('[node '): continue
    nm=re.search(r'\bname="([^"]+)"',line)
    parent=re.search(r'\bparent="([^"]+)"',line)
    if not nm:continue
    name=nm.group(1)
    parent_path=parent.group(1) if parent else '.'
    full=name if parent_path=='.' else parent_path+'/'+name
    check(full not in paths,'Duplicate scene node '+full)
    if parent_path!='.':check(parent_path in paths,'Missing parent '+parent_path)
    paths.add(full)
check('Layout/DetailsWell/DetailsVBox/SeedRow/SavedSeeds' in paths,
      'Saved seed option is not in details container')
check('Layout/DetailsWell/DetailsVBox/ItemDescription' in paths,
      'ItemDescription parent should match GDScript onready')
for name in ('hud.gd','inventory_panel.gd'):
    code=src('scripts/'+name)
    check(not any(line.startswith('    ') for line in code.splitlines()),
          'Unexpected mixed indent in '+name)
print(json.dumps({'patch':'v1.46.3','status':'PASS' if not errors else 'FAIL',
                  'checks':'tooltip + seed generation + favorite persistence + sword FX + scene paths',
                  'runtime':'NOT RUN; Godot engine not available',
                  'errors':errors},indent=2))
if errors:raise SystemExit(1)
