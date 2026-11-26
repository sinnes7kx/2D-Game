# Ghost Girl — Master Development Roadmap

> **Product north star:** Ghost Girl is **first and foremost a rare seeded-item collecting, trading, and showcasing game**. Players should dream about finding an extraordinarily rare, visually recognizable item; enjoy owning it; proudly display it; and eventually trade with other players. Think of the enduring item hunt and social prestige of *Diablo II*, with **light, accessible everyday combat**. The deliberate, high-skill feel of *Bloodborne* is important **for an optional competitive challenge and leaderboard track**, not a difficulty barrier between casual collectors and their loot.
>
> **This is the canonical product-priority document for the repository.** See [AGENTS.md](AGENTS.md) for instructions to coding agents.

_Last updated: 2026-11-26 · Godot 4 · living design and delivery plan, not a claim of completion or a release-date promise._

## Read this first: the game we are building

### Product promise

**Find it. Love its seed. Keep it safe. Show it off. Trade it, if you choose.**

Ghost Girl should make a collector feel that a one-of-a-kind item has an identity, not just a higher damage number. Every exciting find should offer at least one story: an unusual silhouette, a rare material, an improbable combination of visual traits, an exceptionally good stat roll, a remembered drop location, or the moment the item was traded into the collection. Other players must be able to recognize and inspect that story.

The item game is the long-term retention engine. Combat, quests, locations, bosses, and rose-hook puzzles are **ways to discover and earn treasures**, not barriers to enjoying the core collecting experience.

### Priorities in conflict

Use the following ranking whenever features compete for scope, implementation time, screen space, or performance:

1. **Existing players' collections and save integrity.** Never casually risk a cherished item or alter its original roll.
2. **Rarity, distinctiveness, and emotional item ownership.** The core collector fantasy.
3. **Showcasing, inspection, social recognition, and a trustworthy future trading economy.**
4. **Pleasant, repeatable, low-friction everyday loot hunting**, accessible to players who are not action-game experts.
5. **Optional deep combat mastery, competitive challenges, and leaderboards** for players who enjoy precision and risk.
6. Exploration, puzzles, story, and presentation that make the world memorable and support the item hunt.

This is an order of **product goals**, not permission to ship crashes or cut basic combat functionality. Technical stability remains a non-negotiable release gate.

### The two supported player fantasies

| Collector / social player (primary) | Competitive hunter (optional) |
| --- | --- |
| Searches for rare seeds, materials, shapes, effects, and rolls | Masters dodges, spacing, counters, boss tells, and movement |
| Runs approachable farming routes and explores for treasures | Repeats timed arenas, difficult encounters, and challenge routes |
| Stores, favorites, curates, compares, and proudly displays finds | Studies personal bests, rankings, skill statistics, and replays |
| Trades and follows item provenance when genuine online trading exists | Competes on fair, verified leaderboards |
| Can access the core item hunt without exceptional reflexes | Can opt into harder content with additional recognition |

**Do not make top-tier collector participation, trading, ordinary equipment progression, or cosmetic discovery contingent on competitive ranks.** Competitive-only rewards should favor titles, badges, frames, trophies, and recognizable prestige presentation rather than monopolizing desirable tradeable items.

### Guiding principles

- **Item-first, not power-creep-first:** more individuality and stories, less endless inflation of item stats.
- **Very rare must truly mean very rare:** communicate scarcity honestly; do not invent population counts, odds, or impossible “1 of 1” claims.
- **Seed identity survives:** rendering, serialization, inspection, storage, exchange, and migration must reconstruct the same item.
- **Appearance and combat power are separate:** a cosmetic reroll does not change affixes, sockets, durability, damage, or identity.
- **Choice over obligation:** players can keep finds privately, display them, or eventually trade them.
- **No prestige by debug controls:** testing overrides and admin tools never mint genuine rare tradeable items or count toward rankings.
- **Keep it gothic:** dark, painterly, quiet, atmospheric, and true to the approved Ghost Girl appearance.
- **Build vertically, verify, then broaden:** small compatibility-preserving increments beat enormous untested rewrites.

---

## 1. Current project baseline — verify before planning implementation

The active Godot project is **`GhostGirl2/`**, not the repository root. File names, test names, and source features below were observed in the repository on 2026-11-24, but they are **not a claim that live gameplay is fully tested**. Some metadata and historical README text remain from older releases; look at current scripts, scenes, and tests rather than assuming a version string proves completeness.

### Existing foundations in source

- `scripts/item_generator.gd` generates deterministic item qualities and affixes from a drop seed; current qualities include normal, magic, rare, set, and unique.
- `scripts/item_instance.gd` stores independent `item_seed`, `cosmetic_seed`, and `cosmetic_uid` fields, visual rolls, a limited set of saved cosmetic looks, item metadata, collector favorite/protection flags, and exhibition assignment.
- Source includes visual/forging variation, collector inspection, material/surface effects, regional identity, and appearance-related smoke tests. Verify each feature against its actual script before changing it.
- `scripts/collection_vault_v181.gd` implements an in-game vault interface with search, favorites, protection, inspection, and Sanctum display assignment.
- `scripts/sanctum_exhibition_v182.gd` renders display-only snapshots from the vault, preserving the underlying stored item.
- The current inventory code includes a compatibility repair path for legacy `TestMythic` controls; `tests/v1921_dropdown_compat_smoke.gd` tests current, legacy, and missing-node scenarios.
- `.github/workflows/ghostgirl-godot-smoke.yml` contains Godot headless/import and versioned smoke checks. CI success and real F5 gameplay are distinct validation claims.

### Important limitations / unknowns

- **Online player accounts, genuine player-to-player trading, publicly accessible showrooms, and verified leaderboards are roadmap goals, not assumed existing systems.**
- A local save can be edited; **local-only item fields do not prove unique ownership or authentic rarity** in a future shared economy.
- Cosmetic favorites / seed rerolls already have partial or substantial source support. Assess the *actual UX and preservation behavior* before rebuilding them.
- The historical duplicate `GhostGirl2/scripts - Copy/inventory_panel.gd` is **not tracked on `main` as inspected 2026-11-25**. Keep the active `scripts/inventory_panel.gd` authoritative; an M0 source-hygiene guard is proposed to prevent duplicate scripts or unresolved merge markers returning.
- The project name/version in `project.godot` and the historical `GhostGirl2/README.md` may lag behind newly added code. Keep actual release state separate from marketing labels.

### Status vocabulary

- **Existing source** = code or tests observed, still subject to engine testing.
- **P0 / Next** = release blocker and first milestone.
- **P1** = core collector loop and first showcase milestones.
- **P2** = deeper social and economy foundations; a verified service is a prerequisite for real exchange.
- **P3** = optional competitive systems, world expansion, and long-run polish.
- **Research/decision** = unresolved design questions, not commitments.
- An unchecked box means work or verification remains; it does not imply everything underneath is absent from source.

---

## 2. Roadmap at a glance

| Stage | Main outcome | Why it matters | Release gate |
| --- | --- | --- | --- |
| **M0 · Reliable foundation (P0)** | Crash-free boot, inventory, item storage, and save/load | A collector must never fear losing a treasured find | Real Godot playtest + tests + migration |
| **M1 · The unforgettable drop (P1)** | Distinct, reproducible, honestly rare seeded treasures | The main emotional hook | Deterministic seeds, inspectable identity, audited odds |
| **M2 · The personal museum (P1)** | Strong inventory, vault, display, galleries, and item sharing | Showing off is half the game | Every item displays faithfully without mutating it |
| **M3 · The satisfying hunt (P1–P2)** | Accessible replayable routes, varied loot sources, secrets | Gives collectors enjoyable ways to find items | Reward loop feels good without ranked-level skill |
| **M4 · Community and safe trading (P2)** | Player identity, profiles, secure authoritative ownership transfers | Real collection culture | No duplication, loss, or spoofed trades |
| **M5 · Competitive mastery (P2–P3)** | Optional Bloodborne-style challenges and verified top lists | Deep endgame for skilled players | Fair rules, legitimate runs, separate ranking categories |
| **M6 · Living world (P3)** | More original areas, unique sources, encounters, long-term seasons | Expands item stories sustainably | No economy breakage or save regressions |

Order is directional. A small polished slice may combine adjacent stages. **Do not skip M0**, and do not announce tradeable online scarcity until M4's authentication and ownership rules exist.

---

## 3. M0 — Stabilize a collection-safe playable build (P0)

### Goal

A newly installed project imports, launches, accepts inputs, opens the inventory, previews items, saves, reloads, and closes cleanly. No item may be silently duplicated, lost, transformed, or corrupted.

### Engineering checklist

- [ ] Reproduce and verify the `TestMythic` crash case: an older `Button` was assigned to an `OptionButton`. Confirm the active `_ensure_effect_dropdown()` implementation fixes it in engine.
- [ ] Run `tests/v1921_dropdown_compat_smoke.gd` against current, legacy-Button, and missing dropdown scenes. Confirm debug effects and reset signals; ensure tester is hidden in exported releases.
- [x] Confirm the conflict-marked duplicate `scripts - Copy/inventory_panel.gd` is absent from the tracked `main` tree (2026-11-25 inspection); do not substitute historical copies for the live `scripts/inventory_panel.gd`.
- [ ] Enforce the proposed active source-hygiene CI guard against unresolved merge markers and reintroduced `scripts - Copy/`; verify CI on the integration PR.
- [ ] Scan tracked GDScript and scenes for unresolved merge markers, missing resources, bad node paths, stale `@onready` assignments, and startup failures.
- [ ] Validate fresh-checkout Godot import, script parsing, scene loading, and the CI smoke workflow.
- [ ] Manually F5-test: new game, old save, inventory, inspect, tooltip, sort, drag-and-drop, socket, equip/unequip, destroy confirmation, vault store/withdraw, favorite/protect, exhibition, save/reload, and exit.
- [ ] Explicitly test backpack grid migration, page count, capacity, full storage, locked items, and failure recovery without item loss.
- [ ] Test appearance reproducibility across save/reload and across different graphics settings.
- [ ] Establish a versioned backup and migration test corpus for older `user://` saves; do not publish or overwrite private player saves.
- [ ] Check item invariants on every transfer between backpack, equipment, vault, display, and future trade staging.
- [ ] Maintain a simple defect table: repro steps, affected scene/script, Godot build, severity, validation result, and patch version.
- [ ] Keep performance and memory affordable on older GPUs; validate the 2D project on lower-spec hardware if accessible.

### v2.06 — full equipment collection vault (source implementation; CI and F5 pending)

- [ ] Expand the existing collection vault from sword/wand-only filtering to all **recognized equipment slots** (dress, head accessory, helm, trinket, charm, sword, wand). Non-equipment/unknown slots remain excluded; equipped items still must be unequipped before depositing.
- [ ] Existing capacity, unresolved-record reservations, rollback on failed save, favorite/lock protection, and Sanctum exhibition references remain unchanged. Display uses the existing non-weapon icon fallback, not fake weapon geometry.
- [ ] A new `tests/v206_equipment_vault_smoke.gd` checks luminous eye/tiara storage, equipped-item rejection, blocked-save rollback on both directions, protected collector flags, palette/seed/stat fidelity, JSON reload and vault UI visibility. This test uses synthetic in-memory inventory only.
- [ ] Verify CI and F5 user experience for both storage modes, full inventory, old saves, and persistent display. No save schema, drop rates, cosmetic rolls or trading claims changed.
### v2.05 — multi-slot collector identity regression (PR source; CI/F5 pending)

- [ ] New `tests/v205_multislot_collector_identity_smoke.gd` checks four real item definitions (dual swords, bow, glowing eyes and tiara) with synthetic collectible seeds. It tests saved-look restoration, appearance-only UID changes, birth/current roll-code separation, equipped-slot mapping, collected flags and whole-inventory JSON encode/decode without accessing `user://`.
- [ ] Check GitHub Actions headless result before calling the suite validated. This test supplements v1.93.1 and v2.00; it does **not** replace private legacy-save F5 tests, vault failure recovery, inventory interactions or visual alignment verification.
- [ ] No save schema, balancing, drop chances or equipment behavior changes. Existing collector IDs, stats and palettes remain untouched.
### v2.04 — seeded eye silhouettes and eye coverage (feature branch; Godot CI / F5 pending)

- [ ] The existing `v202_luminous_eyes` accessory now draws opaque eye-shaped backing across the original black pupils, with four eye variants (Moonveil, Cathedral slit, Starborn, Hollow ring) selected deterministically from the saved cosmetic seed. A separate versioned continuous color gradient follows the cosmetic UID; cosmetic rerolls can yield new variants and shades without touching stats, item identity or the saved `wings` slot.
- [ ] Verify real eye location and coverage in all four facings, in equipment preview and in world animations (idle, walk, dodge, attack, jump); compare against the user's screenshot, including the very small-scale UI preview. Head cosmetics and original body atlases are not otherwise changed.
- [ ] Run the new `tests/v204_eye_palette_coverage_smoke.gd` through Godot CI and perform F5 visual testing. This static anchor test cannot prove that the opaque eye backing perfectly masks all original pupil pixels in every authored animation frame.

### v2.26 — silk motion and rendering efficiency (source implementation; engine review pending)

