shader_type spatial;

render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform vec4 body_color : source_color = vec4(0.10, 0.58, 1.0, 1.0);
uniform vec4 hot_core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float body_emission : hint_range(0.0, 8.0, 0.1) = 3.4;
uniform float hot_core_emission : hint_range(0.0, 10.0, 0.1) = 3.8;
uniform float edge_instability : hint_range(0.0, 0.3, 0.01) = 0.08;


void fragment() {
	float transverse = abs(UV.y * 2.0 - 1.0);
	float detail = sin(UV.x * 91.0 + COLOR.b * 47.0 + TIME * 31.0);
	detail += sin(UV.x * 173.0 - COLOR.b * 29.0 - TIME * 23.0) * 0.5;
	float disturbed_edge = transverse + detail * edge_instability * transverse;
	float body_mask = exp(-pow(disturbed_edge / 0.68, 2.0) * 1.5);
	body_mask *= 1.0 - smoothstep(0.82, 1.02, disturbed_edge);
	float core_ratio = clamp(COLOR.g, 0.55, 0.70);
	float core_mask = 1.0 - smoothstep(core_ratio * 0.18, core_ratio, transverse);
	float tip_phase = clamp((UV.x - 0.91) / 0.09, 0.0, 1.0);
	float cap_width = max(sqrt(max(1.0 - tip_phase * tip_phase, 0.0)), 0.001);
	float tip_mask = 1.0 - smoothstep(max(cap_width - 0.2, 0.0), cap_width, transverse);
	body_mask *= tip_mask;
	core_mask *= tip_mask;
	float longitudinal_pulse = mix(0.86, 1.08,
		0.5 + 0.5 * sin(UV.x * 43.0 - TIME * 28.0 + COLOR.b * 17.0));
	body_mask *= longitudinal_pulse;
	core_mask *= mix(0.92, 1.08, longitudinal_pulse);

	float white_center = pow(core_mask, 2.2);
	vec3 core_tint = mix(body_color.rgb, hot_core_color.rgb, white_center);
	vec3 body_energy = body_color.rgb * body_mask * body_emission;
	vec3 core_energy = core_tint * core_mask * hot_core_emission;
	ALBEDO = body_color.rgb * body_mask * 0.18 + core_tint * core_mask * 0.34;
	EMISSION = (body_energy + core_energy) * COLOR.r;
	ALPHA = clamp((body_mask * 0.64 + core_mask * 0.26) * COLOR.a, 0.0, 0.86);
}
