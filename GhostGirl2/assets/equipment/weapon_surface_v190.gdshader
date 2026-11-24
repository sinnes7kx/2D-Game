shader_type canvas_item;
render_mode unshaded, blend_mix;
uniform sampler2D pigment_ramp : source_color, filter_linear, repeat_disable;
uniform int surface_mode = 0;
uniform int signature_kind = 0;
uniform int glow_motif = 0;
uniform int color_mode = 0;
uniform float surface_phase = 0.0;
uniform float surface_speed = 0.5;
uniform float strength = 0.35;
uniform vec2 cell_size = vec2(176.0);
uniform bool overlay_only = false;
varying vec4 vertex_tint;
void vertex() {
    vertex_tint = COLOR;
}
void fragment() {
    vec4 art = texture(TEXTURE, UV);
    vec2 local = fract(UV / TEXTURE_PIXEL_SIZE / cell_size);
    float u = local.y;
    float v = local.x;
    float t = TIME * surface_speed + surface_phase * 6.2831853;
    float weight = 0.22 + 0.12 * sin(u * 115.0 + v * 7.0 + surface_phase * 6.2831853);
    if (surface_mode == 1) {
        weight = 0.5 + 0.5 * sin(u * 37.0 + sin(v * 7.0 + surface_phase * 6.2831853) * 2.8);
    } else if (surface_mode == 2) {
        weight = pow(0.5 + 0.5 * sin(u * 21.0 + v * 6.0 + t), 3.0);
    } else if (surface_mode == 3) {
        weight = pow(0.5 + 0.5 * cos(u * 40.0 - t * 2.0), 6.0);
    } else if (surface_mode == 4) {
        weight = 0.5 + 0.5 * sin(u * 10.0 + v * 3.0 - t + sin(u * 18.0 + t));
    } else if (surface_mode == 5) {
        weight = 0.35 + 0.35 * sin(u * 13.0 - t + v * 4.0) + 0.3 * pow(max(0.0, sin(u * 71.0 + v * 39.0 + surface_phase * 6.2831853)), 9.0);
    } else if (surface_mode == 6) {
        weight = 0.5 + 0.5 * sin(u * 27.0 + v * 11.0 + t * 1.5 + sin(u * 59.0 - t));
    }
    float shift = surface_mode >= 2 || color_mode >= 2 || signature_kind == 10 ? TIME * surface_speed * 0.12 : 0.0;
    // Smooth ping-pong along the actual rolled ramp, never a forced hue wheel.
    float sample_at = 1.0 - abs(mod(u + shift, 2.0) - 1.0);
    vec3 pigment = texture(pigment_ramp, vec2(sample_at, 0.5)).rgb;
    float lum = dot(art.rgb, vec3(0.299, 0.587, 0.114));
    vec3 tinted = pigment * (0.42 + 0.58 * lum);
    float amount = strength * (0.22 + 0.78 * clamp(weight, 0.0, 1.0));
    // Small moving engraved flashes, restricted to the original weapon alpha.
    float motif = pow(max(0.0, sin(u * (28.0 + float(glow_motif) * 7.0) - t * 2.0 + sin(v * 30.0) * float(glow_motif) * 0.35)), 10.0);
    if (signature_kind > 0) {
        float line = sin(u * (19.0 + float(signature_kind) * 5.0) - t * 2.0 + sin(v * 45.0 + t) * 2.0);
        motif = max(motif, pow(max(0.0, line), 9.0));
    }
    tinted = mix(tinted, mix(pigment, vec3(1.0), 0.30), motif * 0.42);
    amount = min(0.52, amount + motif * (signature_kind > 0 ? 0.22 : 0.10));
    vec3 result = mix(art.rgb, tinted, amount);
    float alpha = art.a * vertex_tint.a;
    if (overlay_only) {
        result = tinted;
        alpha *= amount * 0.88;
    }
    COLOR = vec4(result * vertex_tint.rgb, alpha);
}
