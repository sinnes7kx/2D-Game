# GHOST GIRL — ACT I
## The Garden That Remembers
**Design specification · PC-first · Godot 4 · No dialogue**

### The promise
A small ghost awakens in a forgotten moonlit estate and gently repairs the things that have lost their purpose. Act I is a peaceful, mysterious three-quarter-view exploration game about **touch, weight, reflection, sequence, and memory**. There is no combat, failure punishment, timer, quest wall of text, or spoken dialogue. The world tells its story through architecture, light, sound, object motion, and Ghost Girl's restrained expressions.

**Character standard:** the primary concept sheet remains definitive. Pale porcelain skin, long silver-white wavy hair, completely black eyes, white short-sleeved lace dress, bare feet and small childlike proportions. Don't replace her with the separate photorealistic ghost portrait or a 3D model. Portrait changes are tied to emotional moments rather than routine actions.

**Art standard:** never build rooms by recoloring, mirroring or relighting another room. Each final background must be a freshly composed environment, produced from the same visual language but with unique architecture, prop layout, lighting and material details. Existing placeholder painted rooms in the previous prototype are not approval to recolor future art.

---

## 1. Core play experience
- **Explore:** WASD or arrow keys to walk, Shift to run. A three-quarter camera follows Ghost Girl with gentle easing.
- **Engage:** press **E** while close to and facing a usable object. No giant prompts: only a small contextual E label appears.
- **Carry:** pick up one physical object at a time; it visibly attaches to her hands.
- **Release:** **G** drops a held object nearby; **R** throws it toward the cursor. The object moves across the ground as a RigidBody2D while a separate vertical arc gives a convincing sense of gravity.
- **Observe:** puzzle feedback occurs inside the environment. Rings brighten, flowers bloom, bells glow and mirrors channel light. No dialogue boxes tell the player they succeeded.
- **Remember:** Ghost Girl's bottom-right portrait stays neutral except at sparse emotional events. After a few seconds it quietly returns to neutral.

### Interaction rules
1. There is one target at a time, selected by proximity and facing direction.
2. The character can carry one object. Picking up a second never destroys the first.
3. Dropped objects retain physics. If they fall in an unreachable area, leaving/re-entering the room restores the initial object layout without erasing completed puzzle progress.
4. Locked gates are represented by unlit symbols and do not open when E is pressed.
5. Objects are `Node2D` or `RigidBody2D` instances inside room scenes. Scene scripts only interpret their state.

---

## 2. Act I room-by-room plan

### Room 01 — The Waking Garden
**Emotional role:** calm curiosity and a sense of being very small in a lovingly abandoned place.

**Unique art direction:** a pale circular fountain, uneven slate walkways, white-blossom tree, moonlit stone fencing, drifting petals and two amber lanterns; central open play space and a clear southern exit. Give the fountain a subtle ripple without adding oversized glowing UI.

**Puzzle — The Weight of a Memory:** a small movable crate rests away from a silver floor seal. E to pick up, carry it across the open courtyard, then G to place it. The seal illuminates and the chapel gate unbars. Throwing the crate onto the plate is also valid.

**Environmental clue:** the seal is shaped like the cross engraved on the crate. No explanatory dialogue.

**Godot editor nodes:** `Gameplay/Carryables/Crate`, `Gameplay/Plates/Seal`, `Gameplay/Portals/chapel`, `Gameplay/VisualClues/GardenMark`.

**Exit condition:** plate detects an unheld object close to its center and near the ground.

### Room 02 — Chapel of Soft Echoes
**Emotional role:** the first realization that abandoned objects can still respond to her.

**Unique art direction:** narrow gothic windows, a mosaic central aisle, faded pews, warm wall candles, three distinct hanging bells, a brass-etched altar, layered shadows from the architecture.

**Puzzle — Three Gentle Notes:** touch three bells in **west → south → east** order. Each correct strike leaves its bell lit. A wrong strike resets the three lights without punishment. A brass triptych engraved near the altar shows the order through pictograms.

**Godot editor nodes:** three `PuzzlePieces/bell_*`, `VisualClues/BellPattern`, locked `Portals/cloister`.

**Exit condition:** all three notes activated in order.

### Room 03 — Whispering Cloister
**Emotional role:** a breath of fresh air after the chapel; introduce the idea that skills from past rooms still matter.

**Unique art direction:** open cloister arcade, hanging ivy, dusty rose vines, broken columns, a circular moonwell, butterfly banners and a partly overgrown north arch. This needs its **own new painting**; do not recolor the chapel.

