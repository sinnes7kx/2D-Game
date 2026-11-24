shader_type canvas_item;
render_mode unshaded, blend_mix;
uniform vec4 primary_color : source_color = vec4(0.91, 0.69, 0.82, 1.0);
uniform vec4 secondary_color : source_color = vec4(0.63, 0.81, 0.99, 1.0);
uniform sampler2D palette_ramp : source_color, filter_linear, repeat_disable;
uniform bool use_palette_ramp = false;
uniform float gradient_angle = 0.0;
uniform float gradient_speed = 0.5;
uniform float pulse_speed = 1.4;
uniform float glow_power = 0.10;
void fragment() {
    vec4 original = texture(TEXTURE, UV);
    float travel = dot(UV - vec2(0.5), vec2(cos(gradient_angle), sin(gradient_angle)));
    float t = clamp(0.5 + 0.42 * sin(travel * 2.2 + TIME * gradient_speed * 0.36), 0.0, 1.0);
    vec3 tint = use_palette_ramp ? texture(palette_ramp, vec2(t, 0.5)).rgb : mix(primary_color.rgb, secondary_color.rgb, t);
    // A translucent enamel accent, rather than replacing the painted bow.
    // Soft alpha contour prevents hard-mask edges at half sprite scale.
    float alpha_soft = smoothstep(0.02, 0.88, original.a) * 0.32;
    float shimmer = 0.92 + 0.08 * sin(TIME * pulse_speed + travel * 4.0);
    COLOR = vec4(tint * (0.76 + original.r * 0.22) * shimmer, alpha_soft);
}