- Optional subtle continuous secondary motion in geometric outer-hair and lower-hem zones of supported neutral/ordinary walk poses and selected separate-weapon idles. Velocity-driven lag, quiet idle sway and hitstop freeze. Original source artwork stays intact; this is an approximate shader prototype, not authored per-frame hair/fabric masks. Unsupported baked weapon clips remain unchanged. Shift+F4 toggles the motion off/on for the session.
- Avoid empty player indicator canvas redraws and repeated head accessory redraws within the same 18 Hz effect bucket; still redraw on pose or equip transitions. Restrict procedural frame blending to the intersection of both source images' nontransparent bounds; identical alpha and blend output, fewer CPU pixel iterations during startup. No extra animation textures, no renderer switch, no physics or enemy AI changes.
- Add synthetic smoke for byte-exact bounded blending, motion scope/decay and shader wiring. Godot parser/render, visual zone calibration and FPS/startup measurements remain pending; source PNG pixels could not be inspected through GitHub. Keep enemy animation work deferred. No Actions dispatch.

### v2.25 — fluid dodging, wand casting and landing (source implementation; engine review pending)

- Expand 16-frame directional dodges to 24 samples and eight-frame directional wand casts to 22 samples. Preserve each original texture and weighted clip duration, including the final pose hold. These are procedural opaque-interior transitions, not newly painted limb poses.
- Explicit nearest-source maps drive wand atlas region, wrist alignment, prestige/glimmer and spell origin together. Dodge eye guides map all 16 authored poses to eight beats. Nonexpanded clips, original source art, seed identities and saves remain unchanged.
- Ease render-only dodge displacement and roll to/from neutral, smooth landing recovery, reset cast scale and restart repeated casts/dodges. Physical dodge speed, 0.24-second invulnerability, stamina and spell release/cooldown timings remain unchanged.
- Add synthetic quick smoke for sample counts, preserved keys, alpha, duration, shared wand indexing and bounded motion. No Godot engine or GPU profiling in this source-only change. Worst-case extra RGBA texture data is roughly 19 MiB (88 generated 256×220 textures); preview skips generation. No automatic Actions dispatch.

### v2.24 — ground sword attack sampling and follow-through (source implementation; engine review pending)

- Expand ordinary four-direction light/heavy sword ground clips from eight to 22 samples (eight exact approved keyframes plus 14 procedural opaque-interior paint transitions). Preserve total weighted duration and final hold; no loop seam, no generated double silhouette. Heavy/light share cached samples when source sequences match. Preview, airborne, bows, wands, counters, dagger-charge indexes and other families keep their previous frame counts. This is not 14 newly painted limb poses.
- Shared nearest-source silhouette indexing for baked blade glow and eye accessory anchors; body and child FX receive small render-time anticipation/swing/recovery transforms. Actual art alignment needs F5 inspection, since binary PNGs could not be reviewed through the repository connector.
- Fix timed action playback inheriting sprint/idle speed_scale, preserve custom rate and frame progress on confirmed-hitstop and dagger-charge resumes, and explicitly restart repeat ground combo clips. Combat timers, costs, hitboxes, damage, save schema and original artwork remain unchanged.
- Synthetic local quick smoke checks timing, sample index and alpha preservation, original texture identity, final hold and bounded follow-through. Source-only checks; Godot/parser/F5 and measured performance pending. Extra generated data is approximately 12 MiB when all four heavy/light texture sequences match, up to 24 MiB if all eight differ. No Actions dispatch.

### v2.23 — directional stride continuity and locomotion sampling (source implementation; engine review pending)

- Expand each ordinary eight-frame walk cycle to 24 procedural samples at unchanged weighted cycle duration, preserving every original texture at every third frame. Intermediate paint borrows only overlapping opaque interior colors and retains one approved silhouette; these are not newly hand-drawn limb poses. Cache four cycles; equipment preview skips generation.
- Preserve weighted stride phase when turning within any walk family, and add very small continuous render-time body bob/roll. Sprint animation follows velocity more closely (visual speed clamp 1.55); movement, stamina, collisions, attack timing and saves unchanged.
- Map expanded ordinary-walk eye guides to the nearest original silhouette. Leave all weapon-specific locomotion, baked combat frame counts and hit indexes untouched pending new approved art.
- Add opt-in Shift+F2 measured FPS readout (hidden by default) and synthetic quick smoke checks for timing, keyframe preservation, source pose mapping and phase transfer. No FPS gain claimed; source-only verification, Godot/F5 still pending. Runtime generation can add startup cost and about 14 MiB of RGBA texture data if the four clips use 256×220 frames.

### v2.22 — fluid motion foundation (source implementation; engine review pending)

- Enable Godot 2D physics interpolation for the player root only, retain 60 physics ticks/s, and leave existing process-driven room and equipment-local transforms uninterpolated. Reset player interpolation and camera smoothing after room/shrine/hook teleports. VSync remains unchanged; rendering FPS still depends on hardware and monitor.
- Increase the existing procedural sword/dagger idle paint in-betweens from 16 to 24 at the same 3.45s cycle. This is not newly hand-painted attack or walking artwork; no approved source PNG or baked attack frame index changed.
- Interpolate independently drawn sword/dagger/twinblade/spear attack angles between authored poses at render time, preserving current-frame wrist anchors and shared physical/FX span lookup. Keep baked weapon art and its frame-indexed guides unchanged. Synchronize unequal-weight action clips and wand casting to existing combat timers.
- Add synthetic fluidity smoke to the quick suite. Source inspection only; no measured FPS gain, renderer, F5, parser, or GPU profiling claimed. Extra idle textures may modestly increase startup time and memory. Verify hook pulls, room transitions, combat hitstop, and equipped glow alignment in Godot before further expansion.

### v2.21 — wand grip, sword attack tracking, magic sound and closer camera (source implementation; visual review pending)

- Replace wand idle/walk/cast body frames with the existing approved hook-free action art, preserving frame durations; align wand atlas frames to the clean-body wrist guides used by physical layer, glimmer and spell origin. Suppress wand artwork outside wand poses and choose FX from the visible pose. Rear grip is estimated when occluded.
- Normal sword attack FX respect the actual animation frame count, sprite mirroring and offset, and are suppressed during non-blade clips. Existing hand-authored blade axes remain the fallback; further per-pixel calibration requires art inspection.
- Original filtered-air/glass-resonance sounds for wand windup, release, charged release and confirmed impact; preserve sound settings, voice cap and combat timing. Gameplay camera zoom 1.12.
- Existing seeds, save schema, character source images, damage and hitboxes unchanged. Extend existing wand and audio smoke checks. Godot parser, F5 four-direction grip/attack/zoom checks and listening remain required; no Actions dispatch.

### v2.19 — honest seeded and personalized appearance identity (source implementation; engine pending)

- Distinguish current seed from original birth seed and separate saved custom glow, bow-body/arrow decoration, and eye preferences in advanced Inspect and offline collector cards. Ordinary tooltip stays compact; no new roll odds or fields.
- Natural arrow selection exposes the current seed's motif as a tooltip; the same unchanged SHA-256 channel is exposed read-only even if an ornament is manually selected. Rename eye reset to Natural (current seed, not original birth look). GG1 remains the base appearance code; copying it does not reproduce custom overrides.
- Extend existing v2.16 smoke with synthetic read-only, legacy-default, seed-invariance and presentation assertions. No new test registration, game damage, save schema, authored art or workflow triggers. Godot parser/F5 and real save testing remain pending.

### v2.18 — local regression coverage (source implementation; engine pending)

- Restore the four omitted Godot smoke scripts (v2.09 share cards, v2.10 cosmetics, v2.11 blunt/scythe aura, v2.14 scythe effects) to the ordered local runner. Quick also includes legacy dropdown, collection recovery and transfer-integrity checks; full runs all 54 existing smoke scripts exactly once.
- Add a read-only registration audit and a `preflight` mode that runs source hygiene and the current v2.16/v2.17 offline source checks before requiring Godot. No game scripts, assets, item data, saves, or workflow triggers changed.
- Source registration compared against the pinned mainline GitHub test directory; real local Python execution, Godot headless, F5 and old-save testing remain pending. No GitHub Actions jobs started. Run `bash GhostGirl2/tools/run_smoke_suite.sh preflight` then `bash GhostGirl2/tools/run_smoke_suite.sh quick` locally. Full is optional on demand.

### v2.17 — finish v2.16 mainline integration and complete bow-glow mode isolation (source committed; engine F5 pending)

