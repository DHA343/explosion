shader_type spatial;

render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform vec4 edge_color : source_color = vec4(0.30, 0.75, 1.0, 1.0);
uniform vec4 contact_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 shell_mix_color : source_color = vec4(1.0, 0.35, 0.85, 1.0);
uniform float edge_emission : hint_range(0.0, 10.0, 0.1) = 3.2;
uniform float core_emission : hint_range(0.0, 12.0, 0.1) = 5.4;


void fragment() {
	vec2 centered_uv = (UV - vec2(0.5)) * 2.0;
	float distance_from_center = length(centered_uv);
	float irregularity = sin(atan(centered_uv.y, centered_uv.x) * 7.0
		+ COLOR.b * 31.0 + TIME * 19.0) * 0.06;
	float edge_mask = 1.0 - smoothstep(0.48, 1.0, distance_from_center + irregularity);
	float core_mask = 1.0 - smoothstep(0.08, 0.48, distance_from_center);
	vec3 local_edge_color = mix(edge_color.rgb, shell_mix_color.rgb, COLOR.g);
	ALBEDO = local_edge_color * edge_mask * 0.4 + contact_color.rgb * core_mask * 0.6;
	EMISSION = (local_edge_color * edge_mask * edge_emission
		+ contact_color.rgb * core_mask * core_emission) * COLOR.r;
	ALPHA = clamp((edge_mask * 0.56 + core_mask * 0.44) * COLOR.a, 0.0, 0.9);
}
