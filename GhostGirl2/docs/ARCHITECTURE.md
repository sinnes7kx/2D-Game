# Ghost Girl — Codebase architecture

This is the engineering map of the active Godot project. Product priorities and acceptance gates remain in the root ROADMAP.md; coding agents must also follow AGENTS.md. Historical version suffixes identify compatibility boundaries, not instructions to create another duplicate of a working system.

## Current ownership and direction of dependencies

| Domain | Active entry points | Responsibility |
| --- | --- | --- |
| Combat orchestration | scripts/player.gd | Input, action state, stamina, movement, committed animation, hit application |
| Combat rules | scripts/combat/melee_rules.gd | Pure base melee balance and normalized frontal geometry; no nodes, saves, rendering or input |
| Input and facing | scripts/direction_controller_v245.gd | Normalized movement, octants, cursor dead zone and input registration |
| Weapon techniques | scripts/unique_specials_v261.gd, relic_arsenal_v277.gd, relic_mechanics_v288.gd | Item-base ability routing, skill profiles and cooldowns |
| Animation | scripts/ghost_animation_library.gd, ghost_diagonal_art_v247.gd, v172_weapon_pose.gd | Clip names, body atlases, cardinal fallback, wrist-based held art |
| Item identity | scripts/item_instance.gd, item_generator.gd | Stable IDs, original rolls, derived stats and cosmetic choices |
| Item presentation | scripts/modular_weapon_art_v178.gd, weapon_models_v283.gd, weapon_prestige_fx.gd, collector_lens_model_v179.gd | Physical geometry and seeded visuals; preview must share live geometry, never change gameplay |
| Inventory/collection | scripts/inventory.gd, collection_vault_v181.gd, sanctum_exhibition_v182.gd | Save ownership, transfers, equipped state, display; UI calls these rather than mutating persistence directly |
| World | scripts/game.gd, scenes/rooms/ | Room loading, rewards, exploration, environment interactions |
| Interface | scripts/hud.gd, inventory_panel.gd, codex_panel.gd | Present state, collect intent, display controls and item details |
| Rendering | scripts/room_atmosphere_v278.gd, gothic_grade_v277.gd, performance_profiles_v230.gd | Scene atmosphere, quality settings and visual-only presentation |
| Validation | tools/run_smoke_suite.sh, tests/ | Local preflight and Godot regression suites |

New pure helpers belong in a descriptive domain directory (start with scripts/combat/); existing scene-bound scripts stay at their current paths until a separately verified migration. Don't create competing implementations named after the next patch version. Do not copy the historical scripts - Copy directory into active code.

## Combat change contract

- Base profiles contain reach, pre-item power, minimum forward dot and poise. Current modifiers, cooldowns, action timing, ray masks, enemy contact and confirmed-hit feedback remain with their current owners. Do not conflate visual blade length with actual reach.
- The player, ordinary parry and unique weapon techniques can reuse shared geometry while retaining distinct timing, range and dot thresholds. A geometry match alone is not a confirmed hit; world obstruction and target validation are still required.
- Art/FX and loot stats are independent. Changing a sprite, edge glow, shader or cosmetic seed must not modify damage, actual hits or saved item identity.
- Keep ordinary farming accessible and optional mastery deep. New mechanics need explicit behavior changes and tests, not silent tuning during refactoring.

## Migration order (incremental, not a rewrite)

1. Base combat rules and regression registration (first step in this PR).
2. Extract action-state/timing and grounded locomotion from player.gd, leaving scene-compatible forwarding methods until tested.
3. Establish shared per-family geometry and FX contracts for gameplay and Lens. Align each of the eight directions and preserve occlusion; audit authored versus reused frames.
4. Isolate inventory presentation from ownership mutation; preserve existing save schema and seed provenance.
5. Extract room routing and visual presentation policies from game.gd; retire obsolete rooms only with explicit progression/save handling.

## Developer checklist

Read ROADMAP.md and inspect the actual main branch and relevant open PRs. Verify the owning function before adding code. Keep one main-targeted PR per cohesive bundle; don't silently stack changes on an unmerged feature. Preserve paths, save fields, item seeds and previous API names unless migration is requested and tested. Add a smoke test for new behavior or retained invariants. Register each smoke script exactly once; run `bash GhostGirl2/tools/run_smoke_suite.sh preflight` from the repository root, and `quick`/ `full` with the supported Godot engine. CI is manually triggered to avoid paid runner use. Report source, preflight, headless, F5 and main integration separately. Never claim a test passed because an assertion was written.

## Visual roadmap guardrails

Use original painterly art and the approved character appearance. The v249 diagonal atlases are now tracked, but an installed alias is not a new authored attack. Prioritize visible, properly anchored weapon motion, realistic hit feedback and scenery readability; preserve performance presets and save data. No new sprites or environments are created by this architecture-only refactor.
