shader_type canvas_item;
// v1.52 — physically separate cloth dye and enchanted-weapon highlights.
// The compact mask tracks dress/skirt pixels in both unarmed and armed frames.
// This material never uses weapon_strength to activate the dress dye.
uniform vec4 dress_tint : source_color = vec4(1.0);
uniform float tint_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec4 weapon_accent : source_color = vec4(0.87, 0.65, 0.95, 1.0);
uniform float weapon_strength : hint_range(0.0, 1.0) = 0.0;
uniform float cloth_filagree_strength : hint_range(0.0, 1.0) = 0.0;
uniform float cloth_filagree_phase = 0.0;
// v1.92.3: baked body art has no trustworthy per-frame fabric/weapon mask.
// Never infer hair, skin or equipment from hue or whole-atlas UV coordinates.
// Preserve the approved original pixels until authored cloth masks exist.
// v2.26: optional, bounded secondary movement in approximate outer hair
// and lower hem zones. No hue-derived masks. Only supported 256x220 poses
// enable this branch; the face, central torso and weapon poses are protected.
uniform float silk_enabled : hint_range(0.0, 1.0) = 0.0;
uniform float silk_phase = 0.0;
uniform float silk_lag : hint_range(-1.0, 1.0) = 0.0;
uniform float silk_energy : hint_range(0.0, 1.0) = 0.0;
varying vec2 silk_local;
varying vec4 silk_ink;
void vertex() {
    silk_local = VERTEX;
    silk_ink = COLOR;
}
void fragment() {
    if (silk_enabled > 0.5) {
        vec2 p = silk_local;
        // Spatial envelopes are deliberately small and zero near the face,
        // wrists, frame borders, and upper torso. No pixel-color inference.
        float outer = smoothstep(38.0, 55.0, abs(p.x)) * (1.0 - smoothstep(76.0, 94.0, abs(p.x)));
        float hair = outer * smoothstep(-87.0, -65.0, p.y) * (1.0 - smoothstep(-28.0, -14.0, p.y));
        float hem = (1.0 - smoothstep(37.0, 55.0, abs(p.x))) * smoothstep(58.0, 80.0, p.y) * (1.0 - smoothstep(95.0, 106.0, p.y));
        float wave = sin(silk_phase + p.y * 0.075);
        float hair_dx = (0.65 * wave + 1.4 * silk_lag) * (0.55 + 0.45 * silk_energy);
        float hem_dx = (0.75 * sin(silk_phase * 1.13 - p.y * 0.052) + 1.35 * silk_lag) * (0.55 + 0.45 * silk_energy);
        vec2 shift = vec2(hair * hair_dx + hem * hem_dx, hem * 0.7 * sin(silk_phase * 1.2 + p.x * 0.06));
        if (dot(shift, shift) > 0.000001) {
            // UV offset is in actual backing-texture pixels. Local frame
            // borders are never sampled by either deformation envelope.
            COLOR = texture(TEXTURE, UV - shift * TEXTURE_PIXEL_SIZE) * silk_ink;
        }
    }
}
