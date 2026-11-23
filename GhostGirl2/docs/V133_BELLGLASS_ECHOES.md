# Ghost Girl v1.33 — Bellglass Echoes

## Install

Extract the v1.33 ZIP into the folder containing `project.godot` **after v1.32**. Let it replace matching `.gd` and `.tscn` files. This incremental patch intentionally contains no original sprite atlases, room paintings, or save files.

## New post-Warden quest

After defeating the Moor Warden, find three Bellglass Echoes across Hollow Veil Moor:

1. **Western Thread** (western moor, approximately 2650,4050): aim and latch the rose-hook with **F**.
2. **Drowned Frost** (eastern fen, approximately 7070,4550): cast the learned Moonfall Blizzard with a wand using **Z**.
3. **Skyward Note** (below the northeastern ruins, approximately 8620,2770): land a **charged bow arrow fired while airborne** (`C`, then right click).

Each echo stores its own persistent discovery flag in `Inventory.collected_pickups`. Three nearby waystones offer hints. A fourth waystone points to the Bellglass Vault southeast of the Moor Warden arena. The vault remains locked until the Warden has fallen **and all three echoes** are awakened. The chest gives one unique `Bellglass Reliquary` charm (+15–22% stamina recovery as its base stat). Existing slots, saves, and item affixes are unchanged.

## Other improvements

- The Warden now despawns its two **summoned** Hush Moths on defeat; normal moor monsters are unaffected.
- The upper-left minimal quest label transitions from Four Laments to Bellglass Echoes when the Warden is defeated.
- New props are editor-placeable scene nodes. No duplicated background texture or gameplay physics changes.

## Validation limitations

`tests/validate_v133.py` checks the new scene structure, file references, group dispatch wiring, boss cleanup, reward conditions and preservation of existing artwork. `validate_v132.py` also passes. `validate_v131.py` uses an older hard-coded scene resource count and fails after new resources were added; it is not a Godot engine check. Real F5 gameplay validation in Godot 4.7 is still required.
