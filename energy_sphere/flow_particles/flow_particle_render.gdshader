shader_type spatial;

render_mode unshaded, blend_premul_alpha, cull_disabled, depth_draw_never;

uniform vec3 cluster_center_world = vec3(0.0);
uniform vec3 cluster_radial_world = vec3(0.0, 1.0, 0.0);
uniform float sphere_radius = 0.5;
uniform float actual_plume_length = 0.225;
uniform float cluster_brightness_multiplier = 1.0;
uniform float pulse_phase = 0.0;
uniform float cluster_pulse_amount = 0.10;
uniform float cluster_pulse_speed = 1.2;
uniform float cluster_alpha = 1.0;
uniform float silhouette_width = 0.65;
uniform float front_back_opacity = 0.08;
uniform float opacity = 0.60;
uniform float emission_strength = 2.2;

varying vec4 particle_custom;

void vertex() {
	particle_custom = INSTANCE_CUSTOM;
}

void fragment() {
	vec2 centered_uv = UV * 2.0 - 1.0;
	float radial_distance = length(centered_uv);
	float particle_mask = 1.0 - smoothstep(0.45, 1.0, radial_distance);

	vec3 particle_center_world = MODEL_MATRIX[3].xyz;
	float height_world = dot(particle_center_world - cluster_center_world, cluster_radial_world);
	float height_ratio = height_world / max(actual_plume_length, 0.0001);
	float plume_fade = 1.0 - smoothstep(0.55, 1.25, height_ratio);

	vec3 view_direction = normalize(CAMERA_POSITION_WORLD - particle_center_world);
	float view_dot = abs(dot(normalize(cluster_radial_world), view_direction));
	float silhouette = 1.0 - smoothstep(0.0, silhouette_width, view_dot);
	float view_weight = mix(front_back_opacity, 1.0, silhouette);

	float particle_age = particle_custom.x;
	float personal_lifetime = max(particle_custom.y, 0.0001);
	float age_normalized = particle_age / personal_lifetime;
	float particle_lifetime_fade = smoothstep(0.0, 0.08, age_normalized)
		* (1.0 - smoothstep(0.70, 1.0, age_normalized));

	float wave = sin(TIME * cluster_pulse_speed + pulse_phase) * 0.65
		+ sin(TIME * cluster_pulse_speed * 1.73 + pulse_phase * 1.37) * 0.35;
	float pulse = 1.0 + wave * cluster_pulse_amount;
	vec3 final_color = COLOR.rgb * cluster_brightness_multiplier * pulse;
	float final_alpha = particle_mask * particle_lifetime_fade * plume_fade * view_weight
		* cluster_alpha * particle_custom.w * opacity;

	ALBEDO = final_color;
	EMISSION = final_color * emission_strength;
	ALPHA = final_alpha;
}
