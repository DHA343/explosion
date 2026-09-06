shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;

instance uniform float surface_radius : hint_range(0.01, 2.0, 0.001) = 0.5;
instance uniform float opacity : hint_range(0.0, 1.0, 0.01) = 0.5;
instance uniform float softness : hint_range(0.01, 1.0, 0.01) = 0.35;

varying float lifecycle_alpha;


void vertex() {
	float mark_size = INSTANCE_CUSTOM.r;
	float response_progress = INSTANCE_CUSTOM.g;
	float fade_progress = INSTANCE_CUSTOM.b;
	vec3 surface_sample = vec3(
		VERTEX.x * mark_size,
		surface_radius,
		VERTEX.z * mark_size
	);
	VERTEX = normalize(surface_sample) * surface_radius;
	NORMAL = normalize(VERTEX);

	float fade_in = smoothstep(0.0, 0.2, response_progress);
	float fade_out = 1.0 - smoothstep(0.0, 1.0, fade_progress);
	lifecycle_alpha = fade_in * fade_out;
}


void fragment() {
	float center_distance = length(UV - vec2(0.5)) * 2.0;
	float edge_start = clamp(1.0 - softness, 0.0, 0.999);
	float circle_alpha = 1.0 - smoothstep(edge_start, 1.0, center_distance);
	ALBEDO = vec3(1.0);
	ALPHA = opacity * lifecycle_alpha * circle_alpha;
}
