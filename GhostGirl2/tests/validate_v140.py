#!/usr/bin/env python3
"""Ghost Girl v1.40 offline integration checks (not a Godot runtime test)."""
from pathlib import Path
import json, posixpath, re

ROOT=Path(__file__).resolve().parents[1]
issues=[]

def check(predicate, explanation):
    if not predicate:
        issues.append(explanation)

scenes=['hollow_veil_moor','moonthorn_woods','blackbrick_court']
counts={}
for scene_name in scenes:
    rel=f'scenes/rooms/{scene_name}.tscn'
    text=(ROOT/rel).read_text()
    check('res://scripts/elemental_kindling_v140.gd' in text, f'{scene_name} lacks fire script')
    check('res://scripts/elemental_hidden_relic_v140.gd' in text, f'{scene_name} lacks hidden-light script')
    check(not re.search(r'^\s*#',text,re.M),f'Invalid # comment in {rel}')
    defined_paths={}
    all_node_declarations=re.findall(r'^\[node name="([^"]+)".*? parent="([^"]+)".*?\]$',text,re.M)
    for node_name,parent in all_node_declarations:
        absolute=node_name if parent=='.' else parent+'/'+node_name
        check(absolute not in defined_paths,f'Duplicate scene node {scene_name}:{absolute}')
        defined_paths[absolute]=True
        if parent != '.':
            check(parent in defined_paths,f'Parent {parent} missing or declared after child {absolute} in {scene_name}')
    for resource in re.findall(r'\[ext_resource [^\]]+ path="res://([^"]+)"',text):
        check((ROOT/resource).is_file(),f'Bad resource {scene_name}: {resource}')
    for match in re.finditer(r'\[node name="(HiddenMoonmark\d+)".*?parent="Gameplay/V140ElementalWorld"\]\n(?:[^\[]*?)reward_chest_path = NodePath\("([^"]+)"\)',text,re.S):
        node,relative=match.groups()
        source=f'Gameplay/V140ElementalWorld/{node}'
        target=posixpath.normpath(posixpath.join(source,relative))
        check(target in defined_paths,f'{scene_name} hidden chest path not resolved: {target}')
    flags=re.findall(r'^(?:flag_id|discovery_id|chest_id) = "(v140_[^"]+)"',text,re.M)
    check(len(flags)==len(set(flags)),f'Duplicate save flags in {scene_name}')
    check('V140ElementalWorld' in text,f'v140 container absent in {scene_name}')
    counts[scene_name]={
        'flammable_nodes': len(re.findall(r'^\[node name="Kindling\d+"',text,re.M)),
        'hidden_secrets':len(re.findall(r'^\[node name="HiddenMoonmark\d+"',text,re.M)),
        'linked_chests':len(re.findall(r'^\[node name="V140LightChest\d+"',text,re.M)),
    }
    check(counts[scene_name]['hidden_secrets']==counts[scene_name]['linked_chests'],f'{scene_name} reveal/chest count mismatch')
check(counts['hollow_veil_moor']['flammable_nodes']>=12,'Not enough moor kindling sites')
check(counts['hollow_veil_moor']['hidden_secrets']>=4,'Not enough moor light secrets')
check(all(counts[n]['flammable_nodes']>=3 for n in scenes[1:]),'Earlier rooms should also have fire clusters')

source={p:(ROOT/p).read_text() for p in [
 'scripts/bow_arrow_v126.gd',
 'scripts/water_body.gd',
 'scripts/breakable_cover_v136.gd',
 'scripts/game.gd',
 'scripts/elemental_flammable_v139.gd',
 'scripts/elemental_kindling_v140.gd',
 'scripts/elemental_hidden_relic_v140.gd',
]}
arrow=source['scripts/bow_arrow_v126.gd']
for snippet in ['func _reveal_hidden_near_sweep(', 'func _freeze_water_on_sweep(', 'water.call("freeze_arrow_segment", start, end, 10.0)', 'cover.call("ignite_from_environment")']:
    check(snippet in arrow,f'Bow arrows missing {snippet}')
check('freeze_arrow_segment(' in source['scripts/water_body.gd'],'Water cannot form temporary ice bridge')
check('get_closest_point_to_segment(local_point, patch["a"], patch["b"])' in source['scripts/water_body.gd'],'Frozen path lacks movement effect')
check('draw_colored_polygon(corners' in source['scripts/water_body.gd'],'Frozen path lacks ice rendering')
check('v140_light_reveal' in (ROOT/'scripts/elemental_light_secret_v139.gd').read_text(),'Old light secrets cannot be revealed by light proximity')
check('v140_flammable' in source['scripts/elemental_flammable_v139.gd'],'Old fire does not spread to new dry roots')
check('ignite_from_environment()' in source['scripts/breakable_cover_v136.gd'],'Destructible cover cannot ignite')
check('Gameplay/V140ElementalWorld' in source['scripts/game.gd'],'New room props do not restore from saves')
check('on_elemental_arrow_hit(element: int' in source['scripts/elemental_kindling_v140.gd'],'New dry roots cannot be ignited with fire arrow')
check('reveal_from_light(world_point: Vector2)' in source['scripts/elemental_hidden_relic_v140.gd'],'New hidden objects cannot be revealed with light')
# The normal projectile remains a single physics hit path, not visual multi-hit.
check('query.collision_mask = 16 | 32' in arrow and 'hit_ids[target_id] = true' in arrow,'Bow one-hit collision path altered')

result={'version':'1.40','status':'PASS' if not issues else 'FAIL','room_counts':counts,'issues':issues,'validation':'static only; Godot F5 playtest required'}
print(json.dumps(result,indent=2))
if issues:
    raise SystemExit(1)
