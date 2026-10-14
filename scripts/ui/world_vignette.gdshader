shader_type canvas_item;
render_mode unshaded;
void fragment() {
	vec2 point = UV * 2.0 - 1.0;
	float falloff = smoothstep(0.35, 1.35, length(point * vec2(0.85, 1.0)));
	COLOR = vec4(0.025, 0.06, 0.045, falloff * 0.45);
}
