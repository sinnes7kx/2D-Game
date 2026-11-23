# Godot F5 playtest — Crypt → Garden

Run `scenes/main.tscn` with **F5** in Godot 4.x. These checks are required because this development environment did not have a runnable Godot executable.

## Opening & inventory
- [ ] F5 opens **Moonwake Crypt** (never the old garden puzzle).
- [ ] Room name briefly appears top-left; there are no dialogue windows.
- [ ] Ghost Girl moves freely across the middle floor, cannot walk through the coffin, stone walls, statue or memorial pedestal.
- [ ] Walk to the small glowing silver **Moon Rose Key** beside the right memorial pedestal; face it and press E.
- [ ] It disappears from the world and appears in inventory. A restrained pickup notification fades out.
- [ ] Tab or I shows six inventory slots, with Moon Rose Key in slot one. Clicking it displays the description.
- [ ] Tab or I closes inventory; returning to the crypt does not duplicate the key.
- [ ] The right-side arched crypt exit works with E whether or not the key has been picked up.

## Waking Garden
- [ ] Entering the garden starts near its southern path, with the large painted fountain visible further north.
- [ ] There is **no crate-on-pressure-plate gate puzzle** in this first outdoor room.
- [ ] E at the northern chapel gate does nothing until the Moon Rose Key is collected.
- [ ] After collecting the key, E unlocks the chapel gate with a quiet notification; E again enters the Chapel of Soft Echoes.
- [ ] The key remains in inventory after unlocking the gate. Returning to the garden preserves the opened gate.
- [ ] There is a practice moonstone on the path; E picks it up, G drops, R throws it toward the cursor.
- [ ] Thrown objects create the original moondust impact particles on landing or a strong collision.

## Rose Hook
- [ ] Q points the hook toward a loose moonstone and reels it toward Ghost Girl when it is **within 280 px**.
- [ ] F can attach to nearby collidable stone or a rose anchor, pulling Ghost Girl without passing through solid walls.
- [ ] Targets beyond 280 px cannot be hooked. Adjust the range in `scenes/rose_hook.tscn` if desired.
- [ ] Add the **hook_blocker** group to a test `StaticBody2D` in Godot; F can no longer latch to that object.
- [ ] A wall in front of the target blocks the hook ray.
- [ ] Hook animations play in the direction Ghost Girl faces, without changing her main character design.

## Editor test
- [ ] Open `scenes/rooms/moonwake_crypt.tscn` directly: painting, foreground overlay, blockers, SpawnPoints, MoonRoseKey and garden portal all exist as editable nodes.
- [ ] Open `scenes/rooms/garden.tscn`: two portals, practice stone and rose anchors are directly editable.
- [ ] Open `scenes/inventory_panel.tscn`: six button nodes, title and item detail label are editable.
- [ ] Enable **Debug → Visible Collision Shapes** to adjust blockers as needed.

Known limitations: world collider shapes are approximate, inventory progress is session-only, remaining six rooms still need their next dedicated art/puzzle polish pass, and hook anchoring is based on **physics colliders** rather than image pixels. This package is a prototype and has not been live-playtested in the Godot engine here.
