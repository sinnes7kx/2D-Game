# Ghost Girl v1.34 — The Last Vigil

Incremental development patch for v1.33.

## Hollow Veil Moor — Vesper Vigil
- Following the Moor Warden's defeat, reach the optional ritual near (3200,3750).
- Press **E** at the moonlit circle to begin an 18-second hold-ground encounter.
- Remaining within 190 pixels advances the ritual; leaving gradually lowers progress.
- At approximately 1, 7 and 13 seconds, two fragile temporary enemies approach.
- The ritual completes permanently and opens the Vesperglass Wand chest. Partial attempts do not alter saved data.
- Two inscription stones describe the final watch. A new waystone points toward the clearing.

## New reward
Vesperglass Wand — guaranteed unique spell-focused wand. Loot and its exceptional visual appearance use the preexisting item system. Completion and chest pickup use the old `collected_pickups` save flags.

## Moor Warden presentation
The original single-hit attacks now each emit their own fading visual release: crescent wake, radial shockwave, and spectral lance. Their hit timing, range, damage, and jump avoidance are unchanged.

## Editor notes
- `Gameplay/V134VesperVigil/V134VesperCircle` — encounter, progress, and wave behavior
- `Gameplay/V134VesperGate` — actual reward seal with collision and chest linking
- `Gameplay/TreasureChests/V134VesperChest` — guaranteed one-time unique item
- `Gameplay/V134VesperVigil/V134InscriptionOne/Two` — readable lore
- `Gameplay/Waystones/V134WarningStone` — navigation hint

## Testing limitation
All static validation and clean-patch tests passed when packaged. A real Godot 4.x import, F5 playtest, collision/visual alignment check, and encounter-balance pass are **still necessary**; no engine runtime was available in this environment.
