# Ghost Girl v1.50 — Momentum, Shatter & Stagger

**Incremental update for fully assembled v1.49 or v1.49.1.** The v1.49.1 floor-breach hotfix script is included, so installing that hotfix separately is not required. Preserve all prior assets and scenes: this patch is an overlay, not a full project.

## Playable changes

- **Jump-to-ground input flow:** During the final 0.19 seconds of a jump, pressing dodge queues a grounded backstep. Once a jump attack has started, pressing another attack during this landing window queues the next grounded attack. There is no additional free air strike. Stamina and existing attack restrictions still apply, and queued actions expire normally.
- **Smash through rotten barricades:** Heavy melee and plunging attacks can damage up to two visible wooden barricades within a short frontal arc. The attack is obstructed by solid walls. Contact has localized hitstop, a wood impact sound, camera weight, splinters, smoke, and the existing barricade burst. Smashing props does **not** count as hitting an enemy for rally healing.
- **Early-room training spaces:** Two breakable, collidable wooden props are placed in Moonwake Crypt and two in the Waking Garden. They are editor-authored, optional, and don't change completion flags or rewards. They reset when a room is re-entered, like existing Moor breakables. They don't repeatedly display the pickup HUD message.
- **Enemy recoil & poise break:** Regular enemies move back slightly from actual damage while respecting wall collision; elites resist the displacement. When poise breaks, a short pale break burst plays. Damage, item stats, enemy health/loot rates, saved progression, and AI windup duration are unchanged.
- **Bow i-frame correction:** Getting harmlessly touched during an invulnerable window no longer cancels an already-held bow draw.
- **Reliability:** The floor-breach script from v1.49.1 is included to avoid the previously reported missing-resource editor error on partial overlays.

## Manual Godot F5 checks still needed

1. Load Moonwake Crypt and Waking Garden on an existing save. Confirm all four new wooden barricades appear, don't trap the player or overlap existing props, and can be hooked or smashed with a heavy/jump attack. Try heavy attacks through a stone wall: they must not reach a barricade behind it.
2. Jump, press dodge just before touching ground: you should backstep immediately after landing (no midair backstep). Start a plunging attack and press light attack near landing: you should perform exactly one follow-up and spend normal stamina. Spam dodge or attack before the input window: no impossible cancel should occur.
3. Use a ranged/charged bow shot, then trigger a harmless i-frame collision. The draw should remain active. Taking real damage should still interrupt the draw.
4. Hit normal and elite enemies with light/heavy attacks: normal targets should recoil subtly, elites less. Only stagger breaks should show the pale particle ring. Check crowded trial fights for excessive effects.
5. Re-enter rooms and load an old save. Existing trial rewards, floor-breach hole, equipped visuals and cosmetic swatches, and rest shrines should behave as before.
6. Confirm the Godot editor's FileSystem and scene tree have no red missing script paths.

## Verification scope

Static scripts, resource-reference checks, and previous-version regression checkers can run without Godot. **No Godot 4 runtime F5 or visual/movement playtest was possible in the patch environment.** Balance and feel may still require adjustment based on in-engine feedback. No user:// save schema is changed.
