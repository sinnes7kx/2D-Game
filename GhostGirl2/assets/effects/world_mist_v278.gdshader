shader_type canvas_item;
render_mode unshaded;
uniform vec4 fog_ink : source_color = vec4(0.47,0.45,0.59,1.0);
uniform float density : hint_range(0.0,0.22) = 0.06;
uniform float layer_phase = 0.0;
uniform float drift = 5.0;
uniform float spatial_scale = 1.0;
varying vec2 world_at;

void vertex() {
	world_at = (MODEL_MATRIX * vec4(VERTEX,0.0,1.0)).xy;
}

void fragment() {
	// Slow continuous world-space fields. Camera motion never drags fog
	// with the screen, and there is no screen copy or texture noise sample.
	vec2 p = world_at * spatial_scale;
	float t = TIME * drift;
	float a = sin(p.x*0.006 + p.y*0.010 + t*0.012 + layer_phase);
	float b = sin(p.x*0.012 - p.y*0.006 - t*0.018 + a*1.1 + layer_phase*1.6);
	float c = sin(p.x*0.0025 + p.y*0.020 + t*0.008 + b*0.8);
	float field = 0.5 + 0.24*a + 0.17*b + 0.09*c;
	float veil = smoothstep(0.22,0.87,field);
	COLOR = vec4(fog_ink.rgb, density*veil*veil);
}
