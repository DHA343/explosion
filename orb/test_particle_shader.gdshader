shader_type particles;

const float TAU_VALUE = 6.28318530718;

uniform float radius : hint_range(1.0, 2000.0, 1.0) = 500.0;
uniform float deceleration : hint_range(1.0, 8.0, 0.01) = 3.0;
uniform float camera_distance : hint_range(1.0, 5000.0, 1.0) = 900.0;
uniform float base_scale : hint_range(0.01, 10.0, 0.01) = 1.0;


uint hash_u32(uint x) {
	x ^= x >> 16u;
	x *= 2246822519u;
	x ^= x >> 13u;
	x *= 3266489917u;
	x ^= x >> 16u;
	return x;
}


float rand01(uint seed) {
	return float(hash_u32(seed)) / 4294967295.0;
}


vec3 random_sphere_direction(uint seed) {
	float z = rand01(seed) * 2.0 - 1.0;
	float angle = rand01(seed + 1u) * TAU_VALUE;
	float xy = sqrt(max(0.0, 1.0 - z * z));

	return vec3(
		cos(angle) * xy,
		sin(angle) * xy,
		z
	);
}


void process() {
	if (RESTART) {
		CUSTOM.x = 0.0;
	} else {
		CUSTOM.x = min(
			CUSTOM.x + DELTA / LIFETIME,
			1.0
		);
	}

	float t = CUSTOM.x;

	uint seed = RANDOM_SEED + NUMBER * 747796405u;
	vec3 direction = random_sphere_direction(seed);

	float remaining = 1.0 - t;

	float distance = radius * (
		1.0 - pow(remaining, deceleration)
	);

	float speed = (
		radius
		* deceleration
		/ LIFETIME
		* pow(remaining, deceleration - 1.0)
	);

	vec3 position_3d = direction * distance;
	vec3 velocity_3d = direction * speed;

	float depth = camera_distance - position_3d.z;
	float perspective = camera_distance / depth;

	vec2 position_2d = position_3d.xy * perspective;

	float perspective_velocity = (
		camera_distance
		* velocity_3d.z
		/ (depth * depth)
	);

	vec2 velocity_2d = (
		velocity_3d.xy * perspective
		+ position_3d.xy * perspective_velocity
	);

	float scale = base_scale * perspective;

	TRANSFORM[0].xy = vec2(scale, 0.0);
	TRANSFORM[1].xy = vec2(0.0, scale);
	TRANSFORM[3].xy = position_2d;

	VELOCITY = vec3(velocity_2d, 0.0);
}