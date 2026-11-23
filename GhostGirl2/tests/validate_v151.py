#!/usr/bin/env python3
"""Ghost Girl v1.51 static overlay check; DOES NOT execute the Godot game."""
from pathlib import Path
import hashlib,re,sys,zipfile
ROOT = Path(__file__).resolve().parents[1]
if len(sys.argv)>1: ROOT=Path(sys.argv[1])
checks=[]
def require(v,label): checks.append((label,bool(v)))
def read(path):
 p=ROOT/path;require(p.is_file(),f'{path} exists');return p.read_text(encoding='utf-8') if p.is_file() else ''
markup=read('scripts/item_rich_text.gd')
popup=read('scripts/item_compare_popup.gd')
hud=read('scripts/hud.gd')
panel=read('scripts/inventory_panel.gd')
instance=read('scripts/item_instance.gd')
fx=read('scripts/weapon_prestige_fx.gd')
for source,name in [(markup,'markup'),(popup,'popup'),(hud,'hud'),(panel,'panel'),(instance,'item'),(fx,'glow')]:
 require('<<<<<<<' not in source and '>>>>>>>' not in source,name+' no merge markers')
 require(re.search(r'^ +\t|^\t+ +\S',source,re.M) is None,name+' no mixed leading indent')
 require(source.count('func _ready(') <= 1,name+' no duplicate ready')
 require(source.count('func _process(') <= 1,name+' no duplicate process')
for token in ['static func item_info(item: Variant, advanced: bool = false)','static func _cosmetic_dots','ALT  ·  Advanced & appearance','VISUAL EFFECTS','On hit  ·  ','Aura  ·  ','Trail  ·  ','Spell  ·  ','Sockets (','stats.keys()']:
 require(token in markup,'compact ALT text '+token)
for text in ['Loot seed','Look #','palette · Ornament','%s palette','Visual imprint']:
 require(text not in markup,'no default cosmetic clutter '+text)
require(markup.index('if not advanced:') < markup.index('VISUAL EFFECTS'), 'visual details only on ALT')
require('if advanced:\n            for jewel in item.socketed' in markup, 'socket gem names behind ALT')
require('"Loot seed' not in instance and 'Look #%d' not in instance,'legacy details never print seed IDs')
require('func details(advanced: bool = false)' in instance,'legacy details compact by default')
for token in ['var hover_alt_down: bool = false','Input.is_key_pressed(KEY_ALT)','ctrl_now != hover_ctrl_down or alt_now != hover_alt_down','item_compare_popup.call("display_item", hovered_item, compare_item, alt_now)']:
 require(token in hud,'HUD live ALT + CTRL '+token)
for token in ['advanced: bool = false','ITEM_MARKUP.item_info(item, advanced)','ITEM_MARKUP.item_info(equipped, advanced)','clampf(68.0 + lines * 22.0']:
 require(token in popup,'hover popup + '+token)
for token in ['var selected_alt_down: bool = false','func _process(_delta: float)','if selected_alt_down != new_alt:','ITEM_MARKUP.item_info(item, selected_alt_down)']:
 require(token in panel,'selected panel ALT + '+token)
require('hovered_equipped = equipped if item != null and equipped != null' in hud, 'CTRL comparison restricted to matching equipped slots')
for token in ['func _blade_span(animation: String, face: String, frame_index: int)','return _blade_span(animation, face, body.frame)','if blade_glow:','var beam_power: float','draw_line(begin, finish','draw_circle(finish, 1.55','if attacking:','effect_intensity: float = 1.0']:
 require(token in fx,'blade FX + '+token)
require('return _blade_span(animation, face, body.frame)' in fx and 'body.to_local(hand.global_position)' in fx, 'swords use frame-local positions; wands keep hand')
require('style_index < 0 and not blade_glow' in fx, 'blade works without prestige')
require('if blade_glow and style_index < 0 and not str(body.animation).begins_with' not in fx,'normal sword idle glow no longer suppressed')
for facing in ['front','back','left','right']:
 require('"'+facing+'":\n' in fx,'four directional blade guides '+facing)
# The source atlas is supplied in the user base files, not shipped again in this small patch.
manifest=ROOT/'resources/ghost_extra_animations.json'
if manifest.is_file():
 import json
 data=json.loads(manifest.read_text(encoding='utf8'))
 entries={x.get('name') for x in data if isinstance(x,dict)}
 for name in ['sword_idle_front','sword_idle_back','sword_idle_left','sword_idle_right','attack_sword_light_front','attack_sword_heavy_front']:
  require(name in entries,'required manifest animation '+name)
# Only changed scripts; gameplay stats/save keys/scene artwork must remain unmodified in patch.
require('item_seed = ' not in markup and 'inventory.save_game()' not in markup,'display layer cannot reroll or save')
errors=[name for name,passed in checks if not passed]
print(f'v1.51: {len(checks)-len(errors)}/{len(checks)} static checks passed')
for e in errors: print('FAIL:',e)
sys.exit(1 if errors else 0)
