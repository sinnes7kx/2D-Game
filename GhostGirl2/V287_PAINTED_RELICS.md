# v2.87 — Painted Relics

The four v2.86 weapons use new transparent, high-resolution held textures and portrait inventory icons if the art pack is installed. No item identity, stats, skills, loot or save changes.

Install the eight PNG files from the companion art pack into `GhostGirl2/assets/ui/weapons_v287/` (relative to repository root). This folder is new; no existing asset needs overwriting. With the game closed, extract the ZIP at the repository root, open Godot and let the images import, then F5. The previous SVGs remain a safe fallback if the art pack is missing.

This source branch intentionally does not contain the binary PNG files; they are supplied in the companion ZIP. Commit the new PNG files and their permanent UID metadata if desired. The code changes alone will not display the new art.

Smoke test: `godot --headless --path GhostGirl2 --script res://tests/v287_painted_relic_smoke.gd`. Check that it reports 4 / 4 installed. In-game verify all directions, heavy attacks, glow off/on, stash and item tooltips. Runtime and rendering have not been tested with Godot.
