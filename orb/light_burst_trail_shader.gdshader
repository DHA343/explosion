shader_type canvas_item;
render_mode blend_add, unshaded;

instance uniform float trail_width = 32.0;
uniform vec4 color : source_color = vec4(1.0);
uniform float edge_softness = 0.2;
uniform float fade_power = 1.5;

void vertex() {
	VERTEX.x *= trail_width;
}

void fragment() {
	float cross_distance = abs(UV.x * 2.0 - 1.0);
	float edge = 1.0 - smoothstep(1.0 - edge_softness, 1.0, cross_distance);
	float fade = pow(1.0 - UV.y, fade_power);
	COLOR = vec4(color.rgb, color.a * edge * fade);
}
