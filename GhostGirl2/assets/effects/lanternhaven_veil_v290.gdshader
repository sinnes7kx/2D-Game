shader_type canvas_item;
render_mode unshaded;
uniform float strength : hint_range(0.0,1.0) = 1.0;
void fragment() {
	vec2 p = (UV - vec2(0.5)) * vec2(1.0,0.82);
	float edge = smoothstep(0.29,0.59,length(p));
	float grain = fract(sin(dot(floor(FRAGCOORD.xy),vec2(12.9898,78.233)))*43758.5453);
	float shade = edge*0.095 + grain*0.009;
	COLOR = vec4(vec3(0.12,0.085,0.15),shade*strength);
}
