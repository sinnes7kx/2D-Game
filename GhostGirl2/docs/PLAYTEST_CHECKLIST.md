# Act I Exploration — Godot 4 F5 smoke test

**This build was statically checked but not run in a Godot engine.** Test with F5 after importing `project.godot` and review the Debugger and Output docks.

1. Press **F5**: Ghost Girl begins in Moonwake Crypt. Character is 2D; no dialogue box.
2. Approach the lower-right Moon Rose Key and press **E**. Press **Tab** or **I** to view the six-slot inventory.
3. Leave via the eastern door to **Waking Garden**; the crypt has no mandatory puzzle.
4. Return to Crypt and try the optional **Memorial Gallery** doorway in the western side of the room; confirm it has a return door and an alternate garden exit.
5. In Waking Garden, find two optional passages: **Broken Rose Bridge** on the western side and **Rose Arbor** toward the eastern side. Both reconnect, forming an exploration loop.
6. At Broken Rose Bridge, try walking the longer route around the lower water versus using **F** to hook the opposite-bank rose anchor across the broken crossing. The hook should cast only within **450 world pixels**. A new world collision layer called **Hook traversal gaps** blocks normal walking but is temporarily ignored during a valid player reel.
7. On the bridge, try **Q** to pull one of the loose stones toward her from within range. Aim past a solid wall and confirm the hook does not pass through it.
8. Add `hook_blocker` to a test object in Godot's **Node → Groups** panel and verify neither hook mode attaches to that object.
9. Throw a loose stone with **R**. Confirm impact petals, particles and the animation complete and disappear without removing the stone.
10. Visit the Rose Arbor. Walk around the central flower garden, reach both exits, and try anchors at different angles. Confirm foreground foliage overlays the character naturally near edges.
11. In each new scene, expand **Gameplay / FutureSecrets**: markers should be visible in the editor but should not spawn real collectible rewards yet.
12. Open `scenes/ambience/*.tscn`: verify flickering candle light, animated water rings, petals and fireflies. Change a frame via `resources/*_ambience_frames.tres` and confirm it updates.
13. Inspect the night-palette tile images in `assets/tilesets/`. They are darker sheets for future TileMap painting, not duplicated room backdrops.
14. The **Moon Rose Key** should still unlock the northern Chapel Gate in Waking Garden. The previous later-chapter puzzles should still load.
15. Enable **Debug → Visible Collision Shapes**. Walk around all new props, especially the bridge crossing; adjust `Collisions/*/CollisionShape2D` in each room scene if their simple rectangles overlap the painting imperfectly.

**Known limits:** New paintings are individual original compositions or supplied room references scaled to a shared game size. This milestone expands the playable area through connected sub-areas, not a single seamless streaming map. The shortcuts and collision shapes require a real Godot playtest before being treated as finished.
