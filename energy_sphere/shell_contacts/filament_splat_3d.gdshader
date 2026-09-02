shader_type spatial;

render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform vec4 body_color : source_color = vec4(0.10, 0.58, 1.0, 1.0);
uniform vec4 hot_core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float body_emission : hint_range(0.0, 4.0, 0.05) = 2.2;
uniform float hot_core_emission : hint_range(0.0, 5.0, 0.05) = 1.2;
uniform float body_sharpness : hint_range(0.5, 8.0, 0.1) = 1.4;
uniform float core_sharpness : hint_range(0.5, 8.0, 0.1) = 0.8;


void fragment() {
	vec2 splat_position = UV * 2.0 - 1.0;
	float angle = atan(splat_position.y, splat_position.x);
	float instability = sin(angle * 7.0 + COLOR.b * 37.0 + TIME * 23.0) * 0.015;
	float radial_distance = length(splat_position) + instability;
	float edge_clip = 1.0 - smoothstep(0.82, 1.0, radial_distance);
	float body_mask = exp(-radial_distance * radial_distance * body_sharpness) * edge_clip;
	float core_ratio = clamp(COLOR.g, 0.55, 0.70);
	float core_distance = radial_distance / core_ratio;
	float core_mask = exp(-core_distance * core_distance * core_sharpness) * edge_clip;
	float white_center = pow(core_mask, 0.65);
	vec3 core_tint = mix(body_color.rgb, hot_core_color.rgb, white_center);

	ALBEDO = body_color.rgb * body_mask * 0.16 + core_tint * core_mask * 0.24;
	EMISSION = (body_color.rgb * body_mask * body_emission
		+ core_tint * core_mask * hot_core_emission) * COLOR.r;
	ALPHA = clamp((body_mask * 0.35 + core_mask * 0.1) * COLOR.a, 0.0, 0.45);
}
