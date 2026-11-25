# Ghost Girl — Master Development Roadmap

> **Product north star:** Ghost Girl is **first and foremost a rare seeded-item collecting, trading, and showcasing game**. Players should dream about finding an extraordinarily rare, visually recognizable item; enjoy owning it; proudly display it; and eventually trade with other players. Think of the enduring item hunt and social prestige of *Diablo II*, with **light, accessible everyday combat**. The deliberate, high-skill feel of *Bloodborne* is important **for an optional competitive challenge and leaderboard track**, not a difficulty barrier between casual collectors and their loot.
>
> **This is the canonical product-priority document for the repository.** See [AGENTS.md](AGENTS.md) for instructions to coding agents.

_Last updated: 2026-11-24 · Godot 4 · living design and delivery plan, not a claim of completion or a release-date promise._

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
- The duplicate `GhostGirl2/scripts - Copy/inventory_panel.gd` currently contains unresolved merge-conflict markers; do not copy it over the active script.
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
- [ ] Remove or clean unresolved Git merge markers in the duplicate `scripts - Copy/inventory_panel.gd`; do not substitute this duplicate for the live `scripts/inventory_panel.gd`.
- [ ] Scan tracked GDScript and scenes for unresolved merge markers, missing resources, bad node paths, stale `@onready` assignments, and startup failures.
- [ ] Validate fresh-checkout Godot import, script parsing, scene loading, and the CI smoke workflow.
- [ ] Manually F5-test: new game, old save, inventory, inspect, tooltip, sort, drag-and-drop, socket, equip/unequip, destroy confirmation, vault store/withdraw, favorite/protect, exhibition, save/reload, and exit.
- [ ] Explicitly test backpack grid migration, page count, capacity, full storage, locked items, and failure recovery without item loss.
- [ ] Test appearance reproducibility across save/reload and across different graphics settings.
- [ ] Establish a versioned backup and migration test corpus for older `user://` saves; do not publish or overwrite private player saves.
- [ ] Check item invariants on every transfer between backpack, equipment, vault, display, and future trade staging.
- [ ] Maintain a simple defect table: repro steps, affected scene/script, Godot build, severity, validation result, and patch version.
- [ ] Keep performance and memory affordable on older GPUs; validate the 2D project on lower-spec hardware if accessible.

### v2.01 — exploration landmarks and creative cave solutions (source implementation; engine and visual review pending)

- [ ] **Bow idle corrective check:** replace the ambiguous runtime 180° arithmetic with explicit **per-facing upright bow angles** for Thornrose and Moonveil. Physical bow, limb-mask shader and child FX must share a single source transformation around the actual wrist. Check front/back/left/right in F5 and both 100%/200% equipment preview; algebraic angle tests do not validate how an actual painted limb appears.
- [ ] **Handheld Pokémon-style exploration principle, not a visual clone:** reward curiosity when traveling between vivid, legible landmarks. Let an apparently impassable object suggest multiple mechanics. Keep the game's own gothic, painterly Ghost Girl identity; use context-sensitive clues, compact controls and original art instead of adopting copyrighted sprite assets or a Game Boy UI imitation.
- [ ] **Moonthorn Woods — Moonlit Hollow boulder:** scene-owned entrance artwork and real static collision physically obstruct an optional cave trail to existing Briar Hollow and its fixed-seed one-time cache. The normal forest-to-Briar-Hollow route stays available. This is an original procedural **entrance art prototype**, not a claim of a finished hand-painted new cave room.
- [ ] The boulder accepts **seven evidence-backed creative outcomes**: frost then a blow, frost then hook, patient repeated hook pulls, accumulated ordinary weapon force, grasping-rose magic, a charged midair bow shot, or frost followed by fire (thermal shock). Inputs reuse existing Moonfall, elemental arrow, rose-hook, bow and projectile systems; no special single-key unlock or mandatory advanced skill route.
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
- [ ] Run `v1921_dropdown_compat_smoke.gd`; inspect and clean the duplicate conflict-marked inventory script.
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
