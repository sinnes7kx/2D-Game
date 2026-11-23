#!/usr/bin/env python3
"""Offline v1.50 overlay checker. Static checks only: no Godot runtime test implied."""
from pathlib import Path
from zipfile import ZipFile
import hashlib, json, re, sys

def validate(project: Path) -> int:
    checks = 0
    def require(ok, explanation):
        nonlocal checks
        checks += 1
        if not ok: raise AssertionError(f'Check {checks}: {explanation}')
    def source(path):
        file = project / path
        require(file.is_file(), f'{path} exists')
        return file.read_text(encoding='utf8')
    player=source('scripts/player.gd')
    enemy=source('scripts/gothic_hunter.gd')
    destruct=source('scripts/breakable_cover_v136.gd')
    particles=source('scripts/impact_burst_v149.gd')
    floor=source('scripts/floor_breach_v1464.gd')
    require('const AIR_LANDING_BUFFER: float = 0.19' in player, 'late-air input window')
    require('started_air_attack = jump_attack_active' in player, 'no duplicate strike on jump button')
    require('if jump_time_left <= AIR_LANDING_BUFFER and not started_air_attack:' in player, 'land buffering gated')
    require('_queue_combat("dodge")' in player and '_queue_combat("light")' in player, 'buffered ground controls')
    require('for object in get_tree().get_nodes_in_group("breakable_cover"):' in player, 'world attacks are enabled')
    require('if heavy_attack:' in player, 'heavy gating present')
    require('broken_attempts >= 2' in player, 'world hit cap')
    require('obstruction.get("collider") != object' in player, 'blocked through-wall smash')
    require('if struck or struck_world:' in player, 'contact feedback includes world props')
    require('if struck and rally_pool > 0.0' in player, 'no rally gained from props')
    damage_section=player.split('func receive_damage(',1)[1].split('func _stat(',1)[0]
    require(damage_section.find('if invulnerable_time > 0.0:') < damage_section.find('bow_draw_active = false'), 'i-frames do not cancel bow draw')
    require('contact_push_left' in enemy and 'contact_push_velocity' in enemy, 'enemy physical hit response')
    require('velocity += contact_push_velocity * (contact_push_left / 0.12)' in enemy, 'enemy flinch decays')
    require('"poise"' in enemy and '"poise"' in particles, 'poise break burst wired')
    require('announce_break: bool = true' in destruct, 'legacy break announcements preserved by default')
    require('if announce_break and world' in destruct, 'early props can avoid HUD spam')
    require('func reveal_from_collapse' in floor and 'func _open' in floor, 'floor-breach hotfix included')
    scenes={}
    for scene_path in ['scenes/rooms/moonwake_crypt.tscn','scenes/rooms/garden.tscn']:
        txt=source(scene_path); scenes[scene_path]=txt
        require(txt.count('id="v150_cover"')==1, f'{scene_path} unique script resource')
        require(txt.count('id="v150_cover_circle"')==1, f'{scene_path} unique collider resource')
        require(txt.count('announce_break = false')==2, f'{scene_path} two quiet props')
        require('V150CombatBreakables' in txt, f'{scene_path} editor nodes')
        require(txt.count('shape = SubResource("v150_cover_circle")')==2, f'{scene_path} physical collider for each prop')
        ext=re.findall(r'\[ext_resource[^\n]*\bid="([^"]+)"',txt)
        sub=re.findall(r'\[sub_resource[^\n]*\bid="([^"]+)"',txt)
        require(len(ext)==len(set(ext)), f'{scene_path} external resource ids unique')
        require(len(sub)==len(set(sub)), f'{scene_path} shape resource ids unique')
        for sid in re.findall(r'(?:ExtResource|SubResource)\("([^"]+)"\)', txt):
            require(sid in (set(ext)|set(sub)), f'{scene_path} resource {sid} resolves')
        # All script external dependencies must be present after full overlay.
        for resource in re.findall(r'\[ext_resource type="Script"[^\n]*path="(res://[^"]+)"',txt):
            require((project/resource.removeprefix('res://')).is_file(),f'{scene_path} script dependency: {resource}')
        all_nodes=set(['.'])
        for node_name,parent in re.findall(r'\[node name="([^"]+)"[^\n]*parent="([^"]+)"',txt):
            require(parent in all_nodes,f'{scene_path} parent exists: {parent} for {node_name}')
            all_nodes.add((parent+'/' if parent!='.' else '')+node_name)
    for name in ['CryptTimberWest','CryptTimberSoutheast']:
        require(f'[node name="{name}"' in scenes['scenes/rooms/moonwake_crypt.tscn'],f'{name} authored')
    for name in ['GardenTimberWest','GardenTimberSouth']:
        require(f'[node name="{name}"' in scenes['scenes/rooms/garden.tscn'],f'{name} authored')
    # Static tests cannot prove that gameplay feels right, collisions behave right,
    # or that Godot compiled the scripts; that requires F5 testing.
    print(f'v1.50: {checks}/{checks} static content and script-reference checks passed')
    return checks

if __name__=='__main__':
    project=Path(sys.argv[1]) if len(sys.argv)>1 else Path(__file__).resolve().parents[1]
    validate(project)
