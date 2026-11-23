# Ghost Girl v1.30 — Veilbound Reliquaries

**Patch base:** v1.29 Hush Moths & Gloom Lanterns. This is an incremental Godot 4 patch.

## Implemented

- Hush Moth: new 4-frame 1024×256 transparent illustrated sprite atlas, animated in the existing enemy draw function.
- Gloom Lantern: matching 4-frame animated, translucent spirit-and-iron-lantern atlas.
- Both continue using their existing collision shapes, frost slow, hook stagger, weak health, attack windups, and original loot odds. No additional damage events were introduced.
- Two optional Triune Reliquaries in Hollow Veil Moor, each requiring three intentional interactions in order:
  1. Aim and cast the **rose-hook (F)** at the reliquary.
  2. Cast **Grasping Roses (T)** on the open flower.
  3. Cast **Moonfall (Z)** on the awakened bloom.
- Every stage saves using the existing `collected_pickups` collection. The gate only opens after the final frost activation. Opening the chest remains a separate one-time saved reward.
- New editable waystones direct players to these hidden mechanisms. The main path between moor exits remains clear.

## Where to test

- Western reliquary: near `(4100, 2200)`, with a hint waystone around `(3890, 2420)`. Reward: a rare Thornrose Bow.
- Eastern reliquary: near `(8700, 4550)`, with a hint waystone around `(8540, 4750)`. Reward: a rare Briar Wand.
- The reliquaries are children of `Gameplay/HookAnchors`, so the existing room binding loop restores their saved state.
- The enemy sprites are independent assets in `assets/enemies/`. Rebuild source: `tools/build_moor_creature_art_v130.py`.

## Installation

Merge this patch into the folder containing `project.godot`, overwriting matching files. Do not copy it to a subfolder. Back up your existing save/project before testing.

## Validation

Static validation v1.24–v1.30 passes (resource references, save IDs, scene paths, image transparency and frame non-emptiness, spell and weapon balance checks). **Godot runtime was unavailable in this environment**. Inspect the level in Godot and run F5 to verify actual animation timing and puzzle interactions before treating it as stable.
