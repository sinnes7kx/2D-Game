# v2.90 — Rose Cyclone & Lanternhaven Living Air

Rose Reflection (Rosemirror Twinblade) is now a hybrid channel. Start with Shift + Mouse2, then keep Mouse2 held while walking. Startup 5 stamina, base drain 21/s, 80% walking speed. Swept physical double-blade contact remains active within 111 px. An outer wind field grows from 0.35 to 1.15 seconds, reaching 132 px, with a weaker pulse beyond the blade radius. The regions are separated to avoid overlapping damage at the same position. Martyr Crown retains its stronger dedicated 145 px cyclone and higher drain.

Both channels cycle existing approved cardinal body poses; two to four sampled translucent character afterimages and layered ribbons supply stylized motion blur without changing source art or adding a postprocessing blur pass. No changes to item rolls, ownership or saves.

Lanternhaven now has warmer lantern halos, thicker world-space mist, lamp-local floating motes, a dark subtle vignette/grain overlay below the existing color grade and HUD, and a cached twelve-second synthetic wind and distant bell loop. All are room-owned. Shift+F5 cycles atmosphere Off/Subtle/Cinematic; Off removes the new effects and stops the town sound. Shift+F3 bounds mote and afterimage counts; Low retains the existing no-foreground-fog setting. Shift+F6 still controls the separate global grade.

Manual QA: equip Rose Reflection and Martyr Crown, hold RMB after Shift+RMB, move in eight directions, release, dodge, take damage, run out of stamina and change rooms. Verify silhouettes, afterimages, no residual effects and relative damage. In Lanternhaven cycle all three graphics presets and walk between lamps; visit another room and return; check audio stops, no duplicate ambience, HUD remains readable and FPS stays acceptable.

Smoke: godot --headless --path GhostGirl2 --script res://tests/v290_rose_atmosphere_smoke.gd

No Godot executable available in the development environment; smoke test execution, actual visuals, audio quality and combat balancing remain unverified.
