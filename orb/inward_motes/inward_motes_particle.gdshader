shader_type particles;
render_mode disable_force, disable_velocity;

uniform float orb_radius : hint_range(0.1, 3.0, 0.01) = 0.5;
uniform float spawn_radius_min_ratio : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float spawn_radius_max_ratio : hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float acceleration_exponent : hint_range(0.1, 5.0, 0.1) = 1.8;
uniform float absorb_start_ratio : hint_range(0.0, 1.0, 0.01) = 0.18;
uniform float absorb_end_ratio : hint_range(0.0, 1.0, 0.01) = 0.04;
uniform float size : hint_range(0.005, 0.3, 0.005) = 0.06;
uniform float size_variation : hint_range(0.0, 0.1, 0.005) = 0.015;

float hash_value(float value) {
	return fract(sin(value * 12.9898 + 78.233) * 43758.5453);
}

vec3 direction_from_seed(float seed) {
	float vertical = hash_value(seed * 101.3 + 1.73) * 2.0 - 1.0;
	float azimuth = hash_value(seed * 173.9 + 3.19) * TAU;
	float horizontal = sqrt(max(1.0 - vertical * vertical, 0.0));
	return vec3(cos(azimuth) * horizontal, vertical, sin(azimuth) * horizontal);
}

void process() {
	if (RESTART) {
		float random_base = float(INDEX) * 17.371 + float(NUMBER) * 0.173;
		float particle_seed = hash_value(random_base + 0.37);
		float spawn_random = hash_value(random_base + 5.41);
		float spawn_ratio = mix(spawn_radius_min_ratio, spawn_radius_max_ratio, spawn_random);

		CUSTOM = vec4(orb_radius * spawn_ratio, particle_seed, 0.0, 0.0);
		TRANSFORM = mat4(1.0);
		TRANSFORM[3].xyz = direction_from_seed(CUSTOM.y) * CUSTOM.x;
	}

	CUSTOM.z += DELTA;
	vec3 direction = direction_from_seed(CUSTOM.y);
	float progress = clamp(CUSTOM.z / LIFETIME, 0.0, 1.0);
	float move_progress = pow(progress, acceleration_exponent);
	float current_radius = mix(CUSTOM.x, 0.0, move_progress);
	float absorb_start_radius = orb_radius * absorb_start_ratio;
	float absorb_end_radius = orb_radius * absorb_end_ratio;
	float absorb_range = max(absorb_start_radius - absorb_end_radius, 0.0001);
	float absorb_progress = clamp(
		(absorb_start_radius - current_radius) / absorb_range,
		0.0,
		1.0
	);
	absorb_progress = smoothstep(0.0, 1.0, absorb_progress);

	float size_offset = (hash_value(CUSTOM.y * 41.17) * 2.0 - 1.0) * size_variation;
	float particle_size = max(size + size_offset, 0.0) * mix(1.0, 0.1, absorb_progress);
	float particle_alpha = 1.0 - absorb_progress;

	TRANSFORM[0].xyz = vec3(particle_size, 0.0, 0.0);
	TRANSFORM[1].xyz = vec3(0.0, particle_size, 0.0);
	TRANSFORM[2].xyz = vec3(0.0, 0.0, particle_size);
	TRANSFORM[3].xyz = direction * current_radius;
	COLOR = vec4(1.0, 1.0, 1.0, particle_alpha);
}
