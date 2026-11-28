# AGENTS.md — Instructions for every coding agent in this repository

> **Mandatory first step:** Read the root [ROADMAP.md](ROADMAP.md) **in full before planning, editing, generating, reviewing, or shipping any Ghost Girl code or asset**. This file is an execution guide; the roadmap is the canonical product brief. If these docs conflict, stop and reconcile the conflict explicitly rather than silently choosing an older interpretation.

## 1. Core mission (do not invert priorities)

**Ghost Girl is primarily about collecting, owning, displaying, and eventually securely trading extremely rare seeded items.** Keep the spirit of *Diablo II*: memorable loot hunting, collecting, and social prestige with **light, approachable day-to-day PvE**. Preserve *Bloodborne*-inspired deliberate combat for an **optional high-skill competitive track with top lists**. Do **not** make difficult combat, ranked placement, or boss execution mandatory for the ordinary item-collecting and showcasing experience.

This ordering is not optional:
1. Protect existing items and saves.
2. Make seeded rarity and item identity distinctive, honest, and reproducible.
3. Improve inventory, collection vault, inspection, exhibition, showcase, and eventual safe trading.
4. Keep routine loot hunting enjoyable and accessible.
5. Develop optional advanced combat and verified rankings.
6. Expand worlds and content in ways that strengthen those loops.
7. A huge part of the game is the dopamine from finding really cool / rare seeded items.
8. Some rare seeded items can improve combat slightly, this needs to be balanced. For example some bow seeds can shoot 3 arrows but each arrow deals 50% less damage.

A task's explicit user request controls scope, but never silently undo these product goals. Flag any apparent contradiction.

## 2. Read and inspect before writing

Use [the live codebase architecture map](GhostGirl2/docs/CODEBASE_ARCHITECTURE.md) to identify ownership and shared contracts before refactoring. Extend existing modules instead of adding version-suffixed duplicates; keep resource paths and save compatibility stable.

1. Read `ROADMAP.md` completely; locate the current milestone, acceptance gates, item invariants, and open decisions.
2. Inspect the **actual current source** under `GhostGirl2/`: relevant `scripts/`, `scenes/`, `items/`, `tests/`, `docs/`, `project.godot`, and GitHub Actions workflow.
3. Identify what is **already implemented**, what is only **source-implemented but not playtested**, and what is genuinely **planned**. Do not duplicate existing item generation, cosmetic seed saving, collection vault, Sanctum displays, or inventory compatibility logic.
4. Confirm the live target branch/file and project version. Historical `README.md`, `project.godot` display labels, old release ZIPs, and `scripts - Copy/` are **not authoritative** over current active scripts.
5. Make a small implementation plan, name affected files, preserve save compatibility, and choose targeted tests before changing behavior.
6. After changes, revisit `ROADMAP.md` and update only status that is **actually evidenced**; document any newly found blocker, decision, or design deviation.

## 3. Critical item safeguards

- Preserve item seeds, cosmetic UID, intrinsic rare traits, stats, affixes, sockets, item quality, favorites/locks, saved looks, vault, and exhibition placement unless the explicit feature legitimately transforms them.
- `item_seed` (stats/loot), `cosmetic_seed` and `cosmetic_uid` (appearance), and a **future authoritative owned-instance ID** are separate concepts. A reproducible seed is **not** globally verified uniqueness.
- Debug forced rarity/appearance is for local testing only. It must never become an authentic minted drop, tradeable rarity, or verified leaderboard result.
- Do not call offline items globally unique or verified. A future shared trading economy needs server-issued ownership, auditability, atomic transactions, replay/dupe protections, and explicit rules for local legacy saves.
- Keep tradeable collector items accessible through ordinary play; keep skill-ranking rewards mostly cosmetic, account-bound, or presentational unless the user approves another balance policy.
- Make destructive item operations safe: protection locks, confirmations, migration/backups, and recoverable failure states.

## 4. Current high-priority build issues

