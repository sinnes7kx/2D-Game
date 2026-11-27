# Permanent eight-direction art

The calibrated wrist tables correspond to the two reconstructed v249 PNGs
distributed in GhostGirl_Diagonal_Atlas_Repair.zip, not arbitrary renamed
spritesheets. Both are 2048 × 1760 RGBA, eight 256 × 220 cells per row.

* `assets/ghost/skins/ghost_diagonal_v249.png` — idle rows 0–3; walk rows 4–7.
* `assets/ghost/skins/ghost_diagonal_actions_v249.png` — dodge rows 0–3; jump rows 4–7.
* Direction order: front-right, front-left, back-left, back-right.

Extract the repair ZIP into the repository root containing GhostGirl2.
In GitHub Desktop select the two PNG files in Changes, commit them, then Push
origin. Do not commit .godot or import cache files. The repository ignores
generated import sidecars already. If you already have both files locally,
just commit them; do not overwrite different artwork without checking it.

Optional verification: run `python GhostGirl2/tools/check_diagonal_assets.py --tracked`
from the repository root. This verifies the actual bytes and Git tracking, and
returns a nonzero status on missing or different art. No CI jobs are enabled.

Action anchors are visually estimated from the repair frames. Far-hand guides
are omitted for hidden hands. Ground/air attacks and casting still use existing
cardinal combat artwork; this change adds equipped diagonal jump and dodge
carry, not newly authored diagonal attack animations.

F5 checklist: unarmed and each equipped family, all four diagonal directions;
jump, dodge, stop, attack, land, reopen inventory preview; inspect near/far
hand and shared glow. Confirm diagonal aliases are not replaced by preview.
