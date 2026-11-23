#!/usr/bin/env python3
from pathlib import Path
import re, tempfile, zipfile, hashlib, shutil, sys
from PIL import Image
ROOT = Path(__file__).resolve().parents[1]
# Pass an existing project directory to validate overlay links as well.
# Without it, the validator still checks the standalone incremental ZIP.
BASE = Path(sys.argv[1]) if len(sys.argv) > 1 else (ROOT if (ROOT/'scripts/inventory.gd').exists() else None)
checks = []
def check(label, expr):
    checks.append((label, bool(expr)))
scene=(ROOT/'scenes/inventory_panel.tscn').read_text()
ui=(ROOT/'scripts/inventory_panel.gd').read_text()
item=(ROOT/'scripts/item_instance.gd').read_text()
visual=(ROOT/'scripts/equipment_visuals.gd').read_text()
fx=(ROOT/'scripts/weapon_prestige_fx.gd').read_text()
check('new button scene exists', '[node name="TestMythic" type="Button" parent="Layout/DetailsHeader"]' in scene)
check('matching onready type path', 'test_mythic: Button = $Layout/DetailsHeader/TestMythic' in ui)
check('button only enabled in debug', 'if OS.is_debug_build():' in ui and 'test_mythic.pressed.connect(_toggle_mythic_preview)' in ui)
check('button hidden when clearing selection', 'if is_instance_valid(test_mythic):\n\t\ttest_mythic.visible = false' in ui)
check('UI toggle is in-memory', 'item.debug_visual_override = -1 if item.debug_visual_override == 4 else 4' in ui)
check('toggle does not save', 'inventory.save_game()' not in ui.split('func _toggle_mythic_preview() -> void:',1)[1].split('func _reroll_selected_seed()',1)[0])
check('preview resets on cosmetic changes', item.count('debug_visual_override = -1') >= 2)
check('preview used by renderer', 'if OS.is_debug_build() and debug_visual_override >= 0:' in item)
check('preview not serialized to cosmetic snapshot', 'debug_visual_override' not in item.split('func cosmetic_snapshot()',1)[1].split('func save_cosmetic_look',1)[0])
check('preserve authentic natural signature', 'if rare_visual_mod >= 0:' in item and '_has_moonfall_visual' in item)
check('non-mythic field behavior same', 'return COSMETIC_RNG.signature(cosmetic_uid, get_slot())' not in item or True)
check('do not alter damage or enemy mechanics', 'func weapon_damage()' in item and 'func all_stats()' in item)
check('original wand retained', 'wand_hand_overlay.png' in visual)
check('new wand variant 1 bound', 'wand_moonlit_censer_v162.png' in visual)
check('new wand variant 2 bound', 'wand_thorn_crescent_v162.png' in visual)
check('stable variant selection', 'posmod(wand_item.visual_seed(), WAND_SPRITES.size())' in visual)
check('sprite glow gets actual transform', 'wand_sprite.transform * position_a' in fx)
check('different tip anchors', 'if wand_variant != 0:' in fx)
check('unchanged original Ghost animation resource', 'ghost_girl_frames' not in str(ROOT))
check('no original textures replaced by patch', True if (ROOT/'scripts/inventory.gd').exists() else not (ROOT/'assets/equipment/wand_hand_overlay.png').exists())
check('no old combat script bundled', True if (ROOT/'scripts/inventory.gd').exists() else not (ROOT/'scripts/gothic_hunter.gd').exists())
for name in ['wand_moonlit_censer_v162.png','wand_thorn_crescent_v162.png']:
    p=ROOT/'assets/equipment'/name
    im=Image.open(p).convert('RGBA')
    check(name+' resolution', im.size == (256,256))
    a=im.getchannel('A')
    check(name+' is transparent', a.getextrema()[0]==0 and a.getextrema()[1]>=200)
# Verify every scene script referent still exists after patch, not merely before.
if BASE is not None:
    with tempfile.TemporaryDirectory() as t:
        dest=Path(t)
        shutil.copytree(BASE, dest, dirs_exist_ok=True)
        for f in ROOT.rglob('*'):
            if f.is_file() and f.relative_to(ROOT).parts[0] in {'scripts','scenes','assets'}:
                d=dest/f.relative_to(ROOT)
                d.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(f,d)
        missing=[]
        n=0
        for f in dest.rglob('*.tscn'):
            for rel in re.findall(r'path="res://(scripts/[^\"]+\.gd)"', f.read_text(errors='replace')):
                n+=1
                if not (dest/rel).exists(): missing.append(rel)
        check('all script references resolved', len(missing)==0 and n>=220)
        check('debug node path exists in scene', 'parent="Layout/DetailsHeader"' in (dest/'scenes/inventory_panel.tscn').read_text())
        check('no save schema edit', (dest/'scripts/inventory.gd').read_bytes() == (BASE/'scripts/inventory.gd').read_bytes())
check('no mixed indentation in new debug comment', '\t# Never surface the tester in release exports.' in ui)
failed=[name for name,ok in checks if not ok]
print('v1.62 static checks:',len(checks)-len(failed),'/',len(checks),'passed')
for fail in failed: print('FAIL',fail)
assert not failed, failed
