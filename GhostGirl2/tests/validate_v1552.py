#!/usr/bin/env python3
"""Ghost Girl v1.55.2 targeted source checks. Does not replace Godot runtime testing."""
from pathlib import Path
import sys, re
root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[1]
fx = (root / 'scripts/weapon_prestige_fx.gd').read_text(encoding='utf-8')
item = (root / 'scripts/item_instance.gd').read_text(encoding='utf-8')
n = 0

def check(test, what):
    global n
    n += 1
    if not test:
        raise AssertionError('v1.55.2 check %d failed: %s' % (n, what))

check('var old_gradient: Array[Color] = []' in item, 'empty color array explicitly typed')
check('old_gradient = glow_gradient_colors()' in item, 'gradient conditional assignment')
check('var old_gradient: Array[Color] = glow_gradient_colors() if' not in item, 'bad typed/untyped ternary removed')
check('func reroll_cosmetic_seed() -> int:' in item, 'reroll entry point retained')
check('if get_slot() in ["sword", "wand"]:' in item, 'weapon-only gradient comparisons remain guarded')
check('elif new_color != old_color:' in item, 'dress palette rerolls exit after changed palette')
check('COSMETIC_RNG.fresh_uid()' in item, 'cryptographic cosmetics still rolled')
check('apply_cosmetic_uid(uid)' in item, 'appearance UID assigned')
check('definit' in item and 'item_seed' in item, 'item mechanics source retained')
check('var visible_glow_strength: float = 1.78' in fx, 'soft-glow strength increased')
check('for i in range(15):' in fx and 'float(i) / 14.0' in fx, 'denser smooth glow samples')
check('0.012 * intensity * opaque_factor' in fx, 'wide halo increased')
check('0.022 * intensity * opaque_factor' in fx, 'middle halo increased')
check('0.047 * intensity * opaque_factor' in fx, 'inner halo increased')
check('0.142 * intensity * opaque_factor' in fx, 'luminous core increased')
check('0.35 * minf(intensity, 1.65)' in fx, 'bright thin core filament')
check('_draw_wand_hold_cosmetics(' in fx, 'v1.55 wand cosmetics preserved')
check('_draw_signature(' in fx, 'rare signatures preserved')
check('_blade_span(' in fx, 'directional blade guides preserved')
check('BLEND_MODE_ADD' in fx, 'additive rendering preserved')
check('draw_polyline' not in fx, 'no angular fan restored')
check('effect_intensity * visible_glow_strength' in fx, 'editor adjustable intensity maintained')
print('v1.55.2:', n, '/', n, 'targeted static checks passed')
