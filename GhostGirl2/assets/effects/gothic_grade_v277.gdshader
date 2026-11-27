shader_type canvas_item;
render_mode unshaded;
uniform sampler2D scene_tex : hint_screen_texture, repeat_disable, filter_linear;
uniform float strength : hint_range(0.0,1.0) = 0.58;
uniform float vignette : hint_range(0.0,0.5) = 0.17;
uniform float atmosphere : hint_range(0.0,0.2) = 0.042;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 src = texture(scene_tex, uv).rgb;
	float lum = dot(src, vec3(0.2126,0.7152,0.0722));
	vec3 graded = mix(vec3(lum),src,0.88);
	// Soft contrast with raised violet-black shadows, not crushed blacks.
	graded = graded + (graded-0.42)*0.12;
	float shadow = 1.0-smoothstep(0.08,0.56,lum);
	float light = smoothstep(0.38,0.92,lum);
	graded += vec3(0.023,0.009,0.047)*shadow;
	graded += vec3(0.055,0.033,0.006)*light;
	float haze = (1.0-smoothstep(0.0,0.85,lum))*atmosphere;
	graded = mix(graded,vec3(0.29,0.24,0.35),haze);
	vec2 edge = (uv-vec2(0.5))*2.0;
	float rim = smoothstep(0.38,1.40,length(edge));
	graded *= 1.0-vignette*rim;
	// Protect highlights and readability, no blur, no flashing/noise.
	COLOR = vec4(clamp(mix(src,graded,strength),0.0,1.0),1.0);
}
