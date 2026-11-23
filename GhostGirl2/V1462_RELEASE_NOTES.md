# Ghost Girl v1.46.2 — Hollow Veil Moor Performance Repair

**Base:** v1.46.1 (Boolean Runtime Repair). This is an incremental patch.

## Root cause identified
Hollow Veil Moor contains 210 regular enemy instances (127 wraiths, 64 moths/lantern creatures and 19 hunters), plus the optional Moor Warden. All were updating AI and animation regardless of distance. The room also contains 50 animated waystones, 17 lanterns, 9 story slabs and 3 water-ripple overlays. These created avoidable CPU work even while completely off-screen.

## Improvements
- New editor-owned `MoorPerformanceDirector` node sleeps enemy physics and visual updates beyond 1,950 pixels and wakes them inside 1,500 pixels, with hysteresis and a 0.24-second check interval. This preserves their placement, health, drops, collision shapes and quest interactions.
- Animated waystones, lanterns, story slabs and ripple overlays stop updating when far away, and resume when nearby. Gameplay objects and puzzle timers are **not** paused.
- Nearby purely decorative objects redraw at about 10–12 Hz instead of every rendered frame.
- Rain continues to follow the player every frame, while its streaks redraw at about 30 Hz.
- In Hollow Veil Moor only, informational HUD hints scan nearby interactables every 0.10 seconds, while pressing E still performs an immediate target check.
- The manager exposes `awake_enemies`, `sleeping_enemies`, `paused_decorations` via Godot Remote Inspector and offers configurable distance thresholds.

## Unchanged
All enemy instances, enemy stats, loot, character/weapon animations, room geometry and collision, world art, quest progress and saves. The original 10,368 × 6,912 moor painting has not been changed or recompressed. Other v1.46.1 repair files are not replaced.

## Installation
Close Godot, back up the project, and extract this ZIP into the directory containing `project.godot` **after v1.46.1**. Overwrite matching files. Reopen Godot and press F6 to test the moor. Use Godot Debugger → Profiler to measure frame time and Remote → MoorPerformanceDirector to inspect active/sleeping counts.

## Verification / limitations
v1.46.2 static checks, resource path audit, clean patch installation and SHA-256 integrity pass. v1.44/v1.46 static regression checks and the v1.46.1 bool-conversion check pass. The v1.45 checker has a stale literal `bool(...)` expectation; that check also fails on the unmodified v1.46.1 base because of the required bool repair.

**Godot F5 runtime and actual FPS benchmarking were not available**. This addresses substantial CPU overhead but does not guarantee a particular frame rate. The original enormous painting may still require high video memory; optional texture tiling may be needed if GPU memory is the bottleneck.