- [x] **Recovery of a real integration gap:** PR #64 merged v2.16 at head `050bed8121b63de9a6bfb4ebc597df4927bd3a4a`, before later corrections on its feature branch. A fresh branch from the current `main`, `fix/v217-mainline-fx-compat`, carries the 12 distinct post-merge corrections. This is **not** cherry-picking over an older stacked feature branch.
- [x] Owner-selected 10/20/30/40/50% intensity is now literal 0.10/0.20/0.30/0.40/0.50 rather than the earlier doubled ratio. Collector's Lens bow-mask opacity respects the selected value rather than multiplying the full-bow 50% into 75%.
- [x] Preserve test-only cosmetic categories through the separate labeled debug switch; do not replace the player's saved glow menu or reactivate the old typed `RadioButton` parser bug.
- [x] Honor **Glow Off** in the scythe, other heavy-weapon FX (mauls/flails/halberds), paired-sword aura, bow release and impact lights, without hiding opaque physical weapons or skipping hits. Preserve rare seeded FX in Natural mode. Repair older source assertions that expected the old scythe preview-only behavior.
- [x] **Bow body Off now suppresses all bow-owned live illumination**, including incidental signature/Mythic filaments that previously bypassed the user's chosen mode. The separate projectile ornament remains independent; limb-only glow keeps its Mythic streak on the limb instead of secretly illuminating the disabled string.
- [x] Extend the existing `v216_editable_fx_bow_wand_smoke.gd` rather than adding another slow Godot test. Check all five limb/string modes and global Glow Off, persisted opacity, and world-FX suppression; strengthen `v216_offline_preflight.py` for mainline recovery without increasing GitHub Actions load. Existing legacy item fields and item seeds are unchanged.
- [ ] **Local Godot headless parser, actual F5 visual/auditory checks, save/load on an old backed-up collection and performance remain unverified.** Draft PR [#65](https://github.com/sinnes7kx/2D-Game/pull/65) now targets `main` directly. Actions stays manual-dispatch-only; do not run remote checks merely for each source change. Confirm engine behavior and review before merging/release.

### v2.20 — consistent bow projectile decoration opacity (source implementation; engine pending)

- Fix saved Off/10–50% glow on the physical arrow's decorative head, particles, elemental effects, and painted echo arrows. Keep the actual shaft fully opaque, one physical projectile, unchanged collision, damage, elemental mechanics and range scoring. Natural retains the existing full-strength decoration.
- Apply the same saved multiplier to release and impact FX; the separate lantern trail uses its existing global intensity factor and now initializes opacity before the first draw. No new seed traits, rarity changes, save schema, artwork or automatic Actions triggers.
- Extend v2.03 synthetic smoke with linear opacity/pigment/damage checks. Source comparison verifies physics code is unchanged; actual Godot parser, render and F5 checks remain pending. This is an independent main-based PR, not dependent on v2.19.

### v2.16 — saved glow choices, glowing bows, seeded arrow signatures and authored wand alignment (source committed; Godot F5 pending)

- [x] **Glow is a saved visual preference**, not a forced rarity reroll. Add optional `glow_level_override` (-1 Natural, 0 Off, 1–5 = 10–50%), `bow_glow_mode_override` (-1 Natural, 0 Off, 1 limbs, 2 limbs + string, 3 full bow) and `bow_projectile_style_override` (-1 Natural or 0–8 named visual styles). Defaults preserve all earlier saves and original collector snapshots; saved looks can restore the additional choices. All three fields are independent of genuine `item_seed`, `cosmetic_uid`, affixes, birth roll and gameplay damage.
- [x] Display these choices as **native CheckBox + ButtonGroup radio sets** for actual owned sword/wand items in the freed inventory detail space. They are available outside debug mode. Each save uses the existing inventory persistence gate, rolling back the in-memory cosmetic choice if saving fails. The older eye editor and test-only cosmetic categories remain independent.
- [x] Make the existing Collector's Lens scythe glow selector a **saved** Natural/Off/10–50% choice for an exact owned item, rather than an unsaved preview. Unowned display snapshots cannot silently modify a collection; blocked saves restore the previous setting. The original blade highlights are still independent of the optional full-scythe aura.
- [x] Restore legible live weapon FX for both genuinely special seeded items in Natural mode and owner-selected glow, with a small shape-following fallback for older rigs. The user-selected Off disables added light, not the opaque weapon or damage. Bow limb, string and full-bow glow now have distinct modes. The inspection model gets a separate additive glow layer using the **same bow-only mask** as its painted in-hand artwork; both views honor the global illumination setting. The actual saved bow palette gradients remain independent of the string gradient.
- [x] New bow seeds derive a **stable, independent projectile ornament** from the saved cosmetic UID: most bows stay plain, while some receive Moonthread, Twin Helix, Halo Burst, Petal Drift, Glass Motes, Comet Tail, Starlace or Wisp Bloom. Players may personalize that ornament without altering genuine seed rarity. All extra imagery is drawn inside the **one** existing `bow_arrow_v126.gd` projectile, with no added collider, damage, extra arrows, targeting, or range-trial success events.
- [x] Share the existing **`wand_pose_guides_v163.json`** for body-frame wand grip/tip, fallback glimmer, prestige FX and the ordinary projectile launch origin. Align artwork to direction-specific Ghost-local hand grips, including authored idle rotation. This is a pose calibration; visual alignment on all four facings, walk, cast and combat still needs real Godot F5 review.
- [x] Add synthetic `tests/v216_editable_fx_bow_wand_smoke.gd` and local-only `tests/v216_offline_preflight.py`. The tests cover legacy optional-field defaults, cosmetic UID/stat preservation, failed-save rollback, scythe 0/50% settings, seeded projectile stability and rare distribution, physical arrow damage invariance, actual bow-mask Inspect glow, and wand guide positions. Include Godot smoke in `tools/run_smoke_suite.sh quick`.
- [ ] **Integration note (updated 2026-11-26):** PR #64 merged v2.16 into `main`, but omitted later changes committed to its head branch. See v2.17 for recovery. Run local `python3 GhostGirl2/tests/v216_offline_preflight.py` and `bash GhostGirl2/tools/run_smoke_suite.sh quick`, and do F5 comparisons of all weapon families, 0–50% opacity levels, arrows, wand casting in every direction, save/load and performance before claiming validation. No F5 approval has been established.
- [ ] Back up `user://ghost_girl_treasures_v2.json` before testing: older builds do not know the three new optional cosmetic keys and may discard those *preferences* when resaving, although original item seeds and stats stay unchanged.

### v2.15 — pose-aware eyes, authentic carried bow inspection, accessible eye customization, B inventory and visible FX (source-only; F5 pending)

- [x] Recalibrate luminous-eye masks against the real pupils in the user-supplied character-screen screenshot: the previous bright rings were about 18–21 preview pixels left and 16–17 pixels below the dark pupils. Use new direction-aware base anchors plus per-frame offsets for idle, walk, attack, dodge and jump, with no back-facing eyes. Recompute overlay drawings on actual animation changes and keep the opaque normal-blend pupil backing. **All four directions and all animation families still require F5 visual inspection**; this is calibrated source art, not claimed pixel-perfect test footage.
- [x] Add a dedicated **Edit eyes** button on the equipment screen and always-available (not debug-only) **Shape** and **Color** exclusive choice groups for the actual equipped/selected `v202_luminous_eyes`. Changes to `eye_style_override` and `eye_palette_override` are cosmetic, recorded separately from the genuine `cosmetic_uid`, item seed, inherent rarity, and birth roll. Optional save keys default to `-1` on legacy items and saved looks; old bookmarks restore their original natural style. Blocked writes roll back the in-memory choices. Existing seed rerolls and favorites remain available.
- [x] Map **B** to Inventory & Equipment in the real Godot InputMap and HUD; move the previous **B healing shortcut to N** to prevent opening inventory while consuming healing dew. Keep TAB and I as existing aliases. Update the control guide; do not change healing stats.
- [x] Collector's Lens bows no longer use an independent icon recolor: display the **same front idle, bow-only 256×220 authored atlas** and the same v139 bow-only mask/seeded surface palette as the actual in-hand bow, with both layers sharing the same grip pivot, rotation and opacity. Wand/icon fallback remains unchanged.
- [x] Restore independent native scythe cutting-edge FX while preserving 0–50% optional whole-scythe aura; improve aura readability at gameplay scale and re-render on FX-intensity changes. Make bow special FX follow a **visible** bow or carry node instead of inheriting hidden color-mask visibility; raise bow-only light visibility without changing projectile damage or item stats.
- [x] Add `tests/v215_eyes_bows_input_fx_smoke.gd` plus `tests/v215_offline_preflight.py`; run the new synthetic Godot test and historic eye-coverage test in the local quick suite. Test fixtures never write to `user://`.
- [ ] **No GitHub Actions, no PR, no main merge.** The work is on `fix/v215-eye-poses-bow-parity-inventory-fx` directly based on the current mainline v2.13 branch. Run `python3 GhostGirl2/tests/v215_offline_preflight.py`, `bash GhostGirl2/tools/run_smoke_suite.sh quick`, F5-check eye cover for every pose/view, inspect-vs-equipped bows in each facing and animations, new eye controls and saved look restore, key B/N behavior, and full FX intensity 0–200%. Back up `user://ghost_girl_treasures_v2.json` before testing saves or downgrading; older builds will not preserve the two optional eye-style preference keys when re-saving.
- [ ] True frame-by-frame pupil alignment and rendered bow color match are **not verified without the Godot renderer**; the new anchors and mask parity require visual feedback before release.

### v2.13.1 — Godot cosmetic radio parser hotfix (source committed; local F5 pending)

- [x] Fix actual Godot 4.7 parse blocker `Identifier "RadioButton" not declared in the current scope` at `inventory_panel.gd:560`, 571 and 598. Replace each nonexistent `RadioButton` type/constructor with native `CheckBox` and retain independent `ButtonGroup` exclusivity for all eight categorized, unsaved cosmetic preview sections. No inventory/stat/seed/save changes.
- [x] Update `tests/v210_offline_preflight.py` to forbid `RadioButton` in the live script, and `tests/v210_inventory_cosmetics_visual_smoke.gd` to verify valid grouped `CheckBox` instances for every section. This change is on the combined v2.13 branch; older unmerged v2.10 PR/branch may still contain the bug.
- [ ] Rerun local Godot 4.7 project import and v2.10 inventory smoke, then F5-open inventory and test Natural/preview selection per category. No GitHub Actions run or live Godot parser result is claimed; the manual-only workflow remains unchanged.

### v2.13 — world-size twinblade presence and softer physical combat sound (branch-only; F5 pending)

- [x] In-world **Gloamrose paired swords** now extend their authored blade spans visually by 34% in idle/walk and 17% during attacks, with both wrist anchors unchanged and tips still confined to the existing 256×220 atlas-frame budget. Opaque modular blade widths and silhouette-aligned edge strokes are more legible at Ghost Girl's reduced world scale, and their saved-palette glow becomes modestly brighter. Combat range, hitboxes, attack timing, stat seeds and cosmetics remain unchanged.
- [x] The separate **double-ended twinblade** family also receives a small drawing-only extension from 68 to 76 source-space units, with a matching fallback. Other weapons are not globally scaled; original world/body artwork and frame assignments are preserved.
- [x] Rework original generated `combat_juice_v194.gd` swing foley into gentler filtered-air movement, with less pitched buzz. Hit/parry sound uses a short damped physical contact texture and subtle steel resonance. Lower the older overlapping hit/swing one-shot levels in `player.gd`, preserving hook, dodge, audio accessibility settings, hit logic and global audio volume behavior. These are **procedural sound-design approximations**, not field-recorded Foley or externally licensed assets; subjective listening is still needed.
- [x] Add `tests/v213_twinblade_audio_smoke.gd` and `tests/v213_offline_preflight.py` to verify authored pose bounds, minimum paired sword idle length, procedural clip structure/peak non-clipping, and synthetic saved-item identity. Include the Godot smoke in the manual/local quick suite.
- [ ] Source-level changes are assembled on **`fix/v213-visible-twinblades-soft-foley`**, built on the still-unmerged v2.12 combined branch and preserving v2.10/v2.11 cosmetics. **No automatic Actions or PR were triggered** while credits are unavailable; this is not a `main` release. Run the local preflight, `bash GhostGirl2/tools/run_smoke_suite.sh quick`, and F5-check paired sword lengths in four directions (idle, walk, heavy, riposte), no blade clipping, visual consistency of rare/anomaly equipment, world FPS on older GPUs, realistic soft sound dynamics, and save/reload. Preserve user:// save backups before changing branches.
- [ ] The long-term sprite-sheet consolidation remains an opt-in unlinked experiment in v2.12; this change does not delete PNGs or remap existing textures.

### v2.12 — single-dagger stab identity and budget-safe Godot validation (source on feature branch; F5 pending)

- [x] Single daggers (including Nocturne) choose the **actual existing 8-frame `_pierce_`** animation for every light attack, not the baked slash animation. Heavy chooses `_heavy_pierce_`, has a distinct longer windup and a bounded hold-to-charge gate: release after 0.16 s or automatically after 0.58 s. One physical strike at the existing damage gate; no multiplied damage or extra hitboxes. Dual daggers retain their separate combo system.
- [x] Suppress the unrelated crescent Rose Slash sprite on **single-dagger confirmed contact**, and the heavy swing wake for this style. Keep narrowly forward-facing dagger hit checks and the existing blade-aligned equipment glow. Other weapons retain their own slash/swing feedback. Original approved Ghost Girl texture pixels and source atlas mappings remain unchanged.
- [x] Replace automatic PR/push Godot Actions with **manual `workflow_dispatch` only** while Actions funds are unavailable; the old 60+ step workflow becomes a single choice of `quick` or `full`, both sharing one Godot import. `bash GhostGirl2/tools/run_smoke_suite.sh quick` runs targeted inventory, animation, bow/blunt and new dagger checks locally. `full` retains the historic exhaustive suites, on demand only. Automatic CI coverage is therefore intentionally suspended and no cloud jobs were started for this branch.
- [x] Supply `tools/build_legacy_atlas.py` to **report** complete eight-frame legacy PNG sequences and optionally build unlinked 8×1 atlas candidates with exact source→region metadata. The tool does **not** delete PNGs, rewrite `.tres` references, alter frame timings, or claim import-time savings until a separate verified resource migration is approved. Existing authored 2048×1760 sprite sheets stay authoritative.
- [ ] Run `python3 GhostGirl2/tests/v212_offline_preflight.py`, then `bash GhostGirl2/tools/run_smoke_suite.sh quick` on a machine with Godot 4.7.2. Run the complete suite locally before release; F5 check light and heavy stab poses in all four directions, charge/release on keyboard and mouse, attack range, hitstop, retained gear glow and other weapons. No successful local engine or interactive run is claimed yet.
- [ ] The supplied Actions screenshot comes from a previous PR run with an undefined `query` variable; the inspected current `main` vault no longer contains that line. This branch protects against its reintroduction but does not imply the old run passed. **Combined branch `fix/v212-combined-dagger-and-cosmetics` is not merged into main**, and no PR was opened to avoid new automatic checks from older workflows.
- [ ] Actual sprite-sheet consolidation must be done later in small, visual-tested batches, remapping only confirmed obsolete per-frame resources after proving frame, opacity, animation order, and UID compatibility; do not bulk-delete artwork.

### v2.11 — restored blunt weapon displays and separate scythe silhouette glow (combined with v2.10; local tests pending)

- [x] The `v203_mournful_mace`, `v203_rosequartz_morningstar` and `v203_nightchain_flail` definitions and their independent `BLUNT_LOOT_TABLE` lane were **already present**; they were not deleted. Collector's Lens previously called `HEAVY.draw_heavy(...)` without the actual `item_id`, making these maul-class collector pieces render as generic heads in the inspect view. It now passes the original ID and uses `BluntWeaponFamilyV203` geometry in both preview and equipped view.
- [x] Maul glow now surrounds the **entire closed head outline**, not just the first four vertices. Mace, morningstar and flail display FX similarly follow their full flanged/spiked/chain-head outlines with restrained broad colored rims rather than a single stroke.
- [x] Prototype an **independent `ScytheGlowLayerV211` Node2D**, both in the real scythe rig and in Collector's Lens: shaft plus both sides of the curved blade are surrounded by layered soft glow without changing original weapon polygons, hitboxes or combat. A separate cosmetic-UID domain rolls exact 0%, 10%, 20%, 30%, 40%, 50% opacity levels; approximately 70% of eligible appearance UIDs choose **0%**. These are unlabeled intensity levels, not false global rarity grades. The roll is fully deterministic and works with old saves through legacy visual-seed fallback, without new save keys.
- [x] Collector's Lens allows trying all six opacity steps and returning to the actual rolled level. The selector is explicitly **preview only** and must not save or mint a new look. F7 weapon trials expose the three existing blunt forms **only in Godot debug builds**, without increasing natural drop odds or replacing acquired items.
- [ ] Run `python3 GhostGirl2/tests/v210_offline_preflight.py` and `python3 GhostGirl2/tests/v211_offline_preflight.py` locally. Run `godot --headless --path GhostGirl2 --script res://tests/v211_blunt_scythe_aura_smoke.gd` and the existing v2.03 and v2.10 smoke tests locally, then visually F5-test every side/attack pose, rarity step, default 0%, real loot/drop flow, and item save/reload. Static source checks are **not** Godot rendering verification.
- [ ] Work is assembled on `fix/v211-combined-cosmetics-and-blunt-glow`, based on the v2.10 cosmetic/UI branch (which itself is not merged into main). No PR or GitHub Actions run while funds are unavailable. The two stand-alone work branches are not the recommended install target. No existing combat stats, item seeds, equipment keys, cosmetic fields, drop tables, or save schema were altered.

### v2.10 — inventory cosmetic layers, readable special tooltips, bow pigment and eye placement (source only; F5 pending)

- [ ] Hide the duplicate bottom item-stat block and "SELECTED ITEM" header in the active inventory while preserving legacy paths for compatibility. Retain Reroll, Save ★, Saved Looks, Equip, Socket, Inspect and safe destructive actions. The **debug-only** TestMythic dropdown is replaced visibly by categorized layer-specific radio controls (signature, Mythic detail, material, color motion, glow, surface, guard and grip) with independent Natural resets, disabled unsupported choices and explicit **TEST · NOT SAVED** labeling. Actual rolled cosmetics remain determined by the saved UID and existing reroll/favorite flow; debug controls never mint a rare drop.
- [ ] Restore a concise genuinely rare seeded appearance/material line and visible glow/trail/bow-arrow information in the normal item tooltip; keep detailed numeric seed/roll information in Collector's Lens. Replace tiny individual metadata links with one broad hover area per full color row and very short plain-English explanations. Update the historical v1.96 tooltip smoke for the new interaction while retaining legacy per-dot meta safety.
- [ ] Allow the existing separate bow-only color mask to apply much stronger pigment without recoloring Ghost Girl's original body. Preserve three independent seeded bow-limb stops and the separate bowstring colors; existing v2 true-onyx ramps can now visually reach near black. Move idle bows subtly rearward for both side facings and keep the right-bow mirror and its color-mask pivot synchronized when facing left.
- [ ] Reposition luminous-eye centers from the hairline to the lower face, and give their dark backing an explicit normal-mix material instead of inheriting additive glow. This is an **estimated atlas-local calibration**, not a claim of verified per-frame pupil coverage; check front/left/right idle, walk, dodge, combat and both equipment/world scales in Godot.
- [ ] Run `python3 GhostGirl2/tests/v210_offline_preflight.py` for source-level checks and `godot --headless --path GhostGirl2 --script res://tests/v210_inventory_cosmetics_visual_smoke.gd` for the new Godot test. Also run existing `v1921_dropdown_compat_smoke.gd`, `v196_compact_tooltip_smoke.gd`, `v203_bow_airborne_blunt_smoke.gd` locally and F5-check the UI, eye anchors, bow palettes/hand pose and saves. **No GitHub Actions or PR initiated while credit budget unavailable**; no engine test is claimed.
- [ ] This is branch-only work on `fix/v210-inventory-cosmetics-bow-eyes-tooltips`; no serialization keys, combat stats, drop odds or body atlas pixels were changed. User visual acceptance and local Godot validation are outstanding.

### v2.12 — single-dagger stab identity and budget-safe Godot validation (source on feature branch; F5 pending)

- [x] Single daggers (including Nocturne) choose the **actual existing 8-frame `_pierce_`** animation for every light attack, not the baked slash animation. Heavy chooses `_heavy_pierce_`, has a distinct longer windup and a bounded hold-to-charge gate: release after 0.16 s or automatically after 0.58 s. One physical strike at the existing damage gate; no multiplied damage or extra hitboxes. Dual daggers retain their separate combo system.
- [x] Suppress the unrelated crescent Rose Slash sprite on **single-dagger confirmed contact**, and the heavy swing wake for this style. Keep narrowly forward-facing dagger hit checks and the existing blade-aligned equipment glow. Other weapons retain their own slash/swing feedback. Original approved Ghost Girl texture pixels and source atlas mappings remain unchanged.
- [x] Replace automatic PR/push Godot Actions with **manual `workflow_dispatch` only** while Actions funds are unavailable; the old 60+ step workflow becomes a single choice of `quick` or `full`, both sharing one Godot import. `bash GhostGirl2/tools/run_smoke_suite.sh quick` runs targeted inventory, animation, bow/blunt and new dagger checks locally. `full` retains the historic exhaustive suites, on demand only. Automatic CI coverage is therefore intentionally suspended and no cloud jobs were started for this branch.
- [x] Supply `tools/build_legacy_atlas.py` to **report** complete eight-frame legacy PNG sequences and optionally build unlinked 8×1 atlas candidates with exact source→region metadata. The tool does **not** delete PNGs, rewrite `.tres` references, alter frame timings, or claim import-time savings until a separate verified resource migration is approved. Existing authored 2048×1760 sprite sheets stay authoritative.
- [ ] Run `python3 GhostGirl2/tests/v212_offline_preflight.py`, then `bash GhostGirl2/tools/run_smoke_suite.sh quick` on a machine with Godot 4.7.2. Run the complete suite locally before release; F5 check light and heavy stab poses in all four directions, charge/release on keyboard and mouse, attack range, hitstop, retained gear glow and other weapons. No successful local engine or interactive run is claimed yet.
- [ ] The supplied Actions screenshot comes from a previous PR run with an undefined `query` variable; the inspected current `main` vault no longer contains that line. This branch protects against its reintroduction but does not imply the old run passed. **Branch `fix/v212-dagger-thrust-ci-cost` is not merged into main**, and no PR was opened to avoid new automatic checks from older workflows.
- [ ] Actual sprite-sheet consolidation must be done later in small, visual-tested batches, remapping only confirmed obsolete per-frame resources after proving frame, opacity, animation order, and UID compatibility; do not bulk-delete artwork.

### v2.08 — collection vault organization (stacked source; CI/F5 pending)

- [ ] Add family and quality filters plus stable original-order, quality, name and equipment-family sorting to the existing stash panel. Existing text search and favorites filter still work in combination; sorting never changes `inventory.contents` or `inventory.vault`.
- [ ] Prevent actions against an item hidden by a filter by clearing invisible selection. On reopening, reset list controls to an understandable default. All operations continue to use exact item references and established save protections.
- [ ] Add `tests/v208_vault_filters_smoke.gd` covering real head/weapon item fixtures, stable ordering, filtered selection safety, immutable save snapshots and the actual UI controls. No new item fields, source timestamps, unsupported acquisition ordering, or invented rarity scores.
- [ ] This is a **stacked PR dependent on the broader equipment vault PR #49**. Merge #49 into `main` before integrating this slice into `main`. Headless CI and live F5 (narrow layouts, large collections, older GPU) remain acceptance gates.

### v2.03 — physical bow grips, more airborne motion and blunt weapon variety (source implementation; F5 approval pending)

**User-provided visual defect (2026-11-25):** The front and left idle bows were floating away from the correct wrist in the inventory preview and in the world. The physical full-color bow and independent palette layer had a shared pivot, but its **grip target** was under-calibrated in those authored facings. Color reroll is shader-only; it must never cause the weapon to move.

- [ ] **Bow grip calibration:** preserve the same explicit single-rotation bow carry animation and matching `BowCarryV166`, `BowPaletteV139`, and child prestige FX transform, while applying a small atlas-local per-facing physical-wrist correction (`front -20,+10`, `left +16,+13`, `right -3,+5`, `back -4,+5` atlas pixels). Test both Thornrose and Moonveil in all four directions, with item coloring changed after equip and via saved-look rerolls, and inspect the real image: analytical handle invariants **cannot** prove a hand is visually correct.
- [ ] **Higher, more expressive jumps:** increase the visual airtime from 0.56 to 0.62 s and apex displacement from 20 to 34 px (before the separate 0.52 character sprite scale), while keeping the original barrier layer and stamina/collision decisions. The shadow stays grounded. A boosted aerial heavy gesture has a distinct wind-up/plunge/landing shape, directional tilt and subtle streak, including on misses; confirmed-hit hitstop still requires contact.
- [ ] **Dedicated airborne 8-frame clips:** all supported ground heavy weapon families (sword, polearms, twinblades, dagger, dual weapons, scythe, maul) and unarmed/wands receive a separate airborne animation clip. Bow short-shot and charged-shot releases gain analogous clips. Source frames remain the original approved Ghost Girl directional attack art; only independent timing and body travel are newly animated, not an invented fully repainted sprite sheet. Color masks, weapon rigs, guides and FX must continue following those same physical hands.
- [ ] **Arrow-only airborne attack authority:** preserve the single real projectile and one release event while skipping the previous duplicate invisible melee strike in `_advance_jump()` when a bow is equipped. Do not change bow damage, hitbox or authored attack timings on the ground.
- [ ] **Blunt weapon family:** distinguish the existing Gravebell Maul and Ashglass Warmaul as blunt in impact classification and default tooltips, with no destructive change to their old item seeds/stats/visual variants. Three new collectible item bases—**Mournful Mace**, **Rosequartz Morningstar**, and **Nightchain Flail**—share maul-class combat tuning for this safe initial slice, but each has an original icon and original separate on-body flanged/spiked/chained geometry; linked flail head is visual-only and cannot create extra hits. Replace blade-slice FX with blunt impact debris on successful hits. Add a small 1-in-41 eligible ordinary-drop lane *outside* the existing 1-in-7 sword indexing to avoid reshuffling all prior sword drop seeds.
- [ ] Run `tests/v203_bow_airborne_blunt_smoke.gd`, earlier v2.00/v2.01/v2.02 suites, main-scene import and F5 visual approvals. Check head/hand alignment after *several* color rerolls, front/left walk-to-idle transitions, jumping/landing with each weapon including bow and wand, flail chain color/angles, enemies' blunt stagger and hit response, saved item/vault migration and older GPU effects before merging.

### v2.02 — lively Lanternhaven, original Moonmoth, fletcher trial and separate headgear (source implementation, F5 pending)

**User request and current gap:** Glowing Eyes were only a planned M1 head-slot experiment; they had **not** been implemented as equippable visual items. The current `wings` equipment save key previously drew one generic headpiece/tiara. This slice turns that legacy slot into **Head Accessory** without renaming its save key and introduces a *separate additive* `helm` key for tiaras and diadems.

- [ ] **Wearable prototype:** four original head-accessory bases (`v202_luminous_eyes`, `v202_bandit_mask`, `v202_crescent_halo`, `v202_rose_horns`) with distinct 96×96 icon assets and four-facing frame-following in-game overlays. Two independent metal helms (`v202_moonlit_tiara`, `v202_starfall_diadem`) can be worn alongside an accessory. All six are discoverable fixed-seed world pickups in Lanternhaven, Moonthorn Woods and Briar Hollow; no special forced high rarity is advertised. The legacy `rosewing_mantle` still uses `wings` and its previous graphic.
- [ ] Old saves with `wings` only load unchanged; new saves add `helm`: -1. Equipment/UI has an explicit new Helm button, the old button reads HEAD ACCESSORY. Test equip/unequip, old save, full inventory, protection, vault and exhibition fidelity, and all four pose directions. The visuals are an **original procedural preview**, not final authored individual atlases. Do not mark M1 equipment complete before real F5.
- [ ] **Town and outdoor wildlife:** a bounded handful of tiny editor-placed original moths, crows, hares and foxes wander gently and avoid the player in Lanternhaven, Moonthorn Woods, Briar Hollow and Weeping Brook. No hostile AI, loot, hitboxes or persistence. Profile low-spec Godot performance before increasing counts.
- [ ] **Original nonverbal Moonmoth companion:** a small winged moonlight familiar follows the player across room changes and brightens around unresolved optional secrets. No Nintendo/Navi art, writing or audio is copied; no extra combat power, path-blocking physics, voice spam or inventory writes. Later design could add optional follow distance, dismiss/hide controls, more expressions and discovery cues without spoiling puzzles.
- [ ] **Lanternhaven three-stage fletcher range:** real swept-arrow targets require (I) normal contact, (II) fully drawn charged contact, (III) airborne fully drawn contact. Count every actual bow arrow fired while in the lane; the **300/300 perfect** requires exactly three shots and three hits. A perfect score persists a new collected flag, revealing a one-time fixed-seed **rare Fletcher's Moonflight Bow** chest. Missing or firing extra shots scores below perfect; E resets the optional challenge. The bow is a scripted attainable prize, not a naturally rare mint or a population-verified unique item. Do not restrict comparable ordinary collector bows behind competitive precision.
- [ ] **Creative puzzles across rooms:** new lightweight Moonthorn root knot (fire, frost+hook, roses, patient hook, certain light arrows) and Briar Hollow bellstone (luminous arrow, aerial charged bow, frost+hook, repeated hook) expose separate once-per-save caches. Both reuse the canonical collection flags/chest mechanism and restore after room entry. The original v2.01 cave remains optional. Add more **distinct authored physical/environmental concepts** in subsequent regions (fallen bell towers, river currents, moon mirrors, brittle mineral bridges, lantern chains) rather than cloning identical interactables across every room. Reward a meaningful discovery, never a guessed mandatory one-button solution.
- [ ] Source tests: `v202_headgear_migration_smoke.gd`, `v202_fletcher_range_smoke.gd`, and `v202_living_world_puzzles_smoke.gd` are registered in CI. They must pass along with prior M0 migration/regression checks; never run a test that writes the player's actual inventory. Real F5 review must check lanes/line-of-sight, wolf/fox/harmless critter look, collision, 100%/200% character preview, save loading and tooltips.

### v2.01 — exploration landmarks and creative cave solutions (source implementation; engine and visual review pending)

- [ ] **Bow idle corrective check:** replace the ambiguous runtime 180° arithmetic with explicit **per-facing upright bow angles** for Thornrose and Moonveil. Physical bow, limb-mask shader and child FX must share a single source transformation around the actual wrist. Check front/back/left/right in F5 and both 100%/200% equipment preview; algebraic angle tests do not validate how an actual painted limb appears.
- [ ] **Handheld Pokémon-style exploration principle, not a visual clone:** reward curiosity when traveling between vivid, legible landmarks. Let an apparently impassable object suggest multiple mechanics. Keep the game's own gothic, painterly Ghost Girl identity; use context-sensitive clues, compact controls and original art instead of adopting copyrighted sprite assets or a Game Boy UI imitation.
- [ ] **Moonthorn Woods — Moonlit Hollow boulder:** scene-owned entrance artwork and real static collision physically obstruct an optional cave trail to existing Briar Hollow and its fixed-seed one-time cache. The normal forest-to-Briar-Hollow route stays available. This is an original procedural **entrance art prototype**, not a claim of a finished hand-painted new cave room.
- [ ] The boulder accepts **nine evidence-backed creative outcomes**: frost then a heavy blade/wand blow, frost then hook, patient repeated hook pulls, accumulated ordinary projectile force, grasping-rose magic, a charged midair bow shot, frost followed by fire (thermal shock), a strong thrown crate, or frost followed by a thrown crate. Inputs reuse existing Moonfall, elemental arrow, rose-hook, bow and projectile systems; no special single-key unlock or mandatory advanced skill route.
- [ ] The first successful solution saves a new namespaced collected-pickup flag **before** opening the physical route; unsuccessful writes roll back both completion and solution-method flags. Subsequent visits restore the clearance and cache visibility. One-time chest rolls use the existing generator and unchanged item seed. No save schema migration, damage, odds, or existing item identities change.
- [ ] Run `tests/v201_moonlit_cave_exploration_smoke.gd` and prior v2.00/inventory migration tests in Godot CI; manually test physical approach, line-of-sight, matching portal/hidden cache behavior, loading an old save, full-backpack rewards and fallback accessibility. Future authored room art and richer rock/physics interactions can follow after this slice is reviewed.

### v2.00 — dual-sword hand alignment, bow-native effects and M0 item safety (source implementation; F5 pending)

- [ ] Verify both dual swords grip the independently authored left/right hands in front, back, left and right idle, walk and attack animations. Covered wrists use conservative fallbacks; the real model/sprite alignment must be inspected at 100% and 200% zoom. No attack reach, damage or item stats change.
- [ ] Bow prestige FX (seeded aura, limb/string glows, trails, rare signature, collector motes, socket echoes) now use a **child of BowPaletteV139** for their drawing transform when a bow is equipped; they must follow the actual full-color bow pose/mask in idle and charged release, then return to Ghost body when another weapon is equipped. The heavy-charge string light is cosmetic only. Check all four directions, animations, and both bow families in F5.
- [ ] The previous upside-down bow idle is rotated 180° around the **same grip pivot** on both physical bow and tint mask. Visual approval is still required because automated pivot calculations cannot prove correct painting orientation.
- [ ] M0 next milestone: new `tests/v200_collection_transfer_integrity_smoke.gd` checks a **protected, favorite item with a saved V2 cosmetic appearance** through rejected vault deposit/withdraw (save blocked), successful storage/exhibition/withdrawal, and a JSON reload without changed stats, seeds, favorite or protection. This is a synthetic fixture, not the user's private saves.
- [ ] Run v1.74/v1.92.2/v1.97/v1.98/v2.00 smoke suite on GitHub CI; perform real F5 inventory → vault → exhibition → reload and low-spec performance tests before calling M0 complete.
- [ ] The older `scripts - Copy/` directory is absent from the tracked main tree as of this change; the duplicate-conflict warning in old roadmap notes is historical, not an active file in the current checkout. Continue rejecting unresolved tracked merge markers.

### Current visual defect slice (v1.92.3, source implementation)

- User screenshots show cyan/purple hair and inconsistent dress dye, missing held-weapon preview effects (especially bows), and a front-facing screen-right dagger grip offset. The body shader used whole-texture UVs and violet-pixel weapon classification; both are unsafe for mixed body atlases. Disable both color passes pending authored per-frame fabric masks; dress palette data and accessory/halo effects remain. This intentionally suspends dress fabric dye rather than risking recoloring hair/skin.
- Shared blade-local signature geometry, restrained motif accents, actual bow-mask signature uniforms and mirrored guide offsets; single detailed pass per twinblade end. Correct the neutral front screen-right hand anchor against the existing body art. No changes to combat or saved item data.
- New `tests/v1923_equipped_fx_smoke.gd` exercises real dropdown, equipped/inspection look parity, bow shader parameters, neutral body shader controls and preserved item data. Registered in CI; interactive four-direction and weapon alignment checks remain release blockers.
- PR #28 (v1.92.2 collection recovery) is now merged, but its recorded CI run 45445026003 failed. The recovery smoke was restored in v1.93 and passed CI run 45476584242; broader real-save and transfer gates remain open. M0 is not complete.
### Current evidence and blockers (v1.92.2)

- v1.92.1 PR #27 merged; GitHub Actions run [45381388211](https://github.com/sinnes7kx/2D-Game/actions/runs/45381388211) succeeded, including the current/legacy/missing TestMythic control smoke. The local F5 confirmation and release-export UI check remain outstanding.
- v1.92.2 source: backpack records that cannot load (missing definitions or insufficient space/capacity) now persist in an additive `unresolved_backpack` array and are retried on later loads. Recovery never evicts an active item or auto-equips an inaccessible record. Original saved equipment indices remap only to successfully loaded original backpack records. Unknown raw fields are retained while a record is unresolved; once it becomes playable, the normal serializer applies. Inventory reports pending recovery. Invalid top-level save/container structure disables saving rather than overwriting the original file. Old v2 grid migration backs up the original bytes; legacy v1 stays intact.
- New synthetic fixture test `tests/v1922_collection_recovery_smoke.gd` covers missing resources, overflow, grid migration, identity, duplicate cosmetic UID with distinct item seeds, invalid containers, and isolated backup creation. Added to CI; result pending at commit time. No private saves used.
- Keep the ignored `scripts - Copy/` backup unchanged until its conflict-marked contents receive explicit cleanup review; it already has `.gdignore`. Do not replace live scripts with this directory.
- Remaining P0 gates: interactive F5, real older-save corpus, full disk-write failure handling for ordinary pickups/destruction/equipment, broader malformed nested-record validation, appearance versioning, and a full tracked resource/node-path audit. Do not mark M0 complete yet.

### Live equipment preview and FX testing (v1.92.4, source implementation)

- Character screen replaces the static Doll texture at runtime with an isolated SubViewport using the actual player scene, equipped-item layers, and current idle animation. Four directional views, read-only shared equipment references, no gameplay input/collision or player-group registration; processing and viewport rendering disabled when hidden. Original portrait scene remains a fallback resource.
- In-game session-only 0–200% held weapon FX intensity slider and 100% reset affect equipped prestige overlay, shared edge/signature passes, painted weapon material overlays and inspection. Base weapon art and Ethereal condition opacity are not changed. Dress/accessory aura and combat projectile/impact effects are outside this slider's scope.
- Debug effect menu keeps existing IDs, explains family/pose/rarity dependencies, marks unequipped items as inspect/equip-first, distinguishes visual Ethereal from durability, and disables unsupported surface/guard/grip choices. Effects and intensity do not become saved item data.
- New `tests/v1924_live_preview_smoke.gd` tests isolated actual rig, direction, slider, selected preview, bow compatibility, no item mutation, and hidden-preview processing. CI run [45458675481](https://github.com/sinnes7kx/2D-Game/actions/runs/45458675481) succeeded and PR #30 merged. User subsequently confirmed the preview works in their local game; full directional/visual/performance checks remain outstanding. Prior v1.92.3 PR #29 CI succeeded and was merged; unsafe dress recoloring remains disabled.

### Lanternhaven town and collection access (v1.93, source implementation)

- Explicit user priority: build a safe starting town with the emotional contrast of Diablo II's protected encampment and threatening world beyond. This narrow M2/M3 vertical slice is brought forward at the user's request; M0 remains an open release gate. Town is a warm, quiet collector home with no hostile spawns, clear boundaries, original artwork, a stash, restorative ember, and space for future NPCs. The initial 3600 × 2400 room is an original vector blockout, not final painterly art or verified Act I scale parity.
- New and existing sessions start in Lanternhaven; existing story flags, world shrine checkpoints, inventory, vault and exhibition assignments are unchanged. The existing crypt remains reachable and has a return gate. Sanctum shortcut opens only after the existing cloister progression gate; its return route is available. Town NPCs, merchants, crafting and final atmosphere/audio are deferred.
- Physical stash reuses the existing vault, not a second item store. E opens the chest; Stored/Backpack tabs select eligible weapons and wands, with deposit/withdraw restricted to chest proximity. Remote collection viewing, inspection and display management remain available. Existing vault capacity and eligibility remain unchanged. No inventory schema or loot-generation changes.
- New town regression checks authored scene landmarks, dimensions, reciprocal route resources, absence of hostile spawns, chest interaction, transfer access, and rollback/identity/protection/display invariants. Restored omitted v1.92.2 recovery regression to CI and adjusted its JSON-number comparison to test semantic metadata preservation. PR #32 CI run 45476584242 succeeded, including the restored recovery smoke and town checks; user confirmed town access. Full interactive route/collision/UI tests remain pending; do not mark M0 complete. If the town route cannot be accessed in real play, fix connectivity before release.
- Roll Code and seeded head accessories remain separate M1 work (roadmap PR #31 merged). The requested ten-digit rarity fingerprint must use audited meaningful trait outcomes, distinguish birth/current/test, and preserve leading zeros.

### Done means

Fresh source imports, headless tests pass, **real F5 playtesting** confirms core item flow, all existing saves in the test corpus still load, and no item changes unexpectedly. Do not mark done on static checks alone.

---

## 4. M1 — Extraordinary seeded item identity (P1, core differentiator)

### 4.1 Every item tells a story

- [ ] Specify a formal **item identity model** before shipping online features: base definition, original generation seed, rolled stats/affixes, intrinsic visual traits, current appearance preset, rarity information, origin, and persistent instance identity.
- [ ] Treat the seed as a **reproducibility input**, not a guaranteed unique item identifier. Two generations of the same seed are not necessarily the same owned physical item.
- [ ] Preserve existing `item_seed`, `cosmetic_seed`, `cosmetic_uid`, `saved_cosmetic_looks`, and legacy saves; introduce new fields only through additive, versioned migrations.
- [ ] Define which traits are **birth traits** (never change on cosmetic reroll) versus **customizable looks** (can be saved/swapped), and make this distinction visually legible.
- [ ] Ensure changes to rendering code or a new content version do not silently change the look of old cherished seeds. Version appearance generation or preserve the required derived fields.
- [ ] Make each found weapon recognizable by silhouette, guard/grip, blade profile, materials, inscriptions, accents, subtle particles, and audio rather than simply changing color.
- [ ] Keep very rare effects restrained and beautiful; do not let every common drop have a maximal animated glow.
- [ ] Define rarities and special visual signatures as separate dimensions: **item quality**, **collector-appearance rarity**, **stat-roll desirability**, and **competitive prestige** must not be conflated.

### 4.2 Honest, extreme scarcity

- [ ] Audit the **actual** RNG paths, loot tables, quality odds, modifier frequencies, region sources, and ways a generated item can be rerolled.
- [ ] Define probability distributions for ultra-rare appearance combinations; use deterministic tests/simulations to verify them before publishing odds.
- [ ] Add rare and ultra-rare visual signatures with distinct authored presentation, not merely an enormous number in a tooltip.
- [ ] Make the rarest combinations aspirational **without** making normal players feel every drop is worthless.
- [ ] Offer multiple satisfying collection goals: unusual colors, shapes, rare materials, near-perfect rolls, provenance, themed sets, and extraordinary combinations.
- [ ] Avoid dishonest “only one exists” labels until an authoritative global registry can actually establish that claim.
- [ ] Publish transparent odds for any stated drop chance; do not quietly manipulate odds by player behavior, spending, or popularity.
- [ ] Prevent debug visual overrides, forced quality parameters, local editor tools, and item-preview seeds from producing trusted tradeable items.

### 4.3 Seed controls, favorites, and the meaning of rarity

- [ ] Audit current saved-look controls before adding alternatives: numbered seed readout should be available in **advanced item inspection**, not clutter the default tooltip.
- [ ] Preserve the current limit/behavior of saved looks unless the design explicitly upgrades it and tests migration.
- [ ] Allow saving a favorite look, restoring it exactly, and comparing two looks without rerolling combat stats.
- [ ] Distinguish a **new cosmetic look generated for an item** from the item's **original rare discovery imprint**.
- [ ] Never let appearance customization falsely manufacture a *new naturally dropped* ultra-rare signature. If customization can mimic a rare trait, distinguish “customized” from “found with”.
- [ ] Offer opt-in appearance “before / after” confirmation and a cancel path for expensive or irreversible operations.
- [ ] Audit inventory/tooltips so compact default swatches remain uncluttered; place seed IDs, channels, motifs, and technical provenance behind an explicit Inspect/Advanced action.

#### Collector Roll Code (user-requested, design proposal)
- [ ] Introduce a separate, shareable, fixed-width ten-character decimal **Roll Code** as a readable rarity fingerprint, not a replacement RNG seed, owned-instance ID or verified provenance. Preserve leading zeros. Each position corresponds to an actual applicable rolled trait/channel, with 0 reserved for its highest rarity outcome, 1–3 for increasingly less exceptional outcomes, and 4–9 for more common outcomes. Exact thresholds and family-specific mappings require an audit and deterministic simulations; do not publish arbitrary odds or treat raw uniform ticket digits as trait rarity.
- [ ] Prototype weapon position meanings: material, effect signature, particles, surface, palette, motion, glow motif, silhouette, grip and ornament. These are provisional: some traits are uniform, dependent, or unsupported on particular families; define documented family-specific applicable mappings before shipping, do not invent rarity for a color or absent feature. Only permit an all-zero perfect pattern for a family with ten real top-tier outcomes; use an explicit unavailable/legacy label until all positions are meaningful.
- [ ] Store/version the original natural-drop roll snapshot separately from the current customizable look. Show compact roll code on playtest hover and in Inspect/Advanced with per-digit explanations, source/version, natural vs rerolled labels, and separate debug-only overlay clearly marked TEST. Reroll preview must show the resulting genuine current-look code without changing the original discovery code, stats, ownership or protected saved looks. Debug forced effects must not change either genuine code. Old saves without reliable birth evidence must be labeled legacy/unknown rather than inventing history.
- [ ] Support recognizable patterns such as 0000000000 (all ten highest-tier traits), 0000001234 and repeated digits as collector goals. Never claim a particular joint probability or worldwide uniqueness without tested distributions, dependencies and ownership evidence. Preserve code version and meaning across saves, graphics settings, inspection, stash, exhibition and future trade. Expose copy/share in collector-facing UI; ordinary production tooltip can remain compact.


#### v1.93.1 Roll Code prototype (source implemented; validation pending)

- V1 is a ten-position string with five ranked channels where applicable: material, signature, particles, surface family, regional imprint. Remaining positions use '-' until meaningful rarity distributions are defined. Legacy UID-less signature, unsupported surface and ineligible region also use '-'. 0 is the rarest existing outcome per ranked channel, not a claim of equal per-channel probability. Full ten-zero pattern is deliberately unavailable in V1.
- Existing material/particle ticket counts are [6000,2500,1000,400,90,9,1] per 10000; signature thresholds use the existing UID signature functions and Mythic/Moonfall precedence; surface availability depends on material (not independent); regional imprint is stamped at origin. Color, motion, motif, shape/grip and ornament have no audited weighted rarity mapping yet. No RNG, loot odds, stat or rendering changes.
- New equipment finds capture original code and UID once through generate_find; optional birth_roll_code_v1 / birth_roll_uid_v1 fields persist via existing item serializer (including ground loot and vault). Legacy birth remains unknown, current look computed read-only. Original code is not a verified ownership or natural-drop certificate; scripted finds also receive an original appearance record. Debug overrides never enter either code. Current changes with cosmetic rerolls/saved looks and preserves birth. Inspect has Copy roll, compact playtest hover displays both, ALT has per-ranked-position breakdown. No joint probability or global scarcity claims.
- New regression exhausts the existing 10000 tier tickets and surface gate combinations, tests leading zeros, debug isolation, legacy absence, save/restore, collector flags and vault/exhibition transfer. Registered in CI; real F5 and additional item lifecycle checks remain required. Back up user data before upgrading; downgrading/resaving with older code drops the new birth metadata.

### 4.4 Deep equipment variation, without visual sloppiness

- [ ] Expand original authored weapon families (swords, daggers, spears, scythes, halberds, bows, wands, dual weapons), keeping authentic shapes and combat timing.
- [ ] Compose layers for blade/body, guard, grip, accents, trinkets, ribbons, wing accessories, glow, particles, and material patterns so independent seed channels can vary.
- [ ] M1 head-slot collector expansion: add Glowing Eyes as the first small authored accessory family, followed by optional crescent halos, floral crowns, veils and delicate spectral ornaments. The current headpiece slot uses the legacy `wings` equipment key; reuse that key for mutually exclusive head accessories rather than silently migrating existing equipment.
- [ ] Eye effects must use separate frame-specific, direction-aware eye anchors/masks (including concealed eyes and back-facing poses). Preserve Ghost Girl's approved facial features and original body pixels; no hue-based body recoloring. Roll independent continuous palettes, glow intensity, asymmetry, pulse speed and restrained motifs using versioned appearance channels. Natural rarity and stats remain independent; no new odds until audited. Use the dagger FX readability as the art reference, and the live equipment preview and adjustable FX control as the testing interface.
- [ ] Verify eye/head accessories in idle, walk, attack, dodge, jump and all four preview directions; verify item identity, lock/favorite, equip/unequip, vault and save/reload. Prototype after the M0 collection-safety gates and item identity baseline, not instead of them.
- [ ] Keep a seed-stable map from stored appearance data to *all* idle, walk, attack, dodge, jump, and inspect poses, including left/right orientation.
- [ ] Use tapered blade-following sword glows and softer visual effects rather than square beam artifacts.
- [ ] Cap layered effect counts for readability and older PCs; use LOD/quality controls without changing the underlying collector identity.
- [ ] Explicitly avoid cosmetic multi-projectiles increasing damage or hit count.

### M1 acceptance tests

- Same persisted item produces identical visual/stat identity on reload and fresh install.
- A cosmetic reroll leaves combat properties unchanged; a stat reroll (if ever added) has clearly separate rules.
- A debug override never survives as a genuine discovery, saveable rarity, or tradable provenance.
- Hundreds or thousands of deterministic seeds cover independent visual channels without unintended collisions or incorrect orientation.
- No rarity or scarcity messaging relies on estimated global counts.

---

## 5. M2 — Showing off: the collection is the game (P1)

### 5.1 Inspect every treasure beautifully

- [ ] Extend the existing collector lens/Inspect experience with a large readable item render, slow optional rotation or pose cycling, and a clean background.
- [ ] Present base item, quality, rare signature, material, origin, item level, socket/status information, and visual swatches in a clear hierarchy.
- [ ] Use a compact default hover; move generation seed, provenance, detailed stat breakdown, and historic visual presets to expanded inspection.
- [ ] Make inspect views faithful: item preview must use the actual saved item, not a freshly rerolled approximation.
- [ ] Add side-by-side item comparison for collectors (visual differences and rarity descriptors), not only combat DPS.
- [ ] Provide a screenshot/share-card composition that can work locally without requiring an account or service.

### 5.2 A collector-grade vault

- [ ] Build on the existing Collection Vault with reliable deposits, withdrawals, favorites, locks, searches, and exhibition assignment.
- [ ] Move normal deposit/withdraw access to a physical stash chest in the starting town. Reuse the existing Collection Vault UI, inventory.vault, unresolved records and serialization; do not create a second store or duplicate items. Preserve current vault contents, locks, favorites, display assignment, exact seeds and stats. Once town access is reliable, remove normal remote stash access, retaining read-only inspection if useful; close the chest UI on exit/range/room change. Keep recoverable fallback for old saves and test capacity, protected records, failed writes, and repeated interaction. Current storage limits/family eligibility remain until separately validated expansion; exhibition remains a display reference, never another owned copy.
- [ ] Add filters for item family, quality, intrinsic visual rarity, color family, material, region, acquisition source, and favorite status as the underlying metadata supports them.
- [ ] Add sorting by acquisition time, rarity, item family, appearance, stat desirability, and user-defined collections (avoid invented sortable metadata).
- [ ] Support a protected “never accidentally sell/destroy/trade” flag and double confirmation for irreversible collector actions.
- [ ] Keep inaccessible/unknown saved items as recoverable placeholders; never discard one because a definition or resource is temporarily missing.
- [ ] Add duplicate/related-item grouping *without* merging distinct instances or their seeds.
- [ ] Consider a collection journal for discovered appearances and silhouettes, distinct from ownership and tradeable inventory.
- [ ] Never let gallery previews or exhibition displays transfer or mutate the actual item behind the scenes.

### 5.3 Sanctum exhibition and personal showroom

- [ ] Polish the existing Sanctum display slots with dedicated lights, pedestal materials, subtle aura presentation, and stable item captions.
- [ ] Add curated museum shelves, walls, themed display sets, and featured “prized possession” locations.
- [ ] Let the player choose which items are **shown**, **kept private**, **favorite**, or **for trade**, independently.
- [ ] Make display interactions readable: inspect, zoom, view appearance, learn source/provenance, and return to collection.
- [ ] Design an attractive shareable collection page / profile preview for eventual multiplayer identity.
- [ ] Keep the showroom meaningful even when offline: it must work with local authentic saves and have no service dependency for basic displays.

### 5.4 Social recognition after identity infrastructure exists

- [ ] Plan optional public collector profiles, visited showrooms, featured items, themed galleries, and respectful reactions.
- [ ] Enable searching and browsing by item base, aesthetic category, material, signature, or discovery story when privacy settings permit.
- [ ] Show provenance and rarity claims only if verified; clearly label self-reported/offline collection snapshots.
- [ ] Offer privacy and safety controls for usernames, public inventories, trade requests, and communication.
- [ ] Avoid unmoderated chat or user-generated display text without reporting, blocking, and abuse-handling designs.

### M2 acceptance tests

A cherished item can be picked up, saved, protected, moved to the vault, displayed, inspected, and reloaded **without any visual, stat, seed, quantity, or ownership change**. A showroom visitor cannot modify or take an item.

---

## 6. M3 — Approachable Diablo II-style loot hunting (P1–P2)

### 6.1 Ordinary combat should be light and satisfying

**Next feedback pass (source implemented on feature branch; not yet playtested):**
- [ ] Verify layered original audio transients for melee swing versus confirmed contact, counter-riposte, precisely confirmed dodge evasion, spell casting and contact, warder guard breaks, and falling debris. Normal whiffs must not produce impact sounds.
- [ ] Tune transient loudness, event density, particles, and brief camera kicks in a real Godot playtest; avoid auditory fatigue in repeated farming. F8 cycles 100/50/0% shake and F9 cycles 100/50/0% new impact audio (session-only).
- [ ] Design a **real enemy parry/deflection mechanic** separately, with an explicit defensive window and outcome callback; a poise-break clang is not evidence of a successful parry.


- [ ] Make common enemies readable, beatable, and brisk to farm without demanding repeated precision dodges.
- [ ] Retain deliberate attacks, good hit feedback, short recoveries appropriate to each weapon, and meaningful risk; “light” does not mean empty or automatic combat.
- [ ] Make most collector routes approachable with ordinary gear and accessible movement/controls.
- [ ] Keep elite encounters and bosses as varied optional difficulty spikes, not universal gates to fundamental collecting.
- [ ] Balance resource/stamina demands so long farming sessions are pleasant rather than exhausting.
- [ ] Distinguish **farming difficulty** from **challenge difficulty** in encounter setup and reward messaging.

### 6.2 The collectible hunt loop

1. Pick a region, creature family, dungeon, or target collection.
2. Fight approachable mobs, open secrets, explore, or solve a short rose-hook interaction.
3. Receive a modest amount of loot; occasionally find an unusual stat roll, item base, or striking rare appearance.
4. Inspect and compare the item; favorite, store, exhibit, use, or eventually trade it.
5. Return for another run because there is more to discover—not because a daily timer forces it.

### 6.3 Item sources and sustainable rarity

- [ ] Define a transparent source matrix by region, encounter, boss, chest, puzzle, hidden room, and challenge activity.
- [ ] Keep ordinary drops moderate and genuine ultra-rare combinations **very** scarce; avoid flooding inventories with random clutter.
- [ ] Give each region recognizable visuals and a small number of meaningful source-specific treasures.
- [ ] Keep item bases and appearance modifiers in stable, auditable drop tables, with documented change history.
- [ ] Avoid powerful mandatory items available only from top-ranked competitive modes.
- [ ] Treat time-limited exclusives cautiously: protect long-term collectability and avoid manipulative fear of missing out.
- [ ] Add pleasant target-farming opportunities while retaining the wonder of surprising off-target finds.
- [ ] Design sink/crafting/reroll systems carefully: no silent deletion of rare original properties, no conversion of debug rolls into prestige finds.

### 6.4 Exploration and rose-hook interaction

- [ ] Starting town hub: replace the starting area's role with a safe, genuinely walkable gothic town approximately the usable scale/feel of Diablo II Act I's Rogue Encampment (reference for scale, not copied geometry/art). Original authored streets, landmarks, town square, stash chest near arrival/waypoint, clear wilderness exits, access to the existing Sanctum, and reserved spaces for NPCs, merchants and workshops. No functional NPC systems required for the initial town slice. No combat pressure in the town.
- [ ] Town migration: new games begin in town; existing saves retain their inventory, discovered areas, quest flags and safe return route. Do not strand old characters or relocate items by copying. First deliver minimal functional town/stash/waypoint connectivity after collection-safety gates, then polish original artwork and expand via M3; broader NPC content remains later.


- [ ] Add the early-room support-beam puzzle: hook the beam, collapse debris, open a persistent hole in the floor, and make the route physically traversable.
- [ ] Expand anchors, objects, switches, movable obstacles, traversal gaps, enemy staggers, and hidden paths as **loot-finding opportunities**.
- [ ] Persist puzzle consequences so a collectible discovery can be associated with an actual changed world state.
- [ ] Build genuinely larger walkable rooms with **new, room-specific painted backgrounds**; never market recolors/mirrors as original new locations.
- [ ] Use subtle exploration guidance and low-clutter UI; rely on atmosphere and landmarks rather than constant quest spam.
- [ ] Keep puzzle completion and ordinary loot routes possible without competitive-rank timing.

### M3 acceptance tests

A new collector can finish several rewarding loops without advanced dodge mastery; experienced players still appreciate intentional attacks; drop rates match audited tables; exploration secrets remain saved.

---

## 7. M4 — Trading and community: secure by design (P2)

> **Architecture warning:** Local deterministic generation is excellent for single-player collecting but insufficient to validate unique items in a public trading economy. Build a **server-authoritative, opt-in verified-item service** before allowing meaningful cross-player item transfer. Offline play should remain enjoyable and clearly differentiated.

### 7.1 Decide the economy contract before writing networking code

- [ ] Decide between offline-only sharing, invite-based exchange, asynchronous trade, or full online trading; make a deliberate staged choice rather than pretending all are ready.
- [ ] Define what can be traded: equipment, cosmetics, crafting materials, trophies, and/or original rare imprints; document bound, protected, and untradeable categories.
- [ ] Decide whether trading uses direct item-for-item exchange, currency, listings, or a combination. **Avoid introducing real-money trading by default.**
- [ ] Define account ownership, account recovery, lost access, age/privacy implications, abuse reporting, and moderation before public launch.
- [ ] Decide how legacy offline items enter the verified economy: conservative migration, audited one-time import, or non-tradeable “legacy/offline” status. Never silently claim edited offline saves are verified.
- [ ] Decide which parts of item history are private versus visible to trade partners/showroom visitors.

### 7.2 Authoritative identity and provenance

- [ ] Give each **verified minted instance** a collision-resistant unique server record separate from its reproducible cosmetic seed.
- [ ] Store the immutable creation event, item definition/version, born stat roll, born visual imprint, original location/source, and authoritative current owner.
- [ ] Keep appearance customizations and legitimate upgrades as separately versioned events without rewriting birth traits.
- [ ] Provide server-verifiable provenance including creation, transfers, and alterations. Do not expose private account data in public item cards.
- [ ] Use atomic ownership transfers with transaction IDs, idempotency, and rollback/reconciliation on network failures.
- [ ] Prevent dupes, stale-save replay, client-forged affixes, double spending, dropped acknowledgments, and concurrent transfers.
- [ ] Include audit logs and suspicious-activity review without exposing security internals to clients.
- [ ] Ensure inventory, vault, exhibition, trade escrow, and ownership cannot simultaneously claim the same verified item as independently owned.

### 7.3 A safe, human-friendly trade flow

- [ ] Create a “For trade” item state that is separate from favorite/protected and separate from public display.
- [ ] Support a trade request, offer construction, visual preview, stat/seed/provenance inspection, and **both-party confirmation**.
- [ ] Re-confirm if either side edits the offer. Lock offered instances while a trade is committing.
- [ ] Cancel cleanly on disconnect, timeout, rejection, insufficient capacity, or invalid item state; neither party loses anything.
- [ ] Display exact item identity before acceptance; never substitute a similarly named item or appearance snapshot.
- [ ] Provide a receipt/history screen for completed transactions, disputes, and support.
- [ ] Add blocking, reporting, rate limits, basic fraud/scam warnings, and understandable trade limits.

### 7.4 Incremental rollout

1. **Local mock trade simulation:** two inventories + fake server + failures; no public economy.
2. **Authenticated staging service:** ownership ledger and transaction tests; no real-value player inventory yet.
3. **Private controlled beta:** invited players, diagnostics, rollback/reconciliation, fraud monitoring.
4. **Public verified trading:** only after server integrity, moderation, and recovery work are proven.

### M4 acceptance tests

Repeated, concurrent, disconnected, or malicious trade attempts never create two owners of one verified item; no permanent loss occurs on failed transactions; legacy/offline claims are honestly labeled.

---

## 8. M5 — Bloodborne-style competitive combat and top lists (P2–P3, optional)

### 8.1 Keep mastery deep, participation optional

- [ ] Preserve weighted, deliberate weapon movesets, readable hitboxes, intentional stamina economy, dodge timing, stagger, guard/counter windows, and enemy tells.
- [ ] Refine hitstop, audiovisual clarity, and committed animations without compromising the main relaxed-farming loop.
- [ ] Trigger dodge-counter/riposte ring, chime, and hitstop **only on confirmed successful hits**.
- [ ] Support meaningful build choices and item variety in advanced content, while ensuring precision and skill still matter.
- [ ] Keep the base campaign, collection vault, showroom, and future trading usable without ever entering a ranked event.

### 8.2 Separate competition formats for fairness

- [ ] **Normalized challenge leaderboards:** controlled loadouts/stats for time trials, no-hit bosses, and precision/rose-hook challenges. This should be the default skill comparison.
- [ ] **Open-build leaderboards:** allow found equipment and creative builds, but display them separately because item luck affects results.
- [ ] **Personal-best challenges:** offline practice and self-improvement, clearly **unverified** until a trustworthy submission exists.
- [ ] Define run categories, input rules, permitted abilities, attempts, pause/quit behavior, seed/map version, and timing start/stop events.
- [ ] Separate lifetime records from any optional seasons; avoid wiping the identity of earned historical achievements.
- [ ] Do not put the best tradeable collector items exclusively behind the top percentile or compel casual collectors into ranked queues.

### 8.3 Legitimate rankings, not a simple local file

- [ ] Keep local timestamps and stats for practice, but do not call them public verified leaderboards.
- [ ] For public top lists, design authoritative challenge conditions, tamper resistance, event verification, replay or trace capture, anomaly review, and clear invalidation policy.
- [ ] Version the rules/maps/combat balance so leaderboard records remain comparable.
- [ ] Add player opt-in, privacy controls, readable personal stats, placement, and earned presentation rewards.
- [ ] Ensure competition does not require trading or owning rare items.

### 8.4 Competition-derived prestige without collector gatekeeping

- [ ] Reward transparent top-list achievements with titles, display frames, trophy plinths, banners, visual insignias, or showroom medals.
- [ ] Distinguish skill prestige from collector rarity and economic value in UI.
- [ ] Consider celebratory cosmetics that are **account-bound**, so top-list competitors gain recognition without monopolizing the core item economy.

### M5 acceptance tests

A collector can ignore ranked play entirely. Ranked runs can be compared fairly within their category; public submissions must be verified, not trusted from modified local data.

---

## 9. M6 — A living world and long-term collecting (P3)

- [ ] Expand regions with authored scenery, hidden paths, distinct lore motifs, collectible sources, and mechanically unique rose-hook interactions.
- [ ] Add memorable bosses and optional elites with truly readable patterns and limited fair access to exceptional rewards.
- [ ] Add rare aesthetic families tied to geography, enemy ecology, puzzle discoveries, and special encounters.
- [ ] Develop collection sets, curated exhibitions, player-origin stories, and personal “museum history” milestones.
- [ ] Consider collection catalogues or non-tradeable discovery stamps, with explicit distinction between **seen**, **owned**, **currently owned**, and **once traded**.
- [ ] Extend modular cosmetics with shades, layered materials, decorative accessories, trinkets, and wings without losing approved character identity.
- [ ] Build sustainable content updates that expand options without depreciating cherished existing seeds.
- [ ] Consider seasonal challenge leaderboards only after stable fair verification. Permanent collections should survive seasonal resets.

---

## 10. Architecture and non-negotiable item invariants

### 10.1 Item data layers

Treat these as distinct concerns (the schema below describes an intended design, **not an assertion that every field already exists**):

| Layer | Meaning | Can it change? |
| --- | --- | --- |
| **Base definition** | Weapon/item family, template identifier, rules/content version | Rarely, with migration |
| **Original loot roll** | Seed, drop quality, affixes, sockets, and intrinsic generated stats | Immutable for an established item unless a documented gameplay transformation exists |
| **Intrinsic visual imprint** | Found rare signature, born materials/shapes, source identity | Immutable for authenticity/provenance |
| **Chosen appearance** | Favorite cosmetic seed, palette, cosmetic preset, displays | Explicitly customizable, independent of stats |
| **Instance identity** | Unique persistent owned-item identifier; future verified server mint | Stable, never recycled |
| **Collection metadata** | Favorite, protected, vault position, exhibition slot, notes | Mutable with item ownership |
| **Trade/provenance** | Verified owner, transfer history, server attestation | Append-only authoritative events (future online) |
| **Competition record** | Run score, ruleset, verification state | Separate from the item and from collector rarity |

Do **not** equate a deterministic seed with an irreplaceable unique instance. Two items can share a reproducible appearance while still being distinct possessions; a “globally unique” claim must come from a verified registry, not from seed length.

### 10.2 Safety invariants every implementation must test

- [ ] Existing item seeds, UID, affixes, sockets, materials, selected appearance, favorites, locks, and exhibition assignments remain stable across save/reload unless the specific feature explicitly changes them.
- [ ] Inspecting, comparing, filtering, previewing, sharing, or exhibiting an item never mutates it.
- [ ] Cosmetic rerolls and aura/projectile variations never change damage, hitboxes, hit counts, or economic provenance.
- [ ] Destructive actions on protected items are rejected or require explicit unlocking; no silent fallback deletes unknown items.
- [ ] Unknown legacy item types are preserved recoverably until a defined migration exists.
- [ ] Old saves are backed up before patching; downgrade safety is documented when new metadata is added.
- [ ] Future verified ownership moves atomically and cannot duplicate; client visual data cannot authorize minting or transfer.
- [ ] Ranked results are not derived solely from modifiable player files.

### 10.3 Suggested boundaries for new systems

- **Core item model / seed engine:** drop stats and RNG independent from cosmetic generation.
- **Visual composition:** deterministic render from saved fields, independent from gameplay effects.
- **Collection repository:** local inventory/vault/gallery state, defensive serialization and migration.
- **Showcase UI:** read-only view-models for inspection, comparison, exhibitions, and profile cards.
- **World/loot sources:** encounter and location rewards feeding through the canonical item generator.
- **Future online economy:** service-owned inventory ledger and trade state machine; *never* a trust-the-client save sync.
- **Future ranking service:** challenge ruleset, event validation, scoring, and public leaderboards separate from general combat code.

Choose incremental wrappers around working code before introducing sweeping replacements.

---

## 11. UX, art direction, accessibility, and performance

### UX principles

- [ ] Prioritize a **beautiful item thumbnail and inspect action** over a wall of item numbers.
- [ ] Clearly distinguish **quality**, **natural rarity**, **cosmetic customization**, **equipped**, **vaulted**, **displayed**, **protected**, and **trade-listed** states.
- [ ] Use readable tier colors alongside text/icons: do not rely on color alone.
- [ ] Provide clear empty states, keyboard/gamepad navigation, controller focus handling, and reversible UI actions.
- [ ] Keep collector flows short: pickup → inspect → favorite/store/display, with minimal repeated modal friction.
- [ ] Place technical seeds and detailed metadata behind Advanced rather than on every tooltip.
- [ ] Avoid monetized pressure, forced daily routines, or UI that demands constant ranked participation.

### v1.95: stable weapon idle presentation (source implementation, playtest pending)

- [ ] Verify 8-step, 3.45-second idle transitions for normal swords, Moonwarden spear, Briarwake trident, Thornrose bow and Moonveil bow, all four facing directions. The new frames are **subtle in-betweens derived from existing approved artwork**, not eight newly hand-painted independent poses.
- [ ] Verify the bow palette mask, mirrored left-hand bow layer, and bow/spear glow axes remain stable while idle. Attack, walking, dodge and cast sprite frames must remain unchanged.
- [ ] On a lower-end GPU, check first-load frame generation time and memory. Adjust transition strength if the weapon looks ghosted rather than still.
- [ ] Longer-term animation-art pass: commission/author eight genuinely distinct approved body-breathing frames while keeping the weapon grip and silhouette fixed; replace interpolated idle only after visual review.

### v1.96: compact visual tooltip and sword-idle readability (source implementation; Godot F5 pending)

- [ ] Test 16 subtle silhouette-locked sword idle frames in all four directions; bow and spear idles retain their eight-step treatment. Confirm that genuine painted weapon contours remain steady and no odd palette ghosting appears when holding a prized item.
- [ ] Check that the normal item tooltip stays compact even when Alt pins it: stats, sockets, larger labelled dot controls, and separately colored flavour prose. Technical roll code/history and lengthy appearance sections remain in P/Inspect.
- [ ] Hold Alt, then hover each visual color dot; verify correct panel-level contextual help for surface tint, bowstring light and FX glow on current and compared items. Dots are shader/FX samples, **not an exact prediction of final weapon pixels**.
- [ ] Cross-check the Moonveil/Thornrose bow limb tint dots against the actual `weapon_surface_v190.gd` shader input after mixing its material ramp, including different effects intensity/debug appearance. Do not imply that the full bow inherits the glow color.
- [ ] Run v1.95 and v1.96 Godot smoke regressions, open equipped preview, and manually check mouse interaction and resource/memory costs on older hardware. Neither the item RNG/save schema nor combat damage may change.

### v1.97: steady daggers, readable Reaper light, dark-gradient generation (source implemented; playtest pending)

- [ ] Verify Roseglass Dagger and Nocturne Stiletto idle presentation across all four directions: 16 gentle interpolated frames over a 3.45-second cycle, fixed approved weapon silhouette and hand anchor, while walking/attacking/dodging remain unchanged. Review startup-time texture cost and visible appearance in equipment preview.
- [ ] Verify Rose Reaper and Veilkeeper's Reaper scythe blade-edge illumination in dark rooms and with black/charcoal appearance rolls. Keep the narrow crescent rim visible without washing out the original metal/shaft. Session FX intensity (including 0%) must still apply. Confirm no combat or item rarity changes.
- [ ] The new **opt-in gradient version 2** adds seeded onyx, true black, charcoal, shadow-to-jewel and slate ramps; legacy items, prior favorite appearances, and missing-version old saves continue using unchanged version 1 colors. Only new drops and deliberate cosmetic rerolls move to V2. Current-look version is serialized and captured in favorite snapshots. Collector material/signature rarity odds and ten-digit Roll Codes are unchanged.
- [ ] Run v1.95/v1.96/v1.97 regressions, reload older saves and saved favorite looks, test surface/FX color swatches, inventory → vault → exhibition continuity, four-facing weapon FX, and performance on older hardware.
- [ ] Back up existing saves before upgrading. Downgrading and saving through an older build that doesn't recognize `gradient_version` may reset V2 looks to V1; do not overwrite a cherished V2 look via downgrade.
- [ ] In future authored-art work, prefer dedicated body-breathing frames over crossfading painted pixels when a weapon needs more visible motion.

### v1.98: weapon proportion, carried bows and meaningful missed attacks (source implemented; Godot visual review pending)

- [ ] Verify Reaper scythe's roughly 13% longer **art-only** span, Briarwake Trident's longer back-shaft, and the slightly extended single/stiletto/dual dagger blades in all four directions, with short guide-anchored overlay tips for dagger/stiletto idle and walking instead of stretching the source atlas. A weapon's displayed length must **not** change the reach/hitbox, loot rolls, rarity or existing saved cosmetics.
- [ ] Bow reference pose: while idle, Thornrose and Moonveil are carried roughly cross-body/horizontal like the uploaded reference. Swap baked bow idle bodies for the original clean approved Ghost Girl body; rotate and align the same extracted physical bow and pigment mask around the actual hand for front/back/left/right. The back-facing hand is partly occluded and uses an approximated anchor; require a real F5 screenshot check before final approval. Shooting/walking/attack frames stay unaltered.
- [ ] Review new original **airy sword whooshes** instead of an impact-like swing beep. Heavy, fully charged bow releases, heavy wand casts and aerial strikes play their own longer sweeps and a restrained visual air wake even on a complete miss; impact sounds/riposte hitstop remain reserved for confirmed contact.
- [ ] Check keyboard/gamepad combat animations, charged bow release and jump landing independently. No fake hit markers, no extra damage/projectiles; camera-only movement on misses must be gentle, and the existing F8 shake and F9 new-impact-sound levels must work.
- [ ] Godot headless CI: run v1.94/v1.95/v1.96/v1.97 and the new v1.98 weapon/sound/hand-alignment smoke suite, plus clean resource import. The new bow pose needs a **manual F5 front/back/left/right preview**, particularly wrist alignment and the bow appearing once.
- [ ] Tune procedural sound loudness and art proportion with actual gameplay; leave PR unmerged if the bow is misaligned or heavy/charged/airborne cues feel too strong.

### Art and audio principles

- [ ] Preserve the approved Ghost Girl silhouette, facial appearance, and dark painterly 2D aesthetic.
- [ ] Distinct original painted locations; no mirrored/recolored existing background marketed as a new area.
- [ ] Treasure FX should be luminous but restrained; rarity is stronger when common gear remains visually quiet.
- [ ] Frame-align original direction-specific animations, dedicated weapon layers, and hook transitions.
- [ ] Let memorable drop sounds, subtle particles, and a brief reveal communicate a rare discovery without blocking gameplay.

### Performance targets

- [ ] Profile on constrained graphics hardware and large collections; prioritize a responsive inventory and vault over excessive shader complexity.
- [ ] Cache item preview compositions and icons sensibly; invalidate on genuine appearance changes, not every frame.
- [ ] Limit particles, offscreen effects, and inspection redraw costs, without affecting seeded identity.
- [ ] Make optional FX detail scalable: lower graphics settings must not make a rare item misidentified or change ownership/state.

---

## 12. Test strategy and release gates

### Local and CI test matrix

| Area | Required proof |
| --- | --- |
| Boot/import | Fresh checkout opens in target Godot version; no blocking parser/resource errors |
| Inventory compatibility | Current and legacy `TestMythic` scene variants; no typed-node crash |
| RNG determinism | Same inputs reproduce item; stats and visuals use isolated streams |
| Scarcity | Simulate sufficiently large seeded samples; verify bounds and probability tables |
| Cosmetics | Favorite/save/restore/reroll unchanged combat stats; original signature remains distinguishable |
| Inventory/vault | Full pages, no-room, protection, destroy cancel, sorting, save/load and migration |
| Exhibition | Read-only model, faithful render, no accidental item mutation |
| Combat | Movement, directions, attacks, stamina, counters, weapon-specific alignment |
| Loot source | Region drops and hidden source rules match the documented table |
| Puzzles | Rose-hook environment state and collision persist |
| Trading (when built) | Atomic transfers, concurrent offers, retries, disconnect, replay/dupe attacks |
| Ranking (when built) | Rule version, verification, fairness categories, invalid submissions |
| Performance | Old GPU / large item counts / heavy VFX / slow disk save-load |

### Validation honesty

Distinguish explicitly between:

1. **Source/static validation** — files, references, JSON and deterministic checks.
2. **Godot headless validation** — scripts/scene imports/automated smoke tests.
3. **Real interactive playtest** — F5 startup, feel, visual alignment, UI, gamepad, combat, inventories, and save recovery.
4. **Online staging tests** — relevant only once networking/trading/ranking actually exists.

A green CI run must not be described as a complete hands-on visual playtest. Never invent pass results or version parity.

### Patch and release routine

- [ ] Work from the most recent confirmed mainline files; inspect diffs before editing.
- [ ] Make small focused, save-compatible patches unless a coordinated migration is justified.
- [ ] Add tests for changed behavior, especially item invariants and older save samples.
- [ ] Keep release notes: scope, exact changed files, backups, upgrade path, downgrade warning, known limitations, validation actually run.
- [ ] Do not ship a new social/trading label until actual authoritative service and abuse safeguards are implemented.
- [ ] Keep `ROADMAP.md` and `AGENTS.md` synchronized when product priorities change.

---

## 13. Decisions to resolve before the relevant milestone

These are open questions, not assumptions. Record answers in the roadmap before implementing irreversible systems.

1. **Offline/online boundary:** Will collectors continue to own fully local items while only newly minted online items become tradeable, or is there an audited legacy-import program?
2. **Scarcity definition:** Which signatures are intrinsically born and globally verifiable versus merely appearance presets that can be recreated by seed?
3. **Trading format:** Item-for-item first, account-bound items, currency, listing house, or a smaller secure exchange model?
4. **Social identity:** Public username, opt-in collection visibility, showroom access, friend system, and content moderation scope?
5. **Competitive events:** Which challenges should be normalized-loadout, open-build, solo, or seasonal?
6. **Economy safeguards:** What permanent protections and recovery windows exist for accidental exchanges or compromised accounts?
7. **Item-lore disclosure:** Exactly which item seeds and origin history should be exposed publicly while preserving privacy?
8. **Presentation:** What should be visible on a default tooltip versus the full collector lens?

Until decided, favor local, reversible, source-compatible features.

---

## 14. Success metrics worth measuring (not promises)

Do not invent public usage figures or publish unverifiable player metrics. Once there is real playtesting/telemetry with consent, measure:

- **Collector delight:** percentage of discovered items inspected, favorited, vaulted, or displayed; qualitative feedback about memorable finds.
- **Collection safety:** zero known lost/duplicated items during migrations and transfers; recovery time for failures.
- **Healthy rarity:** audited drop distributions, genuine signature frequencies, and meaningful variety across collected items.
- **Showcase activity:** number of players who build or share exhibits, and whether displayed items render accurately.
- **Accessible hunting:** typical time to complete a rewarding farm run; whether casual players can progress without ranked-level skill.
- **Trade trust (future):** completed versus failed transfers, proven double-owner incidents (target zero), dispute rate, and clear ownership recovery.
- **Competitive credibility (future):** verified submissions, rejected fraudulent runs, understandable ranking rules, and continued opt-in participation.
- **Technical health:** Godot parse errors, crashes, regressions, corrupted saves, and old-hardware responsiveness.

Use metrics to improve joy and trust, not to manipulate rarity odds or trigger compulsive play.

---

## 15. Next-build task order — actionable sprint

**Integration gate (2026-11-25):** PR #37 reached `main`, while subsequent PRs #38 and #39 were merged into **stacked feature branches**, not `main`. A green nested PR is not a mainline release. PR #40 targets `main` to integrate v1.97–v1.98 together. Its headless CI must pass; after merge, verify the new scripts and tests are visible from `main` and run a mainline smoke workflow. Real F5 bow hand placement in four directions, audio feel, item migrations, vault, inventory, and old saves are still open. **Build blocker resolved:** PR #41 restored the missing `GOLD` constant on `main`, and Godot run 45514483189 passed. The earlier PR #40 failed CI against the pre-hotfix mainline due to that missing constant. PR #40 must be rechecked after that fix, not judged against its stale failure.


**Sprint A: stability before spectacle**

- [ ] Check current branch and reproduce/close the inventory Button → OptionButton issue with Godot.
- [ ] Re-run `v1921_dropdown_compat_smoke.gd` in current CI; the old duplicate inventory script is no longer tracked on `main`. Preserve active compatibility behavior.
- [ ] Run existing smoke tests, then F5 test the full item lifecycle, vault, exhibitions, and an older save.
- [x] Restore the v1.92.2 collection recovery regression to the active workflow. **Godot headless CI passed** in run 45511859931, including the legacy migration test. Real F5 transfer/save-load checks and private older-save compatibility remain outstanding; do not treat CI as that playtest.
- [ ] Document any remaining blockers and only declare completion with evidence.

**Sprint B: the collector's identity**

- [ ] Inventory audit: document current stat seed, cosmetic seed/UID, birth appearance, saved-look behavior, rarity rolls, and serialization rules.
- [ ] Build a small **item identity regression suite** for unchanged stats, look, seed, protection, and display through save/reload.
- [ ] Audit and prototype versioned Collector Roll Code with real trait rarity mapping and birth/current/test separation, including leading-zero and all-zero pattern tests.
- [ ] Improve the prized-item Inspect presentation, with numeric seed in Advanced only and uncluttered default tooltips.
- [ ] Confirm favorite/look save and reroll behavior; do not write a parallel implementation when an existing path works.
- [ ] Prototype at least one genuinely rare, understated, memorable visual combination using deterministic seeded art and tested rarity boundaries; Glowing Eyes is the requested first head-slot candidate after the M0 and identity gates.

**Sprint C: the collection showcase loop**

- [ ] Polish Collection Vault filtering, protection and persistence; do not corrupt items on failed transfers.
- [ ] Deliver the first safe starting-town/stash chest slice with the existing vault backend and reliable return path before retiring remote stash access.
- [ ] Enhance Sanctum exhibition and faithful item zoom/inspection.
- [ ] Add local share-card/export for prized finds without implying online provenance.
- [ ] Playtest the loop: farm → discover → inspect → favorite → vault → exhibit → reopen game.

**Sprint D: the light hunt**

- [ ] Polish the original town's walkable scale, landmark layout and routes into the wilderness; leave NPC spaces reserved for later.
- [ ] Tune accessible enemy density, drop pacing, and one rewarding collector route.
- [ ] Add the support-beam hook puzzle and a genuinely original walkable connected room.
- [ ] Confirm puzzles, loot, and item identity survive reload.

**After those gates:** decide the verified-online architecture before trading; build the competitive leaderboard stack as an independent optional track.

---

## 16. Explicit non-goals for the next build

- No claim that a local save proves globally authentic ultra-rare ownership.
- No live person-to-person trade powered only by editable `user://` data.
- No public top lists based solely on client-submitted numbers.
- No mandatory brutal combat or ranked progression to enjoy collecting.
- No visual rarity obtained merely by forcing a debug preview.
- No pay-to-win economy, real-money item marketplace, or manipulative rarity marketing.
- No replacement of Ghost Girl's approved design or original room art with reused mirrors/recolors.
- No broad rewrite, broken save compatibility, or “feature complete” announcement without real tests.

**North star check before every change:** *Does this make a cherished rare item more exciting to find, safer to own, easier to admire, or more meaningful to show and eventually trade—without making ordinary collecting frustrating?* If not, explain why it deserves priority now.
