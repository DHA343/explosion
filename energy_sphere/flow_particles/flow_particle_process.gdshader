shader_type particles;

uniform float sphere_radius = 0.5;
uniform float plume_length = 0.225;
uniform float plume_width = 0.09;
uniform float plume_taper = 0.75;
uniform float plume_density_power = 2.0;
uniform float particle_lifetime_min = 1.0;
uniform float particle_lifetime_max = 2.0;
uniform float particle_size_min_ratio = 0.010;
uniform float particle_size_max_ratio = 0.020;
uniform float particle_brightness_variation = 0.12;
uniform float plume_outward_speed = 0.12;
uniform float plume_bend_strength = 0.16;
uniform float plume_bend_speed = 0.45;
uniform float particle_turbulence_strength = 0.22;
uniform float particle_turbulence_scale = 3.0;
uniform float particle_turbulence_speed = 0.65;
uniform float particle_radial_turbulence = 0.35;
uniform float plume_cohesion = 2.0;
uniform float cluster_seed = 343.0;
uniform vec4 cluster_color = vec4(0.54, 0.24, 1.0, 1.0);

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
	float c000 = hash_value(cell + vec3(0.0, 0.0, 0.0));
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

void start() {
	uint random_state = RANDOM_SEED;
	float height_random = random01(random_state);
	float height_ratio = pow(height_random, plume_density_power);
	float width_factor = max(1.0 - plume_taper * height_ratio, 0.05);
	float cross_radius = plume_width * width_factor;
	float angle = random01(random_state) * TAU;
	float disk_radius = sqrt(random01(random_state)) * cross_radius;
	float x_offset = cos(angle) * disk_radius;
	float z_offset = sin(angle) * disk_radius;
	float particle_size = sphere_radius * mix(particle_size_min_ratio,
		particle_size_max_ratio, random01(random_state));

	TRANSFORM = mat4(
		vec4(particle_size, 0.0, 0.0, 0.0),
		vec4(0.0, particle_size, 0.0, 0.0),
		vec4(0.0, 0.0, particle_size, 0.0),
		vec4(x_offset, height_ratio * plume_length, z_offset, 1.0)
	);
	CUSTOM.x = 0.0;
	CUSTOM.y = mix(particle_lifetime_min, particle_lifetime_max, random01(random_state));
	CUSTOM.z = mix(0.85, 1.15, random01(random_state));
	CUSTOM.w = mix(0.75, 1.0, random01(random_state));
	COLOR.rgb = cluster_color.rgb * mix(1.0 - particle_brightness_variation,
		1.0 + particle_brightness_variation, random01(random_state));
	COLOR.a = 1.0;
}

void process() {
	CUSTOM.x += DELTA;
	if (CUSTOM.x >= CUSTOM.y) {
		ACTIVE = false;
	} else {
		vec3 current_position = TRANSFORM[3].xyz;
		float height_ratio = clamp(current_position.y / max(plume_length, 0.0001), 0.0, 1.0);
		vec3 bend_time = vec3(TIME * plume_bend_speed * 0.71,
			-TIME * plume_bend_speed * 0.43, TIME * plume_bend_speed * 0.59);
		vec3 bend_position = vec3(cluster_seed * 0.017) + bend_time;
		float bend_x = noise3(bend_position + NOISE_OFFSET_X) * 2.0 - 1.0;
		float bend_z = noise3(bend_position + NOISE_OFFSET_Z) * 2.0 - 1.0;
		float bend_influence = smoothstep(0.15, 1.0, height_ratio);
		vec3 bend_velocity = vec3(bend_x, 0.0, bend_z) * sphere_radius * plume_bend_strength * bend_influence;

		vec3 turbulence_position = current_position / max(sphere_radius, 0.0001)
			* particle_turbulence_scale;
		vec3 turbulence_time = vec3(TIME * particle_turbulence_speed * 0.71,
			-TIME * particle_turbulence_speed * 0.43,
			TIME * particle_turbulence_speed * 0.59);
		vec3 turbulence_sample = turbulence_position + turbulence_time + vec3(cluster_seed * 0.031);
		vec3 turbulence = vec3(
			noise3(turbulence_sample + NOISE_OFFSET_X),
			noise3(turbulence_sample + NOISE_OFFSET_Y),
			noise3(turbulence_sample + NOISE_OFFSET_Z)
		) * 2.0 - 1.0;
		turbulence.y *= particle_radial_turbulence;
		vec3 turbulence_velocity = turbulence * sphere_radius * particle_turbulence_strength;

		float allowed_radius = plume_width * max(1.0 - plume_taper * height_ratio, 0.05);
		vec2 lateral = current_position.xz;
		float lateral_length = length(lateral);
		vec3 cohesion_velocity = vec3(0.0);
		if (lateral_length > allowed_radius) {
			cohesion_velocity.xz = -normalize(lateral) * (lateral_length - allowed_radius) * plume_cohesion;
		}

		vec3 outward_velocity = vec3(0.0, sphere_radius * plume_outward_speed, 0.0);
		VELOCITY = (outward_velocity + bend_velocity + turbulence_velocity + cohesion_velocity) * CUSTOM.z;
	}
}
