shader_type particles;

uniform float sphere_radius = 0.5;
uniform float particle_lifetime = 1.8;
uniform float particle_size_min_ratio = 0.008;
uniform float particle_size_max_ratio = 0.016;
uniform float spawn_radius_min_ratio = 1.0;
uniform float spawn_radius_max_ratio = 1.04;
uniform float outward_speed = 0.16;
uniform float flow_strength = 0.55;
uniform float flow_scale = 0.85;
uniform float flow_speed = 0.22;
uniform float flow_normal_amount = 0.20;
uniform float turbulence_strength = 0.25;
uniform float turbulence_scale = 4.0;
uniform float turbulence_speed = 0.75;
uniform vec4 particle_color = vec4(0.20, 0.75, 1.0, 1.0);

const vec3 NOISE_OFFSET_X = vec3(17.1, 43.7, 11.8);
const vec3 NOISE_OFFSET_Y = vec3(29.6, 7.4, 53.2);
const vec3 NOISE_OFFSET_Z = vec3(61.3, 31.9, 19.5);


float hash_value(vec3 point) {
	return fract(sin(dot(point, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}


float noise3(vec3 point) {
	vec3 cell = floor(point);
	vec3 fraction = fract(point);
	vec3 smooth_fraction = fraction * fraction * (3.0 - 2.0 * fraction);
	float c000 = hash_value(cell);
	float c100 = hash_value(cell + vec3(1.0, 0.0, 0.0));
	float c010 = hash_value(cell + vec3(0.0, 1.0, 0.0));
	float c110 = hash_value(cell + vec3(1.0, 1.0, 0.0));
	float c001 = hash_value(cell + vec3(0.0, 0.0, 1.0));
	float c101 = hash_value(cell + vec3(1.0, 0.0, 1.0));
	float c011 = hash_value(cell + vec3(0.0, 1.0, 1.0));
	float c111 = hash_value(cell + vec3(1.0, 1.0, 1.0));
	float low_z = mix(mix(c000, c100, smooth_fraction.x), mix(c010, c110, smooth_fraction.x),
		smooth_fraction.y);
	float high_z = mix(mix(c001, c101, smooth_fraction.x), mix(c011, c111, smooth_fraction.x),
		smooth_fraction.y);
	return mix(low_z, high_z, smooth_fraction.z);
}


float random01(inout uint state) {
	state = state * 1664525u + 1013904223u;
	return float(state & 16777215u) / 16777215.0;
}


vec3 vector_noise(vec3 point) {
	return vec3(
		noise3(point + NOISE_OFFSET_X),
		noise3(point + NOISE_OFFSET_Y),
		noise3(point + NOISE_OFFSET_Z)
	) * 2.0 - 1.0;
}


void start() {
	uint random_state = RANDOM_SEED;
	float y = 1.0 - 2.0 * random01(random_state);
	float angle = TAU * random01(random_state);
	float horizontal = sqrt(max(1.0 - y * y, 0.0));
	vec3 radial = vec3(cos(angle) * horizontal, y, sin(angle) * horizontal);
	float spawn_ratio = mix(spawn_radius_min_ratio, spawn_radius_max_ratio,
		random01(random_state));
	float particle_size = sphere_radius * mix(particle_size_min_ratio,
		particle_size_max_ratio, random01(random_state));

	TRANSFORM = mat4(
		vec4(particle_size, 0.0, 0.0, 0.0),
		vec4(0.0, particle_size, 0.0, 0.0),
		vec4(0.0, 0.0, particle_size, 0.0),
		vec4(radial * sphere_radius * spawn_ratio, 1.0)
	);
	CUSTOM.x = 0.0;
	CUSTOM.y = mix(0.75, 1.25, random01(random_state));
	CUSTOM.z = mix(0.85, 1.15, random01(random_state));
	CUSTOM.w = mix(0.70, 1.00, random01(random_state));
	COLOR = particle_color;
}


void process() {
	CUSTOM.x += DELTA;
	if (CUSTOM.x >= particle_lifetime) {
		ACTIVE = false;
	} else {
		vec3 current_position = TRANSFORM[3].xyz;
		vec3 radial = normalize(current_position);
		vec3 normalized_position = current_position / max(sphere_radius, 0.0001);

		float flow_time = TIME * flow_speed;
		vec3 flow_position = normalized_position * flow_scale + vec3(
			flow_time * 0.71,
			-flow_time * 0.43,
			flow_time * 0.59
		);
		vec3 raw_flow = vector_noise(flow_position);
		float normal_component = dot(raw_flow, radial);
		vec3 large_flow = raw_flow - radial * normal_component
			+ radial * normal_component * flow_normal_amount;

		float turbulence_time = TIME * turbulence_speed;
		vec3 turbulence_position = normalized_position * turbulence_scale + vec3(
			-turbulence_time * 0.61,
			turbulence_time * 0.79,
			turbulence_time * 0.37
		);
		vec3 turbulence = vector_noise(turbulence_position);

		vec3 outward_velocity = radial * sphere_radius * outward_speed * CUSTOM.y;
		vec3 flow_velocity = large_flow * sphere_radius * flow_strength;
		vec3 turbulence_velocity = turbulence * sphere_radius * turbulence_strength;
		VELOCITY = (outward_velocity + flow_velocity + turbulence_velocity) * CUSTOM.z;
	}
}