- Fix and verify the old inventory `TestMythic` `Button`/typed `OptionButton` crash. The active `GhostGirl2/scripts/inventory_panel.gd` uses `_ensure_effect_dropdown()`; do not restore the fragile typed `@onready` path.
- Use `GhostGirl2/tests/v1921_dropdown_compat_smoke.gd` to cover current, legacy Button, and missing dropdown paths; verify the actual inventory with F5.
- `GhostGirl2/scripts - Copy/inventory_panel.gd` contains Git conflict markers and old code. Treat it as an unsafe duplicate; clean/remove only with proper review and do not overwrite the active script.
- Treat saved-item lifecycle, old save migration, and real visual/engine testing as release blockers, not optional cleanup.

## 5. Aesthetic and combat boundaries

- Preserve the approved Ghost Girl facial features, proportions, animation identity, silhouette, and painterly gothic atmosphere.
- Make **new original room artwork** for new rooms; do not masquerade as new content by flipping/recoloring existing backgrounds.
- Prefer complete, correctly aligned Godot directional weapon animations and deterministic layered visuals; preserve existing atlas/animation compatibility.
- Favor rare, refined FX over constant particle clutter. Sword glows should follow blades, and decorative extra projectiles must not multiply damage.
- Everyday mobs and farming should be approachable. Maintain deliberate precise combat, dodge counters, hitstop, and high-skill bosses for separate optional challenges. Counter effects play only on confirmed hits.
- Public competitive results must be fairly categorized (normalized vs open builds), ruleset-versioned, and verified; do not treat local high scores as authenticated top lists.

## 6. Development workflow and delivery

1. **Before work:** read `ROADMAP.md` and relevant code/tests; verify requirements and save compatibility.
2. **Implement:** prefer minimal focused changes and incremental patches over refactoring unrelated systems. Never blindly copy files from older ZIPs or conflict-marked duplicate folders.
3. **Test:** add a regression for each bug or item invariant. Run relevant Python/static validations and Godot headless checks if the engine is present.
4. **Playtest:** if possible, run real Godot F5 and exercise inventory, scene transitions, loot, combat, vault, display, and old saves. If unavailable, explicitly say it was not performed.
5. **Document:** report changed files, exact validation performed/results, untested areas, migrations, backup/downgrade instructions, and any open risks.
6. **Update roadmap:** mark work completed only when verified; otherwise record it as source-present / pending real playtest.

### Architecture maintenance

Read `GhostGirl2/docs/ARCHITECTURE.md` before implementing cross-system features. Prefer named domain modules for new pure rules; do not duplicate established systems or move scene-bound scripts without verified reference migration. Gameplay and preview must share physical weapon geometry where possible. Keep cosmetic effects independent of combat and persistence. Register smoke scripts exactly once and keep the manual CI budget policy.

Helpful existing resources:
- Main Godot project: `GhostGirl2/project.godot`
- Live inventory: `GhostGirl2/scripts/inventory_panel.gd`
- Item identity: `GhostGirl2/scripts/item_instance.gd`, `item_generator.gd`
- Vault/display: `GhostGirl2/scripts/collection_vault_v181.gd`, `sanctum_exhibition_v182.gd`
- Compatibility regression: `GhostGirl2/tests/v1921_dropdown_compat_smoke.gd`
- CI: `.github/workflows/ghostgirl-godot-smoke.yml`

### Mainline integration gate (mandatory)

- **Use `main` as the normal pull-request base.** If a change explicitly depends on an unmerged feature PR, mark it **stacked**, document the dependency and planned merge order, and create a separate, verified integration PR targeting `main` before calling it delivered.
- A GitHub PR with `merged=true` is **not proof that its contents reached `main`**. Read the PR's actual base branch; check the changed file or commit from `main`, and require mainline CI after the integration merge.
- Never report a feature as released/available from `main` solely because its nested PR was merged or its feature-branch CI passed. Distinguish **branch implemented**, **headless tested**, **merged into main**, and **F5 playtested**.
- Before starting a next feature on a stacked series, check whether the whole stack is on `main`. Consolidate first if not. Do not silently implement against an older mainline or regress newer feature changes.

## 7. What not to claim

Never claim live trading, account ownership, globally verified scarcity, online showrooms, public verified leaderboards, or completed real-world Godot playtests without actual corresponding code and evidence. Distinguish **idea**, **source implementation**, **headless validation**, **interactive engine testing**, and **released feature**.

**Definition of done:** The change advances the product north star, preserves existing item and save identity, has appropriate regression checks, and is documented truthfully. Re-read the roadmap before declaring completion.
