shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 ground_color : source_color = vec4(0.002, 0.012, 0.026, 1.0);
uniform vec4 minor_grid_color : source_color = vec4(0.025, 0.075, 0.12, 1.0);
uniform vec4 major_grid_color : source_color = vec4(0.055, 0.14, 0.2, 1.0);
uniform float minor_grid_size : hint_range(1.0, 50.0, 1.0) = 10.0;
uniform float major_grid_size : hint_range(10.0, 200.0, 5.0) = 50.0;

varying vec3 world_position;

float grid_line(vec2 position, float cell_size, float line_width) {
	vec2 coordinate = position / cell_size;
	vec2 derivative_width = max(fwidth(coordinate) * line_width, vec2(0.00001));
	vec2 distance_to_line = abs(fract(coordinate - 0.5) - 0.5) / derivative_width;
	return 1.0 - min(min(distance_to_line.x, distance_to_line.y), 1.0);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float minor_grid = grid_line(world_position.xz, minor_grid_size, 0.8);
	float major_grid = grid_line(world_position.xz, major_grid_size, 1.1);
	vec3 color = mix(ground_color.rgb, minor_grid_color.rgb, minor_grid * 0.34);
	color = mix(color, major_grid_color.rgb, major_grid * 0.58);

	ALBEDO = color;
	ROUGHNESS = 0.82;
	METALLIC = 0.08;
	EMISSION = (
		ground_color.rgb * 0.8
		+ minor_grid_color.rgb * minor_grid * 0.08
		+ major_grid_color.rgb * major_grid * 0.18
	);
}
