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

float rand_from_seed(inout uint seed) {
	int k;
	int state = int(seed);
	if (state == 0) {
		state = 305420679;
	}

	k = state / 127773;
	state = 16807 * (state - k * 127773) - 2836 * k;
	if (state < 0) {
		state += 2147483647;
	}

	seed = uint(state);
	return float(seed % uint(65536)) / 65535.0;
}

uint hash(uint value) {
	value = ((value >> uint(16)) ^ value) * uint(73244475);
	value = ((value >> uint(16)) ^ value) * uint(73244475);
	value = (value >> uint(16)) ^ value;
	return value;
}

vec3 direction_from_randoms(float vertical_random, float azimuth_random) {
	float vertical = vertical_random * 2.0 - 1.0;
	float azimuth = azimuth_random * TAU;
	float horizontal = sqrt(max(1.0 - vertical * vertical, 0.0));
	return vec3(cos(azimuth) * horizontal, vertical, sin(azimuth) * horizontal);
}

void process() {
	if (RESTART) {
		uint particle_seed = hash(NUMBER + uint(1) + RANDOM_SEED);
		float spawn_random = rand_from_seed(particle_seed);
		float vertical_random = rand_from_seed(particle_seed);
		float azimuth_random = rand_from_seed(particle_seed);
		float spawn_ratio = mix(spawn_radius_min_ratio, spawn_radius_max_ratio, spawn_random);

		CUSTOM = vec4(orb_radius * spawn_ratio, vertical_random, 0.0, azimuth_random);
		TRANSFORM = mat4(1.0);
		TRANSFORM[3].xyz = direction_from_randoms(CUSTOM.y, CUSTOM.w) * CUSTOM.x;
	}

	CUSTOM.z += DELTA;
	vec3 direction = direction_from_randoms(CUSTOM.y, CUSTOM.w);
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

	uint size_seed = hash(NUMBER + uint(1) + RANDOM_SEED);
	float size_random = rand_from_seed(size_seed);
	float size_offset = (size_random * 2.0 - 1.0) * size_variation;
	float particle_size = max(size + size_offset, 0.0) * mix(1.0, 0.1, absorb_progress);
	float particle_alpha = 1.0 - absorb_progress;

	TRANSFORM[0].xyz = vec3(particle_size, 0.0, 0.0);
	TRANSFORM[1].xyz = vec3(0.0, particle_size, 0.0);
	TRANSFORM[2].xyz = vec3(0.0, 0.0, particle_size);
	TRANSFORM[3].xyz = direction * current_radius;
	COLOR = vec4(1.0, 1.0, 1.0, particle_alpha);
}
