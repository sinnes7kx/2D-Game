# Cardinal refresh (candidate)

Two optional, transparent 2048 × 1760 candidate atlases (8 columns, 8 rows; 256 × 220 cells):
- `ghost_cardinal_refresh_candidate.png`: idle front/back/left/right, walk front/back/left/right. Loaded only for unarmed cardinal locomotion.
- `ghost_cardinal_combat_candidate.png`: parry front/back/left/right, candidate light attack front/back/left/right. Only the four parry rows are installed. The attack rows are deliberately unregistered pending family-specific action review.

The PNGs are not committed as binaries: the repository connector can write code and JSON but did not expose a way to transfer the local PNGs. Apply the companion asset patch into the repository root before testing this branch. Without both files, the respective loader keeps existing art.

The guard importer reads `resources/cardinal_guard_candidate_guides.json`, with visually estimated left/right wrist coordinates for each frame and explicit hidden hands. It validates dimensions, the complete four-row set, and peak guard lead-wrist presence. Existing approved authored guards take precedence. Candidate guards remain excluded from the approved artwork audit. Shared single and paired weapon renderers use the same pose and wrist guides; hidden wand poses and their light are suppressed. A confirmed contact advances to the guard hold immediately even if the parry was early; recovery retains the existing gameplay timer. Original diagonal art and combat timings, stats, saves are unchanged by design.

The locomotion loader preserves original duration and normalized phase across directional changes, including in the equipment preview.

Review status: both atlases are generated candidate artwork, not visually approved replacements. Original diagonal PNGs remain unavailable for direct comparison; the new guard candidate has visible face/dress differences and cannot yet be claimed an exact identity match. Validate scale, silhouette, loop smoothness, equipped transitions, wrists, occlusion, parry recovery and every weapon family in Godot. Equipped idle/walk, family-specific attacks, jump, dodge and final polished parry art remain outstanding. Do not merge as a finished art refresh.
