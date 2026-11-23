# Ghost Girl v1.23 — Relic Showcase & Moonstep

Apply this quick patch **over v1.22** by extracting directly into the project
root (the folder with `project.godot`) and replacing matching files.

## New main-room testing gallery
Moonwake Crypt now has eleven collectible weapon pedestals covering every
existing blade, scythe, halberd and wand template. Face a pedestal and press E
to take its seeded item. Each pedestal is collectible once per save. The icon
remains visible after claiming it, without blocking movement. Some pedestals
hold set/unique demonstration variants so you can see the rare visual effects.

A new portal in the east of Moonwake Crypt takes you directly to **Hollow Veil
Moor**. A return portal in the moor brings you back to the crypt.

## New prestige aura visuals
Seven vivid original procedural effect families can surround the equipped
weapon: Crowned Moon, Rose Comet, Astral Filigree, Eclipse Wings, Frostfire Halo,
Thorn Constellation and Prismatic Afterglow.

- Normal and magic items do **not** produce a prestige aura.
- Rare items have a deterministic one-in-eleven cosmetic chance.
- Set and unique items show a prestige aura as a signature feature.
- Effect style and the two item-seeded colors stay stable between sessions.
- The VFX adds **no attacks, damage, hitboxes, or power**.
- The baked weapon-bearing animations remain in place, so this patch will not
  cause weapons to disappear again by changing their actual sprite renderer.

## Jump traversal and Moonstep trial

Hold a direction and press **C** to jump. This can now pass through clearly
marked **low spectral thorn barriers** on their own physics layer, but not
ordinary scenery or enemies. The normal collision mask returns automatically
on landing, after interruption, and when changing rooms.

In the eastern half of Moonwake Crypt, jump over the narrow thorn barrier and
land on the glowing Moonstep seal. A successful midair landing awards a
set-quality Rose Reaper **once per save**. This makes jumping useful beyond
its existing airborne heavy-attack prototype.

## Compatibility
No changes to existing inventory save keys, item combat stats, original
background paintings, approved character frames, or the four weapon atlases.
Old item seeds generate the same deterministic prestige eligibility whenever
loaded. A real Godot F5 playtest is still required; this archive has been
checked statically and by a patch-install simulation only.
