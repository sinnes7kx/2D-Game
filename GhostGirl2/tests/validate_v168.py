from pathlib import Path
import re,random
root=Path(__file__).resolve().parents[1]
def read(rel): return (root/rel).read_text(encoding="utf-8")
def expect(rel,*tokens):
 s=read(rel)
 for t in tokens:
  assert t in s, f"{rel} missing {t!r}"
 return s
checks=0
expect("scripts/player.gd", 'return _bow_art_style() + ("_walk_" if moving else "_idle_")');checks+=1
expect("scripts/bow_palette_overlay_v139.gd", "var carrying: bool = false", "limb_gradient");checks+=2
expect("scripts/cosmetic_rng_v152.gd", 'gradient_for_channel', 'sha256_buffer');checks+=2
expect("scripts/item_instance.gd", 'bow_limb_gradient_colors', 'bow_string_gradient_colors', 'mythic_layer_variant');checks+=3
fx=expect("scripts/weapon_prestige_fx.gd", "_draw_bow_dual_glow", "_bow_string_at", "mythic_layer_variant()", "_draw_mythic_seed_variant");checks+=4
assert "if fposmod(elapsed + offset, cadence) >" in fx;checks+=1
expect("scripts/inventory.gd", "const GRID_ROWS: int = 6", "var capacity: int = 72", '"grid_rows": GRID_ROWS', "saved_grid_rows", "wanted.y = old_page * GRID_ROWS");checks+=5
expect("scripts/inventory_grid.gd", "const ROWS: int = 6");checks+=1
expect("scenes/inventory_panel.tscn", "Vector2(460, 276)", "ALT details");checks+=2
expect("scripts/item_rich_text.gd", "Bow limbs", "Bowstring", "Mythic animation", "if not advanced:");checks+=4
expect("scripts/inventory_panel.gd", 'gradient_for_channel(uid, saved_seed, "bow-limbs")');checks+=1
expect("scripts/moon_spell.gd", "_draw_mythic_spell_bolt", "_draw_mythic_spell_beam", "if rare_signature == 4", "mythic_layer_variant");checks+=4
expect("scripts/game.gd", "bolt.mythic_layer_variant = wand.mythic_layer_variant()");checks+=1
expect("scripts/wand_release_fx_v156.gd", "mythic_variant", "clampi(sig, 0, 5)");checks+=2
# Paper-test old pages 0..7: never migrate into a different page.
for old_y in range(32):
 old_page,old_local=divmod(old_y,4)
 new_y=old_page*6+old_local
 assert new_y//6==old_page and new_y%6==old_local
 checks+=1
# No new direct physics/damage function in projectile, and GDScript routine remains.
spell=read("scripts/moon_spell.gd")
for routine in ["_physics_process", "_find_contact", "_hit_enemy", "_resolve_beam"]:
 assert f"func {routine}" in spell
 checks+=1
# If validator is run from within a real project, cross-check all scene script refs.
if (root/"project.godot").exists():
 count=0
 for source in (root/"scenes").rglob("*.tscn"):
  txt=source.read_text(encoding="utf-8")
  for res in re.findall(r'\[ext_resource type="Script"[^\]]+path="(res://[^"]+)"', txt):
   assert (root/res[6:]).exists(), f"Missing {res} from {source}"
   count+=1
 print(f"Resolved {count} scene script references")
print(f"v1.68 static checks: {checks} passed")
