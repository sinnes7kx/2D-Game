# Ghost Girl v1.36 — Chainfall & Shattered Cover

Incremental source patch for **v1.35**. Extract directly into the Godot project folder containing `project.godot`. This does **not** replace the large moor painting or any approved Ghost Girl / weapon sprites.

## New environmental systems

**Chainfall:** Two optional, three-link collapse sequences in Hollow Veil Moor. First, initiate the western support with the rose hook (`F`) or a thrown crate. In the east, weaken the first joint using Moonfall (`Z`), then pull it with the hook (`F`). On impact, each fallen structure can weaken the next link: physical debris, not particles, causes the domino effect. Each link saves its collapse state; only the first link can be activated directly on these two chains.

**Breakable cover:** Four small barricades sit near moor encounters. Enemy hex shots, arrows, and thrown crates can damage them. Hooking one pulls it apart instantly. A broken barricade briefly splinters and can injure a nearby enemy once; it no longer blocks arrows or movement afterward. Barricades refresh when the room is loaded, intentionally allowing repeated tactical use. They do not generate additional loot.

**Reliability repair:** The hook now resolves a physical `HookBody` collision to its parent mechanism, rather than incorrectly treating the nested collider as a generic hookable wall.

**Exclusive rewards:** Complete all three west-chain links to open the unique **Chainwake Locket** cache; complete all three east-chain links to open the unique **Mourning Girder** bow cache. Rewards are one-time, saved by the existing collected-pickup flags. Two recovery shrines and two short inscriptions have been added nearby.

## Locations and testing

- **Western Chainfall:** around `(3100, 2900)`; follow the linked supports eastward
- **Eastern Chainfall:** around `(7300, 3880)`; frost, then hook, then follow the impacts
- **Breakable barricades:** around `(2720, 3260)`, `(4160, 3460)`, `(6940, 3610)`, `(8410, 4420)`

Open the moor using its existing shortcuts/portals. Aim carefully, as the hook still obeys solid collisions. Test saving, exiting, then returning: broken supports and opened reward gates should persist. The cover barricades should reset on re-entry by design.

## Validation caveat

Static checks verify files, resource paths, scene node parents, unique IDs, item dependencies, and source-level damage-event wiring. **No Godot executable was available**, so F5 playtesting, visual pacing, collisions, and physical feel still need confirmation in Godot 4.x.
