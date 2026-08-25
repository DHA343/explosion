shader_type particles;

uniform float speed_decay_power : hint_range(1.0, 8.0, 0.01) = 2.5;
uniform float depth_strength : hint_range(0.0, 1.0, 0.01) = 0.3;
uniform float sphere_radius = 450.0;
uniform float particle_size = 128.0;
uniform float trail_duration : hint_range(0.01, 1.0, 0.01) = 0.1;

float random_from_seed(inout uint seed) {
	int k;
	int value = int(seed);
	if (value == 0) {
		value = 305420679;
	}
	k = value / 127773;
	value = 16807 * (value - k * 127773) - 2836 * k;
	if (value < 0) {
		value += 2147483647;
	}
	seed = uint(value);
	return float(seed % uint(65536)) / 65535.0;
}

uint hash_seed(uint value) {
	value = ((value >> uint(16)) ^ value) * uint(73244475);
	value = ((value >> uint(16)) ^ value) * uint(73244475);
	return (value >> uint(16)) ^ value;
}

float motion_progress_at(float age) {
	return 1.0 - pow(1.0 - clamp(age, 0.0, 1.0), speed_decay_power);
}

float distance_at(float age) {
	return motion_progress_at(age) * sphere_radius;
}

void start() {
	uint seed = hash_seed(NUMBER + uint(1) + RANDOM_SEED);
	float theta = random_from_seed(seed) * TAU;
	float depth = random_from_seed(seed) * 2.0 - 1.0;
	float planar_length = sqrt(1.0 - depth * depth);
	vec3 forward = vec3(cos(theta), sin(theta), 0.0);
	vec3 side = vec3(-sin(theta), cos(theta), 0.0);

	if (RESTART_POSITION) {
		TRANSFORM = mat4(vec4(1.0, 0.0, 0.0, 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
		if (RESTART_VELOCITY) {
			VELOCITY = (EMISSION_TRANSFORM * vec4(VELOCITY, 0.0)).xyz;
		}
		TRANSFORM = EMISSION_TRANSFORM * TRANSFORM;
	}

	TRANSFORM *= mat4(vec4(forward, 0.0), vec4(side, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	CUSTOM = vec4(theta, depth, 0.0, 0.0);
}

void process() {
	float theta = CUSTOM.x;
	float depth = CUSTOM.y;
	float age = min(CUSTOM.z + DELTA / LIFETIME, 1.0);
	float planar_length = sqrt(1.0 - depth * depth);
	float current_distance = distance_at(age);
	float previous_age = max(age - trail_duration / LIFETIME, 0.0);
	float previous_distance = distance_at(previous_age);
	float depth_scale = 1.0 + depth * motion_progress_at(age) * depth_strength;
	vec3 direction = vec3(cos(theta) * planar_length, sin(theta) * planar_length, depth);
	vec3 forward = normalize(TRANSFORM[0].xyz);
	vec3 side = normalize(TRANSFORM[1].xyz);

	TRANSFORM[1].xyz = side * depth_scale;
	TRANSFORM[3].xyz = direction * current_distance;
	float trail_length = (current_distance - previous_distance) / depth_scale;
	TRANSFORM[0].xyz = forward * depth_scale * (1.0 + trail_length / particle_size);
	CUSTOM = vec4(theta, depth, age, 0.0);
}
