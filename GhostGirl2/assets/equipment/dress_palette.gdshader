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
void fragment() {
    vec4 base = texture(TEXTURE, UV);
    // Clothing lives below the shoulders, centered on Ghost Girl's figure.
    // Keep white hair on the outer silhouette and the face untouched.
    float hem = smoothstep(0.45, 0.60, UV.y) * (1.0 - smoothstep(0.94, 0.99, UV.y));
    float midline = smoothstep(0.22, 0.38, UV.x) * (1.0 - smoothstep(0.63, 0.80, UV.x));
    float pale_fabric = smoothstep(0.36, 0.67, dot(base.rgb, vec3(0.3333)));
    float cloth_mask = clamp(hem * midline * pale_fabric * base.a, 0.0, 1.0);
    float brightness = dot(base.rgb, vec3(0.30, 0.59, 0.11));
    // Larger hue separation between palette swatches, retaining fabric texture.
    vec3 dyepigment = dress_tint.rgb * (0.49 + brightness * 0.66);
    vec3 dyed = mix(base.rgb, dyepigment, cloth_mask * tint_strength * 0.78);
    // v1.54: a subtle rose-lattice embroidery in the hem, independent of arms
    // and weapon art. Stable from dress cosmetic seed, never animated blocks.
    vec2 warp = UV * vec2(23.0, 18.0);
    float petal = sin(warp.x + sin(warp.y * 0.78 + cloth_filagree_phase) * 1.28)
                * cos(warp.y * 1.38 - sin(warp.x * 0.65 + cloth_filagree_phase));
    float braid = sin((warp.x + warp.y * 0.52) * 2.1 + cloth_filagree_phase);
    float embroidery = smoothstep(0.55, 0.86, abs(petal)) * 0.65
                     + smoothstep(0.92, 0.99, braid) * 0.35;
    float embroider_mask = cloth_mask * cloth_filagree_strength * clamp(embroidery, 0.0, 1.0) * 0.27;
    vec3 embroidered = mix(dyed, dress_tint.rgb * 0.66 + vec3(0.30), embroider_mask);
    // Weapon highlights are a separate spectral pass — unrelated to dress.
    float violet = smoothstep(0.045, 0.100, base.r - base.g)
                 * smoothstep(0.075, 0.165, base.b - base.g)
                 * smoothstep(0.25, 0.55, dot(base.rgb, vec3(0.3333)));
    float spectral = clamp(violet * weapon_strength * (1.0 - cloth_mask * 0.9), 0.0, 1.0) * base.a;
    float lum = dot(embroidered, vec3(0.30, 0.59, 0.11));
    vec3 weapon_dyed = clamp(weapon_accent.rgb * (0.24 + lum * 1.42), 0.0, 1.0);
    COLOR = vec4(mix(embroidered, weapon_dyed, spectral), base.a);
}
