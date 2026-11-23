# Ghost Girl v1.38 — Elemental Fletching

**Base:** v1.37 Bellroot Chorus. Install over the directory containing `project.godot`.

## Bow visual layers

Each *bow item*, independently of its combat statistics, now has five seeded visual characteristics:

- Element: Moonsteel, Emberfire, Frostglass, or Luminous
- Formation: one physical arrow, or a **Triune Echo** with two cosmetic copies
- Glow color (10 colors)
- Trail pattern (6 patterns)
- Etching ornament (5 patterns)

Normal bows remain understated, magic bows have restricted element rolls, and rare/set/unique bows can obtain the full collection. The additional two visible Triune arrows are **not extra damaging projectiles**. Charged bows still pierce at most two distinct enemies. Ice arrows apply a short slow to enemies already supporting frost; other elements do not add damage.

Legacy saves acquire seeded defaults, then store the new five fields when next saved. No existing weapon stat, affix, or damage-seed calculations are changed. The cosmetic Relic Attunement altar rerolls these new layers on equipped rare-or-better bows.

## Bow animation cleanup

Two 2048×1760 combat atlases replace only the combat rows for Thornrose and Moonveil. All sixteen four-direction light/heavy attack tracks preserve their 8-frame order. They now contain frame-matched nock/draw/release glints and bowstrings. The old melee-purple-sword crescent in the release pose has been removed by reworking that frame from the adjacent approved bow pose. Idle/walk art and original source frames remain unchanged.

This is still a first-pass compositing pass, not newly hand-drawn full character animations.

## New moor puzzles

1. **The Fletcher's Embers**: use a Fire bow and an Ice bow to activate two runes; reward: unique Emberfrost Stave.
2. **The Sunlace Vault**: use a Light arrow and a **charged Triune Echo** arrow to activate two runes; reward: unique Sunlace Longbow.

The existing arrow's wall-clipped swept segment detects targets; it won't trigger sigils through solid cover. Both puzzles save independent flags via the existing collected-pickup system.

## Test bows

Four new one-time weapon pedestals in Moonwake Crypt provide guaranteed Fire, Ice, Light, and Triune seed combinations. Claim with **E**, equip with **I**, and use normal or charged attacks to try the new effects.

## Validation limit

Static source, resource, sprite-atlas and patch checks are automated, but Godot is not installed in this environment. Please run **F5** and check arrow interactions and animation timing in the real engine before treating this as a stable release.
