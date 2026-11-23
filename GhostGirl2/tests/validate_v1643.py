from pathlib import Path
root = Path('/mnt/data/v1643_pkg/scripts')
checks = {
    'player.gd': ['return "walk_" if moving else "idle_"', 'Bow attack / draw / release animations remain unchanged'],
    'bow_palette_overlay_v139.gd': ['_resolved_animation_name', '_should_flip_for_animation', 'flip_h = _should_flip_for_animation(source_animation)'],
    'weapon_prestige_fx.gd': ['_resolved_bow_animation_name', 'no detached mythic ring', 'luminous string, limb rails, a nock flare'],
}
for fn, reqs in checks.items():
    txt = (root/fn).read_text(encoding='utf-8')
    missing = [r for r in reqs if r not in txt]
    if missing:
        raise SystemExit(f'{fn} missing {missing}')
print('v1.64.3 validation passed')
