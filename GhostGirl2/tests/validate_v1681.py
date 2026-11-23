"""Static checks for v1.68.1 optional bow-carry crash fix.
Run using Python 3 from any directory; needs no Godot executable.
"""
from pathlib import Path
import zipfile

root = Path(__file__).resolve().parents[1]
script = (root / "scripts/bow_palette_overlay_v139.gd").read_text(encoding="utf-8")
assert 'get_node_or_null("BowCarryV166") as AnimatedSprite2D' in script
assert 'get_node("BowCarryV166") as AnimatedSprite2D' not in script
assert 'if bow_carry_visual != null:' in script
assert '        _create_bow_carry_art()' in script
assert 'func _create_bow_carry_art() -> void:' in script
assert '    if bow_carry_visual == null:' in script
assert 'var carrying: bool = false' in script
assert 'bow_carry_visual.sprite_frames = SpriteFrames.new()' in script
assert 'bow_carry_visual.visible = false' in script
assert 'item.bow_limb_gradient_colors()' in script
assert 'item.weapon_style() != "bow"' in script
# Both source scene formats are supported: v1.65 lacks the carry node;
# v1.66 added it. Neither scene is changed by the hotfix.
source_zip = Path("/mnt/data/GhostGirl_v1.65_PROJECT_PART1_Core_Character.zip")
upgrade_zip = Path("/mnt/data/GhostGirl_v1.66_Bow_Carry_Jewel_Echoes_PATCH_for_v1.65.zip")
if source_zip.exists() and upgrade_zip.exists():
    with zipfile.ZipFile(source_zip) as z:
        scene = z.read("GhostGirl2/scenes/player.tscn").decode("utf-8")
        assert "BowCarryV166" not in scene
    with zipfile.ZipFile(upgrade_zip) as z:
        scene = z.read("scenes/player.tscn").decode("utf-8")
        assert "BowCarryV166" in scene
print("v1.68.1: 11/11 static assertions passed")
