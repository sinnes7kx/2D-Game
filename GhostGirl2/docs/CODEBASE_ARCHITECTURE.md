# Ghost Girl — codebase architecture

**Scope:** the live Godot project is `GhostGirl2/`. Read the root ROADMAP.md and AGENTS.md first. This map supplements them; it does not change product priorities or certify runtime behavior.

## System ownership

| Domain | Current entry points | Responsibility |
| --- | --- | --- |
| World | scripts/game.gd, scenes/rooms/ | Room state, progression, encounter lifecycle and transitions |
| Player | scripts/player.gd, direction_controller_v245.gd | Input, action state, movement, stamina, committed attack timing |
| Combat geometry | scripts/combat_geometry.gd | Pure direction/range tests, target eligibility, explicit collision queries |
| Weapon techniques | unique_specials_v261.gd, relic_arsenal_v277.gd, relic_mechanics_v288.gd, relic_ground_v288.gd | Base-specific skills, cooldowns and contact application |
| Animation | scripts/animation/directional_playback.gd, ghost_diagonal_art_v247.gd, ghost_animation_library.gd, gentle_weapon_motion_v191.gd | Shared clip routing and timed playback, body atlases, weighted phase, wrist anchors |
| Weapon presentation | scripts/animation/weapon_render_contract.gd, v172_weapon_pose.gd, weapon_models_v283.gd, scythe_art_v190.gd, heavy_weapon_art_v192.gd | Physical weapon geometry and attachments |
| Visual FX | weapon_prestige_fx.gd, anomalous_steel_fx_v180.gd, collector_lens_model_v179.gd | Seeded effects; reuse physical pose and shared edge renderers |
| Item identity | item_instance.gd, item_generator.gd, item data resources | Immutable birth identity, stats and reproducible cosmetic identity |
| Collection | inventory_panel.gd, collection_vault_v181.gd, sanctum_exhibition_v182.gd | Inventory, ownership transfers, inspection and display |
| Presentation | hud.gd, room_atmosphere_v278.gd, gothic_grade_v277.gd | Interface, accessibility, atmosphere; no combat authority |
| Verification | tests/, tools/run_smoke_suite.sh | Source preflight and local Godot smoke regressions |

Versioned filenames are historical identifiers, not a reason to duplicate a working module. Keep Godot paths stable during incremental extraction: scenes, preloads, UIDs and saves may depend on them.

## Shared contracts

- Separate **physical gameplay** from presentation. An attack has one authority for hit timing, damage and poise; extra particles or blade trails must never multiply damage.
- `combat_geometry.gd` holds pure checks and collision queries. It does not own stamina, enemy hit ledgers, cooldowns or effects. Keep ordinary melee's world-only mask (2) distinct from ground relic world + props mask (6); preserve caller ray heights. A successful geometry test alone is not a confirmed hit.
- Eight logical headings and 360-degree aim are separate from animation clips. Body frame selection owns wrist positions; held weapons and glow derive their geometry from that pose. Do not mark reused body atlases as bespoke painted attack art.
- Equipped and inspected models should use the same material, seed and edge helpers. Keep debug controls separate from actual rolled traits. Never invent missing seed identities or globally verified rarity.
- Preserve save schemas and resource identities unless a migration is expressly planned and tested. Keep retired spell data readable; do not re-enable the retired shortcut routes.
- Preserve the original Ghost Girl appearance and approachable regular enemy difficulty. No unnecessary cross-system changes in a refactor.

## Workflow for future developers and AI agents

1. Read the actual current mainline and open PRs; locate the owning module and tests before writing.
2. Keep behavior changes distinct from structural extractions. Add focused regression cases for boundaries and old behavior; avoid gratuitous renames and broad file moves.
3. Prefer pure helper functions for reusable calculations. Avoid cyclic preloads and hidden global state. Keep physics queries in the physics path and rendering out of damage logic.
4. Update this map only when ownership actually changes. Use `ROADMAP.md` for feature decisions and evidence.
5. Run `bash GhostGirl2/tools/run_smoke_suite.sh preflight` and relevant Godot smoke checks locally when possible; interactive F5 testing is separate. Manual Actions only, respecting the existing budget-safe workflow.
6. Report separately: source implemented, source preflight passed, headless passed, mainline integrated, F5 playtested. Never imply that a PR or a regression assertion is a runtime result.

## Incremental extraction queue

- First pass: shared combat geometry, with existing public wrappers preserved.
- Directional playback and shared straight-blade rendering extracted. Polearm heads, heavy shape/strength and wand atlas/core now shared. Next: finish baked weapon and secondary ornament parity and test real rendering.
- Later: separate player action-state transitions and world/save responsibilities once regression coverage allows it. No full rewrite or mass relocation of resources.

The existing codebase is intentionally retained; these are ownership boundaries for future maintenance, not a claim that every domain is already fully decoupled.
