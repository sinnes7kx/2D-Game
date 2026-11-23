from pathlib import Path
root = Path("/mnt/data/v158_package/scripts")
checks = {
    "item_instance.gd": ["_has_mythic_visual", "return 4", "rare_visual_mod = 4"],
    "weapon_prestige_fx.gd": ["Mythic Radiance", "sig == 4"],
    "equipment_visuals.gd": ["dress_aura_enabled", "visual_signature() == 4"],
    "inventory_panel.gd": ["_appearance_preview", "_mirrored_icon", "rare_visual_mod"],
}
for fn, reqs in checks.items():
    txt = (root/fn).read_text(encoding="utf-8")
    missing = [r for r in reqs if r not in txt]
    if missing:
        raise SystemExit(f"{fn} missing: {missing}")
print("v1.58 validation passed")
