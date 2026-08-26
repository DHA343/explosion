shader_type particles;

const float TAU_VALUE = 6.28318530718;

group_uniforms Motion;
uniform float radius : hint_range(1.0, 2000.0, 1.0) = 500.0;
uniform float deceleration : hint_range(1.0, 8.0, 0.01) = 3.0;
uniform float camera_distance : hint_range(1.0, 5000.0, 1.0) = 600.0;

group_uniforms Trail;
uniform float trail_ratio : hint_range(0.0, 1.0, 0.01) = 0.12;
uniform float catchup_start : hint_range(0.0, 1.0, 0.01) = 0.80;
uniform float catchup_end : hint_range(0.0, 1.0, 0.01) = 0.98;
uniform float catchup_power : hint_range(0.1, 8.0, 0.1) = 2.0;
uniform float final_trail_ratio : hint_range(0.0, 1.0, 0.01) = 0.20;

group_uniforms Shape;
uniform float particle_width : hint_range(1.0, 200.0, 1.0) = 80.0;
uniform float head_width_scale : hint_range(0.0, 3.0, 0.01) = 1.0;
uniform float tail_width_scale : hint_range(0.0, 3.0, 0.01) = 1.0;

group_uniforms Spawn;
uniform float spawn_width_end : hint_range(0.0, 0.5, 0.01) = 0.20;

group_uniforms DepthSize;
uniform float size_perspective_strength : hint_range(0.0, 1.0, 0.01) = 0.25;
uniform float depth_size_start : hint_range(0.0, 1.0, 0.01) = 0.10;
uniform float depth_size_end : hint_range(0.0, 1.0, 0.01) = 0.30;

group_uniforms;


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


float distance_at(float t) {
	float clamped_t = clamp(t, 0.0, 1.0);
	float remaining = 1.0 - clamped_t;

	return radius * (
		1.0 - pow(remaining, deceleration)
	);
}


vec3 position_3d_at(float t, vec3 direction) {
	return direction * distance_at(t);
}


float perspective_at(vec3 position_3d) {
	float depth = max(
		camera_distance - position_3d.z,
		0.0001
	);

	return camera_distance / depth;
}


vec2 project_to_2d(vec3 position_3d) {
	float perspective = perspective_at(position_3d);

	return position_3d.xy * perspective;
}


float size_perspective_at(vec3 position_3d) {
	float perspective = perspective_at(position_3d);

	return pow(
		perspective,
		size_perspective_strength
	);
}


void process() {
	if (RESTART) {
		CUSTOM.w = 0.0;
	} else {
		CUSTOM.w = min(
			CUSTOM.w + DELTA / LIFETIME,
			1.0
		);
	}

	float t = CUSTOM.w;

	uint seed = RANDOM_SEED + NUMBER * 747796405u;
	vec3 direction = random_sphere_direction(seed);

	float tail_t = max(
		t - trail_ratio,
		0.0
	);

	vec3 head_3d = position_3d_at(
		t,
		direction
	);

	vec3 raw_tail_3d = position_3d_at(
		tail_t,
		direction
	);

	vec2 head = project_to_2d(head_3d);
	vec2 raw_tail = project_to_2d(raw_tail_3d);

	float head_size_perspective =
		size_perspective_at(head_3d);

	float raw_tail_size_perspective =
		size_perspective_at(raw_tail_3d);

	float progress = distance_at(t) / radius;

	float catchup_end_value = max(
		catchup_end,
		catchup_start + 0.0001
	);

	float catchup = smoothstep(
		catchup_start,
		catchup_end_value,
		progress
	);

	catchup = pow(
		catchup,
		catchup_power
	);

	float trail_length_ratio = mix(
		1.0,
		final_trail_ratio,
		catchup
	);

	vec2 tail = mix(
		head,
		raw_tail,
		trail_length_ratio
	);

	float tail_size_perspective = mix(
		head_size_perspective,
		raw_tail_size_perspective,
		trail_length_ratio
	);

	float spawn_end = max(
		spawn_width_end,
		0.0001
	);

	float spawn_width_factor = smoothstep(
		0.0,
		spawn_end,
		t
	);

	float depth_end = max(
		depth_size_end,
		depth_size_start + 0.0001
	);

	float depth_size_factor = smoothstep(
		depth_size_start,
		depth_end,
		t
	);

	float head_depth_scale = mix(
		1.0,
		head_size_perspective,
		depth_size_factor
	);

	float tail_depth_scale = mix(
		1.0,
		tail_size_perspective,
		depth_size_factor
	);

	float head_width =
		particle_width
		* head_width_scale
		* spawn_width_factor
		* head_depth_scale;

	float tail_width =
		particle_width
		* tail_width_scale
		* spawn_width_factor
		* tail_depth_scale;

	vec2 segment = head - tail;
	float segment_length = length(segment);

	vec2 axis_x = vec2(1.0, 0.0);

	if (segment_length > 0.0001) {
		axis_x = segment / segment_length;
	}

	vec2 axis_y = vec2(
		-axis_x.y,
		axis_x.x
	);

	float head_radius = head_width * 0.5;
	float tail_radius = tail_width * 0.5;

	float quad_length =
		segment_length
		+ tail_radius
		+ head_radius;

	float center_offset =
		(head_radius - tail_radius)
		* 0.5;

	vec2 center =
		(head + tail) * 0.5
		+ axis_x * center_offset;

	TRANSFORM[0] = vec4(
		axis_x.x,
		axis_x.y,
		0.0,
		0.0
	);

	TRANSFORM[1] = vec4(
		axis_y.x,
		axis_y.y,
		0.0,
		0.0
	);

	TRANSFORM[2] = vec4(
		0.0,
		0.0,
		1.0,
		0.0
	);

	TRANSFORM[3] = vec4(
		center.x,
		center.y,
		0.0,
		1.0
	);

	CUSTOM.x = quad_length;
	CUSTOM.y = tail_width;
	CUSTOM.z = head_width;

	VELOCITY = vec3(0.0);
}
