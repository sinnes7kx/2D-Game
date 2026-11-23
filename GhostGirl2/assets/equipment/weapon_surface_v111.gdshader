shader_type canvas_item;
render_mode blend_mix;

// Four independently saved appearance channels. Paint lives only on the
// transparent weapon overlay, NEVER on Ghost Girl's face/dress/body.
uniform vec4 base_color : source_color = vec4(0.85, 0.7, 0.87, 1.0);
uniform vec4 gradient_color : source_color = vec4(0.65, 0.84, 0.96, 1.0);
uniform vec4 engraving_color : source_color = vec4(0.91, 0.83, 0.96, 1.0);
uniform sampler2D detail_atlas : source_color, filter_linear, repeat_disable;
uniform int detail_a_index = 0;
uniform int detail_b_index = 2;
uniform float appearance_seed = 0.0;

varying vec2 pixel_position;
void vertex() {
    // SpriteFrames atlas tiles use a fixed 256x220-sized quad centered at 0.
    // Local coords are stable across the 8x8 sheets and regardless of frame.
    pixel_position = VERTEX + vec2(128.0, 110.0);
}

float detail_sample(int idx, vec2 uv) {
    float id = float(idx);
    vec2 offset = vec2(mod(id, 2.0), floor(id / 2.0));
    vec2 local_uv = fract(uv);
    return texture(detail_atlas, (offset + local_uv) * 0.5).r;
}

void fragment() {
    vec4 original = texture(TEXTURE, UV);
    if (original.a <= 0.003) {
        COLOR = vec4(0.0);
    } else {
        vec2 p = pixel_position;
        float shade = dot(original.rgb, vec3(0.299,0.587,0.114));
        float chroma = max(max(original.r, original.g),original.b) - min(min(original.r,original.g),original.b);
        // Metallic areas receive stronger color; original purple gemstones and
        // hand-authored contrast retain more of their painted identity.
        float metal = smoothstep(0.12,0.54,shade) * (1.0 - 0.38*smoothstep(0.07,0.38,chroma));
        vec3 tinted = mix(original.rgb, original.rgb * (base_color.rgb * 1.30), 0.56*metal);
        float grad = smoothstep(0.10,0.90,clamp(p.y/220.0 + 0.13*sin(p.x*0.038+appearance_seed),0.0,1.0));
        tinted = mix(tinted, tinted * (gradient_color.rgb*1.30), 0.42*grad*metal);
        // Pattern A: metal grain / stone wear. Pattern B: rose/celestial
        // filigree, sampled independently from the same small atlas.
        vec2 uv_a = p/vec2(100.0,110.0) + vec2(appearance_seed*0.17, appearance_seed*0.09);
        vec2 uv_b = p/vec2(180.0,180.0) + vec2(appearance_seed*0.03, appearance_seed*0.19);
        float grain = detail_sample(detail_a_index,uv_a);
        float filigree = detail_sample(detail_b_index,uv_b);
        tinted *= 1.0 - 0.13*grain*metal;
        tinted += engraving_color.rgb * (0.18*filigree*metal*grad);
        COLOR = vec4(clamp(tinted,vec3(0.0),vec3(1.0)),original.a);
    }
}
