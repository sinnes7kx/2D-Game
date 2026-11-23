"""v1.33 Bellglass Echoes / Warden cleanup.
Offline structural validation. Godot engine execution is still required.
"""
from pathlib import Path
from collections import Counter
import json, re, sys
ROOT = Path(__file__).resolve().parents[1]
issues=[]
def check(cond, msg):
    if not cond:
        issues.append(msg)

def read(rel):
    p=ROOT/rel
    check(p.is_file(),f'missing {rel}')
    return p.read_text(encoding='utf8') if p.is_file() else ''

room=read('scenes/rooms/hollow_veil_moor.tscn')
game=read('scripts/game.gd')
hud=read('scripts/hud.gd')
boss=read('scripts/moor_warden_v132.gd')
echo=read('scripts/bellglass_echo_v133.gd')
vault=read('scripts/bellglass_vault_v133.gd')
item=read('items/v133/bellglass_reliquary.tres')
old=ROOT.parent/'GhostGirl_v132_work'

# Hard parse checks for all modified scenes (the original moor once had a # comment error).
check(room.endswith('\n'), 'scene must end with newline')
check(not any(line.lstrip().startswith('#') for line in room.splitlines()), 'invalid .tscn # comment')
check(not any(line.startswith('<<<<<<<') or line.startswith('>>>>>>>') for line in room.splitlines()), 'merge conflict marker')
resource_count = len(re.findall(r'^\[(?:ext_resource|sub_resource) ',room,re.M))
got_steps = re.search(r'^\[gd_scene load_steps=(\d+) format=3\]',room,re.M)
check(got_steps is not None and int(got_steps.group(1)) == resource_count+1,'scene load_steps inaccurate')
nodes={'.'}
for lineno,line in enumerate(room.splitlines(),1):
    if line.startswith('[ext_resource'):
        match=re.search(r'path="res://([^"]+)"',line)
        check(bool(match),f'ext resource malformed {lineno}')
        if match:
            check((ROOT/match.group(1)).is_file(), f'missing scene ext resource at {lineno}: {match.group(1)}')
    if line.startswith('[node '):
        match=re.search(r'\bname="([^"]+)".*?\bparent="([^"]+)"',line)
        if match:
            name,parent=match.groups()
            check(parent in nodes,f'unknown scene parent {parent} for {name} on line {lineno}')
            path=name if parent=='.' else f'{parent}/{name}'
            check(path not in nodes,f'duplicate scene node {path}')
            nodes.add(path)

expected={
    'V133BellglassVault':'bellglass_vault_v133.gd',
    'V133WillowHookEcho':'bellglass_echo_v133.gd',
    'V133FenFrostEcho':'bellglass_echo_v133.gd',
    'V133RuinsBowEcho':'bellglass_echo_v133.gd',
    'V133BellglassGate':'rose_gate.gd',
    'V133BellglassChest':'treasure_chest.gd',
}
for node in expected:
    check(room.count(f'[node name="{node}"')==1,f'missing/duplicate node {node}')
for kind,key in [('hook','v133_bellglass_hook'),('frost','v133_bellglass_frost'),('airborne_bow','v133_bellglass_bow')]:
    check(room.count(f'echo_kind = "{kind}"')==1,f'missing/distorted echo kind {kind}')
    check(room.count(f'echo_id = "{key}"')==1,f'missing/distorted echo ID {key}')
    check(key in vault and key in game, f'echo id missing from HUD/vault {key}')
for needle in ('vault_path = NodePath("../V133BellglassVault")',
               'gate_path = NodePath("../V133BellglassGate")',
               'chest_path = NodePath("../../TreasureChests/V133BellglassChest")'):
    check(needle in room,f'invalid gate/vault linkage {needle}')
check('guaranteed_quality = "unique"' in room[room.index('[node name="V133BellglassChest"'):], 'reward not unique')
check('item_id = "v133_bellglass_reliquary"' in item and 'unique = true' in item and 'equip_slot = "charm"' in item,'charm template missing')
check('stat_id = "stamina_recovery_pct"' in item,'charm stat mismatch')
check('V133BellglassChest' in room and 'loot_data = ExtResource("v133_charm")' in room,'unique chest item not linked')
check('const WARDEN_FLAG: String = "v132_moor_warden_defeated"' in echo,'echo not gated behind Warden')
check('not _warden_defeated()' in echo and 'return false' in echo, 'echo lacks post-boss gate')
check('func on_hook_latched()' in echo and 'func on_moonfall()' in echo and 'func on_bow_hit(charged: bool, airborne: bool)' in echo,'echo mechanics incomplete')
check('charged and airborne' in echo,'airborne charged bow check absent')
check('"hook": add_to_group("hook_switch")' in echo, 'rose hook cannot target echo')
check('"frost": add_to_group("v130_triune_relay")' in echo, 'Moonfall cannot reach echo')
check('"airborne_bow": add_to_group("moon_archery_targets")' in echo, 'bow cannot target echo')
check('records[echo_id] = true' in echo and 'inventory.call("save_game")' in echo, 'echo save persistence incomplete')
check('func refresh_from_inventory(inventory: Node) -> void:' in vault and 'gathered == ECHO_IDS.size()' in vault, 'final vault gate incomplete')
check('if prop.has_method("restore_from_inventory"):' in game and 'Gameplay/V133Afterglow' in game, 'on-room-reload restoration incomplete')
check('func set_bellglass_status(' in hud and 'set_bellglass_status' in game, 'echo progress HUD missing')
check('v132_warden_summons' in boss and 'summoned_moth.queue_free()' in boss, 'boss temporary summons not cleaned on defeat')
check('user://ghost_girl_treasures_v2.json' in read('scripts/inventory.gd'),'save file changed')

# Existing resources (art, old spells, gameplay) must not be touched.
if old.exists():
    for rel in ('resources/ghost_extra_animations.json','resources/weapon_layer_manifest.json','scripts/moonfall_blizzard.gd','scripts/bow_arrow_v126.gd','assets/world/hollow_veil_moor_v118.jpg'):
        check((ROOT/rel).read_bytes()==(old/rel).read_bytes(),f'unexpected modification to {rel}')

# Check new nodes remain safely inside the 10368 x 6912 painted room.
for name in ('V133WillowHookEcho','V133FenFrostEcho','V133RuinsBowEcho','V133BellglassVault','V133BellglassChest'):
    m=re.search(r'^\[node name="'+re.escape(name)+r'"[^\n]+\nposition = Vector2\(([-\d.]+), ([-\d.]+)\)',room,re.M)
    check(bool(m),f'position missing for {name}')
    if m:
        x,y=map(float,m.groups())
        check(100 < x < 10268 and 100 < y < 6812,f'{name} is out of map bounds')

result={'version':'1.33','status':'PASS' if not issues else 'FAIL','echoes':3,'unique_reward':1,'waystones':4,'boss_summon_cleanup':True,'runtime_tested':False,'issues':issues}
print(json.dumps(result,indent=2))
if issues:
    sys.exit(1)
