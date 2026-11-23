GHOST GIRL v1.49.1 - MISSING FLOOR BREACH SCRIPT HOTFIX
============================================================

Symptom:
Godot reports missing: res://scripts/floor_breach_v1464.gd

Cause:
Moonwake Crypt scene refers to the early-room floor-breach script from v1.46.4.
The script exists in the original v1.46.4 patch but is not packaged again in
the later v1.47/v1.48/v1.49 incremental patches.

Install:
1. Close Godot.
2. Open the root of your existing GhostGirl2 Godot project (folder that
   contains project.godot).
3. Extract this ZIP into THAT folder, preserving the scripts/ directory.
   Final file must be: <your project>/scripts/floor_breach_v1464.gd
4. Reopen Godot and let it rescan/reimport.

No save files, artwork, scenes, or gameplay tuning are changed. This hotfix
restores the exact original v1.46.4 script (SHA256 c6de8ee3b97440bded10254530922da3c852cb6abde6b99061049595d15b7d11).

If the warning remains, verify you did not extract into an extra folder,
and that the file is spelled floor_breach_v1464.gd (case sensitive).

Static package check only; Godot engine execution not available here.
