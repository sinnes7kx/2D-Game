# Ghost Girl v1.37 — Bellroot Chorus

**Base:** Ghost Girl v1.36. Extract contents directly into the folder with `project.godot`, replacing matching files. Keep a backup of your saves and project first.

## New world interaction

Four original code-drawn Bellroot Chimes are placed around Hollow Veil Moor, each with an independent permanent discovery flag. Every bell recognizes five approaches:

- **F:** Rose-hook a bell.
- **T:** Cast Grasping Roses on its location.
- **Z:** Summon Moonfall Blizzard over it.
- **C + charged bow shot:** Fire a charged arrow while jumping.
- **Falling masonry:** Cause an environmental chainfall near the Graveglass Bell (the eastern v1.36 chain is aligned for this).

**Each new method on each bell is saved separately.** Repeating the same activation cannot farm damage or loot. Ringing a bell sends a single modest shockwave that can interrupt nearby weaker enemies or weaken destructible cover. A new original chime and animated rings/petals signal which method was used.

## Two rewards

1. Ring all four bells by any methods to open the **Chimekeeper Rosary** unique charm chest.
2. Ring all four bells and discover **three distinct methods** across them to open the **Choral Moonbow** unique bow chest. A previously activated bell can be rung again with an untried method, so the second reward is not missable.

Both gates and both reward chests use the original save format and existing item seed/quality mechanics. Five waystones point to the sites and explain the puzzle without adding a large HUD.

## Scope and safety

No original body, weapon, inventory, save file, or moor background artwork is replaced. This patch adds four bell nodes, two puzzle gates, two item definitions, eight deliberately fragile enemies, five hints, and one lore inscription. All props remain independently editable Godot scene nodes.

## Validation

`python tests/validate_v137.py` validates scene syntax structure, file references, unique IDs, save-method design, gameplay wiring, audio file, and the expected progressive reward conditions. **This is static validation only.** The environment does not have a Godot executable, so the complete game and its new mechanics still require an editor import and F5 playtest in Godot 4.x.
