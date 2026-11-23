# Ghost Girl v1.47 — Act I Echo Trials & Rose Chimes

This larger, **gameplay-focused incremental patch** builds directly on v1.46.4.
It keeps the approved Ghost Girl 2D art, current sprites, existing room paintings,
inventory cosmetics/gradient swatches and all legacy save formats unchanged.

## Where the fun is

- **Moonwake Crypt — Moonwake Echoes:** optional three-round fight after the
  starter area, with easy rose wraiths building into faster blade foes. Press
  **E** at the rose-ring trial altar. A nearby **F**-hook rose bell staggers
  creatures within its radius; its 8-second cooldown rewards timing against
  the enemy's existing windups. Earn a **magic Thornwake Sabre** on first clear.
- **Waking Garden — Thorn Vigil:** another optional three-wave challenge with
  multiple foe archetypes and an elite warder and occultist at the end.
  Timing the bell against a mixed melee/ranged wave is the intended test.
  First-clear reward: **rare Vesper Rapier**. These are fixed, one-time earned
  rewards, NOT farmable enemy loot or new random rare-drop frequency.
- **Short retry loops:** the crypt and garden have new editor-owned **E**-rest
  embers near the trials. They refill health, stamina and dew using the existing
  shrine behavior, and save a defeat checkpoint. No mandatory locked exits.
- **Three Rose Chimes — Crypt Gallery:** hook the three visible chimes in order
  **1 / 2 / 3** (the dots indicate order). A wrong chime resets the sequence;
  success permanently reveals a one-time **Silver Thread Charm** cache.
  Existing Gallery passages and dress pickup remain untouched.

## Trial feel and scoring

Three separate short waves per trial. The existing enemy telegraphs, combat,
dodges, Q-hook yank, spells and equipment all still work. Each cleared wave
restores a modest amount of health and stamina, reducing downtime without
making the last wave trivial. An existing quiet HUD line displays wave/time/hits
only while the trial is active. Completing displays the result and medal:
**MOONLIT** (no health-loss event), **SILVER** (one or two), **ASHEN** (more).
Replays improve your best completion time; only the first clear grants an item.
Enemies created by the trial have **no random loot drops**.

A full backpack does NOT consume the reward: after a clear, empty a space, then
press **E** at the same altar to claim it. A trial abandoned via room transfer,
rest or defeat can be started again; it doesn't mark a victory prematurely.

## Persistence and compatibility

- Original `ghost_girl_treasures_v2.json` and `ghost_girl_world_v1.json` unchanged.
- New booleans use `Inventory.collected_pickups` for first-clears, one-time
  claimed items, and the chime relay, just like the existing puzzles.
- Numeric best results use **separate** `user://ghost_girl_echo_trial_bests_v147.json`
  because the original inventory loader converts collected values into `true`.
- The v1.46.4 crypt floor-breach and garden falling-beam cache remain present;
  no character art, weapon statistics, cosmetics, save indices, or main progression
  locks have been replaced.

## Godot F5 playtest checklist (not yet performed here)

1. From an old save, enter Moonwake Crypt. Check **E** trial altar, wave HUD,
   two foe types, timed rose bell **F**, wave breaks, one first-clear item and
   **E** replays. Verify Q-hook yank and dodge-counter still function.
2. Clear with a FULL backpack: close/restart the game, empty a slot, return,
   **E**-claim exactly once. Confirm further trial clears award no more loot.
3. Rest at the nearby ember, die/return, and re-enter after walking through a
   room portal. Verify enemies and active waves reset; the claimed item does not.
4. Run Garden Thorn Vigil through all three rounds; verify elite and ranged
   attacks are telegraphed and the bell helps without trivializing the fight.
5. In Crypt Gallery, hook chimes 2, 1, 3 (wrong order), then 1, 2, 3. Confirm
   chest appears only after success, has a one-use item, and stays revealed after
   leaving/reloading; existing dress and routes still work.
6. Retest previous v1.46.4 hook-collapse/secret floor and garden cache, existing
   item tooltips, Ctrl compare, equipment colors and seed favorites.
7. Check Godot debugger for scene import, script parse, physics and audio errors.

## Edited files

`game.gd`, `hud.gd`, four new v147 scripts, three room scenes, one validator.
No large existing textures or Godot cache are shipped. The `SpawnWaves` markers
are editor-movable; names select the foe (e.g., WraithA, BladeHunterA,
WarderElite, OccultistA) and keep encounters easy to tune.

## Test limits

The build verified patch structure, scene parent paths, references and game-system
links, one-time reward design, unchanged saves, and tested sample spawn points
against authored room collision geometry. No Godot runtime playtest or visual
balance tuning was possible in the build environment.
