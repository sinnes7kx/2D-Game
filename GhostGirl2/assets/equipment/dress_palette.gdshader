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
void fragment() {
    COLOR = COLOR;
}
