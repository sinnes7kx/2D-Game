#!/usr/bin/env bash
# Local-first tests. No network, GitHub Actions or paid runners needed.
# From repo root: bash GhostGirl2/tools/run_smoke_suite.sh preflight|quick|full
set -euo pipefail
cd "$(dirname "$0")/../.."
mode="${1:-quick}"
if [[ "$mode" != preflight && "$mode" != quick && "$mode" != full ]]; then
  echo "Usage: $0 preflight|quick|full" >&2
  exit 2
fi
quick_tests=(
  v186_animation_smoke.gd
  v1801_twinblade_inspect_smoke.gd
  v208_vault_filters_smoke.gd
  v1921_dropdown_compat_smoke.gd
  v1922_collection_recovery_smoke.gd
  v200_collection_transfer_integrity_smoke.gd
  v210_inventory_cosmetics_visual_smoke.gd
  v211_blunt_scythe_aura_smoke.gd
  v214_scythe_effects_smoke.gd
  v203_bow_airborne_blunt_smoke.gd
  v212_dagger_stab_smoke.gd
  v213_twinblade_audio_smoke.gd
  v204_eye_palette_coverage_smoke.gd
  v215_eyes_bows_input_fx_smoke.gd
  v216_editable_fx_bow_wand_smoke.gd
  v222_fluid_animation_smoke.gd
  v223_locomotion_smoke.gd
  v224_sword_fluidity_smoke.gd
  v225_dodge_wand_motion_smoke.gd
  v226_silk_performance_smoke.gd
  v227_silk_memory_smoke.gd
  v228_motion_efficiency_smoke.gd
  v229_silk_startup_smoke.gd
)
full_tests=(
  v174_animation_smoke.gd
  v175_hookfree_mirror_smoke.gd
  v176_polearm_smoke.gd
  v177_collector_smoke.gd
  v178_modular_smoke.gd
  v179_lens_smoke.gd
  v1791_core_animation_smoke.gd
  v180_anomalous_smoke.gd
  v181_vault_smoke.gd
  v206_equipment_vault_smoke.gd
  v182_exhibition_smoke.gd
  v207_sanctum_captions_smoke.gd
  v209_collector_share_card_smoke.gd
  v183_regional_smoke.gd
  v184_ethereal_smoke.gd
  v185_inspection_smoke.gd
  v187_surface_smoke.gd
  v188_palette_smoke.gd
  v189_forging_smoke.gd
  v190_arsenal_smoke.gd
  v191_gentle_motion_smoke.gd
  v192_heavy_weapons_smoke.gd
  v1923_equipped_fx_smoke.gd
  v1924_live_preview_smoke.gd
  v193_town_smoke.gd
  v193_quality_tooltip_smoke.gd
  v1931_roll_code_smoke.gd
  v194_impact_audio_smoke.gd
  v195_steady_weapon_idle_smoke.gd
  v196_compact_tooltip_smoke.gd
  v197_dagger_reaper_dark_gradient_smoke.gd
  v198_weapon_swing_bow_pose_smoke.gd
  v199_tooltip_gold_constant_smoke.gd
  v200_weapon_attachment_smoke.gd
  v205_multislot_collector_identity_smoke.gd
  v201_moonlit_cave_exploration_smoke.gd
  v202_headgear_migration_smoke.gd
  v202_fletcher_range_smoke.gd
  v202_living_world_puzzles_smoke.gd
)
# Compare the explicit ordered test lists with every tracked smoke script.
# Fail before importing Godot if a future test is omitted or listed twice.
python3 GhostGirl2/tests/validate_smoke_registration.py
python3 GhostGirl2/tests/validate_active_source_hygiene.py --self-test
python3 GhostGirl2/tests/v216_offline_preflight.py
if [[ "$mode" == preflight ]]; then
  echo "Source preflight PASSED (no Godot runtime or F5 validation)"
  exit 0
fi
: "${GODOT:=godot}"
command -v "$GODOT" >/dev/null || { echo "Godot executable not found: $GODOT" >&2; exit 1; }
echo "Godot: $("$GODOT" --version)"
# Import once per run rather than once per test.
"$GODOT" --headless --editor --path GhostGirl2 --import
if [[ "$mode" == full ]]; then
  python3 GhostGirl2/tests/validate_v1722.py
  python3 GhostGirl2/tests/validate_v1723.py
  python3 GhostGirl2/tests/validate_v173.py
  python3 GhostGirl2/tests/validate_v174.py
  python3 GhostGirl2/tests/validate_v175.py
  for script in weapon_prestige_fx v173_dual_daggers v173_dual_dagger_blade v174_dual_swords v174_dual_sword_blade v175_hookfree_weapon_body bow_palette_overlay_v139 v172_weapon_pose; do
    "$GODOT" --headless --path GhostGirl2 --check-only --script "res://scripts/${script}.gd"
  done
  quick_tests+=("${full_tests[@]}")
fi
for test in "${quick_tests[@]}"; do
  echo "TEST: $test"
  "$GODOT" --headless --path GhostGirl2 --script "res://tests/$test"
done
"$GODOT" --headless --path GhostGirl2 --quit-after 10
echo "$mode suite PASSED"