**Puzzle — The Rose Seal:** move a heavier looking moonstone crate around a garden obstacle to the far seal. The act should emphasize positioning and avoiding collision rather than retreading the exact route from the first garden.

**Editor nodes:** `Carryables/Crate`, `Plates/Seal`, `Portals/sanctum`, `VisualClues/MoonSealMark`. Designers can add blocking `StaticBody2D` shapes and alter object placement without changing the orchestrator.

**Exit condition:** stone rests on seal.

### Room 04 — Moonlit Sanctum
**Emotional role:** first sorrowful recognition. Treat this as a **quiet transition room**, not a second large puzzle level.

**Unique art direction:** a broken sanctuary open to night sky, candles in limestone niches, a tiny memorial garden, pale flowers, a single gentle shaft of light falling onto an altar. A sense of absence rather than threat.

**Interaction — The Lost Memory:** touch a softly glowing memory suspended above the altar. The flowers lift briefly, the eastern water passage opens, and Ghost Girl changes to **sad** for a short moment. There is no monologue or textual lore.

**Editor nodes:** `Memories/LostMemory`, `Portals/lily_pond`, room effects.

**Exit condition:** memory touched once; remains awakened on return.

### Room 05 — Lily Mirror Pool
**Emotional role:** reflection and balance.

**Unique art direction:** a shallow dark-blue water garden with silver water lilies, stepping-stone islands, fluted railings, mossy banks, a broken footbridge and moving moon reflections. The room needs carefully authored safe walkways.

**Puzzle — Two Hands of the Moon:** two movable moonstones must weigh down **two different plates simultaneously**. Ghost Girl can carry or throw them into position. Lifting either stone deactivates that plate until both are resting again. No irreversible failures.

**Environmental clue:** paired lily motifs behind the two floor seals.

**Editor nodes:** `Carryables/MoonstoneOne` and `MoonstoneTwo`, `Plates/LeftSeal` and `RightSeal`, `VisualClues/TwinSealPattern`, `Portals/glasshouse`.

**Exit condition:** both plates active in the same physics frame.

### Room 06 — Glasshouse of Wishes
**Emotional role:** restoration and quiet hope.

**Unique art direction:** a cracked conservatory with curved ironwork, frosted glass, dewy purple foliage, white hydrangeas, climbing blossoms and warm points of lantern light. No reused floorplan from other rooms.

**Puzzle — The Gardener's Sequence:** awaken **rose → lily → iris**. A small, painted flower triptych provides the order. Incorrect touches reset the progress visually. On completion, all three flowers glow together and the observatory gate opens.

**Editor nodes:** `PuzzlePieces/blossom_rose`, `blossom_lily`, `blossom_iris`, `VisualClues/BloomPattern`, `Portals/observatory`.

**Emotional event:** a brief **faint smile**, because she has restored something alive. Do not change expression for merely walking, picking up, throwing or ringing a bell.

### Room 07 — Starfall Observatory
**Emotional role:** gentle wonder and Act I's climax.

**Unique art direction:** a small circular chamber under a broken moon dome, star mosaics in the floor, bronze orrery, tall windows, suspended dust, three silver mirrors and a dormant star on a pedestal.

**Puzzle — A Path Made of Light:** rotate **west, north and east** mirrors with E. The reflected light visibly reaches only as far as the first misaligned mirror; each correct mirror extends the path. A compact etched star chart shows their target orientations. Current prototype alignments are west=2, north=0, east=3.

**Editor nodes:** `PuzzlePieces/mirror_west`, `mirror_north`, `mirror_east`, `VisualClues/StarChart`, `Effects/LightPath`, `Memories/FinalStar`.

**Exit condition:** all mirrors align; E at the newly awakened star completes the Act I story beat.

**Emotional event:** a brief **faint smile** after touching the star, not on every mirror rotation. The final image is a softly illuminated estate beyond the windows—an invitation to Act II, not a loud completion banner.

---

## 3. State and progression

```text
Garden crate → Chapel gate
   ↓
Chapel bells → Cloister gate
   ↓
Cloister rose seal → Sanctum gate
   ↓
Sanctum memory → Lily pond passage
   ↓
Two moonstones / two seals → Glasshouse gate
   ↓
Rose / Lily / Iris → Observatory gate
   ↓
Three aligned mirrors → Touch final star → ACT I COMPLETE
```

Backtracking is allowed. Completed puzzle switches persist during the session. Object positions may reset when revisiting rooms to prevent softlocks. Persistent save/load is a **future implementation task**, not something this document claims is working.

---

## 4. Screen and emotion design

