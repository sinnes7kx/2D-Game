# Original cardinal animation restoration

The generated cardinal replacement atlases and candidate wrist-guide JSON are no longer used. This branch retains the project's original character PNGs, frame geometry, weapon anchors and existing art selection. The approved diagonal assets remain untouched.

The existing body shader now has an isolated cardinal-only detail pass. It adds a small bounded luminance detail correction to opaque interior pixels in centered 256 × 220 original cardinal frames. It does not change alpha, silhouette, UV geometry, source textures, frame count, weapon anchors, damage, or combat timing. The pass is disabled for all diagonal clips, alternate skin clips, flipped/offset or incorrectly sized frames. Direction changes retain the normalized idle/walk phase. Separate weapon layers keep their existing materials.

Parry continues to use the original raised-arm body frames and their existing guide coordinates. Confirmed contact immediately displays the guard pose while retaining gameplay recovery timing. No generated artwork is promoted to approved authored status.

This is a non-destructive first visual restoration, not a painted replacement of the older animation sheets. The uploaded full asset ZIP could not be opened due to the execution environment returning errors; individual repository original PNGs were inspected instead. Final painterly matching of the original cardinal frames to the new diagonal atlas, and runtime verification in Godot, remain outstanding. Do not install the older candidate asset patches.
