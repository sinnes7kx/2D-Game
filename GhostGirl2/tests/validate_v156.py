from pathlib import Path
import sys
root=Path(sys.argv[1]) if len(sys.argv)>1 else Path(__file__).resolve().parents[1]
game=(root/'scripts/game.gd').read_text()
spell=(root/'scripts/moon_spell.gd').read_text()
fx=(root/'scripts/wand_release_fx_v156.gd').read_text()
requirements=[
 ('game script preload', 'WAND_RELEASE_SCRIPT_V156: Script = preload("res://scripts/wand_release_fx_v156.gd")' in game),
 ('wand appearance gradient', 'wand.glow_gradient_colors()' in game),
 ('third gradient', 'bolt.gradient_c = wand_gradient[2]' in game),
 ('rare signature', 'bolt.rare_signature = wand.visual_signature()' in game),
 ('single release fx', game.count('release_fx.call("configure"')==1),
 ('legacy damage unchanged', 'bolt.damage = (35.0 if charged else 14.0)' in game),
 ('single collision probe', 'func _find_contact(' in spell),
 ('projectile third color', 'var gradient_c: Color' in spell),
 ('short flight trail', '_draw_projectile_cosmetics(scale_factor)' in spell),
 ('beam accents', '_draw_beam_cosmetics(line_end, fade)' in spell),
 ('lance accents', '_draw_lance_cosmetics()' in spell),
 ('release cleans up', 'age >= LIFE:' in fx and 'queue_free()' in fx),
 ('draw-only release', '_physics_process' not in fx and 'CollisionShape' not in fx),
]
for name,passed in requirements:
    assert passed, name
print(f'v1.56 static integration: {len(requirements)}/{len(requirements)} passed')
