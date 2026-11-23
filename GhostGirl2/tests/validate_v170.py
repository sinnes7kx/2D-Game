#!/usr/bin/env python3
"""Static and asset-integrity checks for the v1.70 incremental patch."""
from pathlib import Path
from PIL import Image
import json, re, sys, hashlib
P=Path(__file__).resolve().parents[1]
BASELINE=json.loads((P/'tests/manifest_v169_baseline.json').read_text())
required={
'scripts/player.gd':['func _weapon_art_style()', '"ashglass_warmaul_v170"', '"rosemirror_twinblade_v170"','"maul"','"twinblade"'],
'scripts/item_instance.gd':['"maul": return 0.67','"twinblade": return 0.36','"maul": return 173.0'],
'scripts/item_data.gd':['"twinblade"','"maul"'],
'scripts/game.gd':['res://items/gravebell_maul_v170.tres','res://items/ashglass_warmaul_v170.tres','res://items/eclipse_twinblade_v170.tres','res://items/rosemirror_twinblade_v170.tres'],
'scripts/weapon_prestige_fx.gd':['NEW_WEAPON_AXES_V170','v170_axes_by_animation','style == "twinblade"','style == "maul"'],
}
checks=0
for rel, tokens in required.items():
    content=(P/rel).read_text()
    for token in tokens:
        assert token in content,(rel,token)
        checks+=1
new_manifest=json.loads((P/'resources/ghost_extra_animations.json').read_text())
base_len=int(BASELINE['original_animation_count'])
canonical=json.dumps(new_manifest[:base_len],sort_keys=True,separators=(',',':'),ensure_ascii=False).encode()
assert hashlib.sha256(canonical).hexdigest()==BASELINE['original_prefix_sha256']
assert len(new_manifest)-base_len==64
checks+=2
axes=json.loads((P/'resources/new_weapon_axes_v170.json').read_text())
assert len(axes)==64
checks+=1
sides=['front','back','left','right']
allnames={e['name'] for e in new_manifest}
for art in ['maul','ashglass_maul','twinblade','rosemirror_twinblade']:
    for family in ['locomotion','combat']:
        path=P/f'assets/equipment/weapons_v170/{art}_{family}_2048x1760.png'
        with Image.open(path) as atlas:
            assert atlas.size==(2048,1760)
            assert atlas.mode=='RGBA'
            for motion in (['idle','walk'] if family=='locomotion' else ['light','heavy']):
                for face in sides:
                    name=f'{art}_{motion}_{face}' if family=='locomotion' else f'attack_{art}_{motion}_{face}'
                    assert name in allnames
                    data=axes[name]
                    assert len(data)==8
                    for pair in data:
                        assert len(pair)==4 and all(-130 <= float(x) <= 130 for x in pair)
                    checks+=1
        checks+=1
for item_id in ['gravebell_maul_v170','ashglass_warmaul_v170','eclipse_twinblade_v170','rosemirror_twinblade_v170']:
    resource=(P/f'items/{item_id}.tres').read_text()
    assert f'item_id = "{item_id}"' in resource
    icon=re.search(r'path="res://([^"]+\.png)"',resource)
    assert icon is not None
    with Image.open(P/icon.group(1)) as img:
        assert img.size==(96,96) and img.getbbox() is not None
    assert 'equip_slot = "sword"' in resource
    checks+=4
# Existing sources should not be modified in unrelated ways.
assert (P/'scripts/item_instance.gd').read_text().count('cosmetic_uid: String') == 1
for name in ['dagger_idle_front','spear_idle_front','attack_dagger_heavy_right','attack_spear_light_left']:
    assert name in allnames
    checks+=1
assert (P/'scripts/player.gd').read_text().count('func _launch_bow_arrow')==1
assert (P/'scripts/game.gd').read_text().count('const BOW_LOOT_TABLE')==1
checks+=2
print(f'v1.70 static integration validation PASSED: {checks} checks')