**Default screen:** the playfield, Ghost Girl, and a very small semi-transparent portrait in the bottom-right. No permanent quest banner, no lore frame, no opening dialogue. The room name appears briefly at the upper-left on entry and fades away. A faint E prompt appears only with a valid target. A tiny carry hint appears only when holding an object. H toggles a discreet control legend on PC.

| Trigger | Portrait | Duration | Why |
|---|---|---:|---|
| Movement, idle, pickup, throw | Neutral | — | Mechanical actions are not emotional events |
| Bell or weight puzzle completed | Neutral | — | Feedback belongs in the world |
| Lost memory touched in Sanctum | Sad | About 4 s | Personal grief / recognition |
| Glasshouse restored | Faint smile | About 2.5 s | Meaningful act of care |
| Final star touched | Faint smile | About 5 s | Quiet hopeful ending |

---

## 5. Scene authoring contract

Each room scene lives in `scenes/rooms/` and contains designer-owned nodes:

```text
RoomName (Node2D)
├── PaintedRoom (Sprite2D)
├── [existing StaticBody2D / CollisionShape2D walls]
├── SpawnPoints (Node2D)
│   ├── Default (Marker2D)
│   └── From_<other_room> (Marker2D)
└── Gameplay (Node2D)
    ├── Portals (Node2D)
    ├── Carryables (Node2D)
    ├── Plates (Node2D)
    ├── PuzzlePieces (Node2D)
    ├── VisualClues (Node2D)
    ├── Memories (Node2D)
    └── Effects (Node2D)
```

`main.tscn` separately contains `Room`, `GhostGirl`, `MouseThrowAim` and `HUD` **as actual scene nodes**. `hud.tscn` contains actual `Control`, `Label` and `TextureRect` elements. `player.tscn` points to an editable SpriteFrames resource (`resources/ghost_girl_frames.tres`).

A developer may adjust the locations of existing nodes and collision shapes in the editor; new puzzle types and changed progression rules still need GDScript. Portal destinations are editable in the inspector. Puzzle pieces expose their kind, color and orientation as exported properties.

---

## 6. Production priorities and acceptance checklist

### Art production — required before final Act I signoff
1. Paint **unique** 1448×1086 room compositions for all final locations. Do not recolor or mirror rooms; include clean navigable paths and layerable near/far foreground elements.
2. Create room-specific physics props rather than generic symbols for everything: three sculpted bells, a real rose/lily/iris trio, silver mirrors, moonstones and star pedestal.
3. Draw dedicated neutral and emotional expressions that match the main concept sheet exactly.
4. Add layered ambience: candle flicker, water shimmer, drifting petals, hanging ivy and a few restrained particles.
5. Add optional ambient sound; no voiced lines or compulsory reading.

### Playtest pass
- E selects only nearby, faced objects, and correctly opens door scenes.
- G drops near the character; R throws in mouse direction and the object lands.
- Both pond plates truly require simultaneous, separate weights.
- Wrong bell and flower order resets safely.
- Mirror beam stops at the first incorrect orientation.
- Once a passage unlocks it remains unlocked after returning to previous rooms.
- Art/collision boundaries are inspected **in the Godot editor** via Debug → Visible Collision Shapes.
- Expressions never react to routine item manipulation.
- HUD never obscures character, puzzle, or exit path.

**Prototype status:** The accompanying project implements node-authored scenes, quiet UI, the existing seven-room puzzle logic and no dialogue. Its seven painted backgrounds are carried forward from the previous project; unique final art is **not yet produced** in this pass. Run an F5 playtest in Godot before treating it as a release candidate.

---

## Act I — Moonrose Hook + expanded worlds (current production addendum)

The playable level canvas has been extended to **2389 × 1792**, while Ghost Girl remains her original 2D scale. Seven distinct room paintings now replace the recycled and recolored room art from previous prototypes, and the new transparent `ForegroundCanopy` layers contribute foreground depth. Existing layouts and named interactable nodes have been relocated to match these art compositions.

The Moonrose Hook adapts the dual-action idea from the user's source `Hook.gd`. **Q** pulls a faced, mouse-aimed loose physics object toward Ghost Girl; **F** reels Ghost Girl toward an authored rose anchor without passing through collision boundaries. The hook's flight, latch, and retract states are animated from the ornate rose hook sheet. Ghost Girl's four directional SpriteFrames gain hook and hook-hold animations, with a procedural forward lean/hand reach. Thrown-item ground and wall impacts trigger an independent animated bloom and sparks. These are gameplay mechanics, not only decorative effects.

Puzzle progression and quiet/no-dialogue presentation are unchanged. See `docs/ROSE_HOOK_AND_LARGE_ROOMS.md` for scene names, resources, controls, and remaining limitations.
