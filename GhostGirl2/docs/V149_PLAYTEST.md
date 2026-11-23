# v1.49 — Weight & Aftermath (playtest checklist)

This patch builds on v1.48 without changing stats, scene layouts, saves, or the
approved Ghost Girl character art.

## Movement feel

- Walk from standstill, release directions, then reverse direction quickly.
  Does the start/stop/turn feel snappy without sliding?
- Sprint for ~10 s; subtle dust should appear near the shoes without obscuring
  the character or filling the room with smoky clouds.
- Jump while moving and land; verify a very brief sprite compression and ground
  dust pulse. Jump over the existing low thorn barrier: collision must still work.
- Try a jump attack on an enemy and then a missed jump attack. Confirm stronger
  hit pause and camera push only **on contact**, and a lower-amplitude landing
  puff whether or not you hit.
- Dodge/backstep under pressure and check the short departure dust does not hide
  the enemy telegraph.

## Impacts

- Take one small hit and one heavy hit: recoil, brief dark-red dust and a
  directional camera push should feel readable, not disorienting.
- Strike both a weak enemy and an armored elite; see the muted contact debris.
  Existing damage and knockback/poise behavior should be unchanged.
- Hook-break a withered barricade: wooden splinters and drifting smoke.
- Pull a ceiling/support beam and watch the landing impact: a larger masonry
  dust cloud, fragments and localized camera rumble.
- Open a moonroot lattice: appropriately tinted broken timber/stone fragments.
- Throw a crate hard into a wall. Contact dust should not trigger each frame.

## Aftermath

- Kill a mourner/blade hunter/warder: a dark, irregular blood pool should remain
  on the painted floor and begin fading near the end of its ~75-second life.
- Kill an occultist: a dark-purple ichor pool instead of bright red blood.
- Kill a spectral moth: NO humanoid blood puddle.
- Fight a large crowd and verify there are at most 24 pools and 26 burst effects.
- Change rooms while some puddles are visible. Pools are cosmetic and should
  clear with the old room rather than persisting through game saves.

## Regression priorities

- v1.47 Echo Trials, rose-bell interrupts and personal records.
- v1.48 Rose Path timed bridge challenge and one-time rewards.
- v1.46.4 Crypt floor breach and Garden support puzzles.
- All directional weapon atlases, bow charge, jump shooting and hook traversal.
- Inventory hover/Ctrl comparison, compact cosmetic gradient swatches,
  saved looks, old saves and quest pickup flags.

These are manual checks to run in Godot; they have NOT been completed in-engine.
