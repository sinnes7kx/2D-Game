# Ghost Girl v1.46.4 — Compact looks & early-world structural puzzles

Apply on top of v1.46.3. Only changed scripts and two room scenes are shipped.

## Cosmetics / inventory
- Item tooltips keep core name, quality, description, damage, stats and sockets.
- Visual-only motif, palette, trail and raw loot/cosmetic seed text are removed from item tooltips.
- Three tinted dots replace long visual-affix labels; compact swatch previews appear in the inspector.
- REROLL keeps random numerical seed identifiers internally; SAVE ♥ stores exact values.
- FAVORITES shows colored gradients as icons instead of named/numbered seeds.
- Existing saved seed snapshot dictionaries remain supported and stats are never rerolled.

## Moonwake Crypt — fractured floor
- Aim the rose hook at the cracked support near the starting floor and press F.
- A telegraphed masonry fall lands to its west; 0.84s later a permanent visual hole is open.
- Face the hole and press E to descend to the already-existing Crypt Gallery.
- Existing crypt/gallery doors still work; this optional route adds no progression deadlock.

## Waking Garden — under-roots cache
- A withered trellis support near the southwest walk can be pulled with F.
- Falling thornwood reveals a hidden, one-use cache with a pre-existing item template.
- Cache open state and both collapses reuse inventory.collected_pickups; old saves stay valid.

## Validation limits
- Static checks validate scene paths, new groups and references, and ZIP integrity.
- A Godot F5 playtest, visual alignment, and save/reload still need an in-engine check.
