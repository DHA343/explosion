uniform sampler3D aura_flow_noise;

const uint AURA_FLOW_SALT = 0x51f15e5du;
const uint AURA_SOURCE_SALT = 0x6a09e667u;


uint aura_hash_u32(uint value) {
	value = ((value >> 16u) ^ value) * 0x45d9f3bu;
	value = ((value >> 16u) ^ value) * 0x45d9f3bu;
	return (value >> 16u) ^ value;
}


float aura_hash01(uint value) {
	return float(aura_hash_u32(value)) / 4294967295.0;
}


vec3 aura_seed_offset(uint seed_value, uint salt_value) {
	return vec3(
		aura_hash01(seed_value ^ salt_value ^ 0x243f6a88u),
		aura_hash01(seed_value ^ salt_value ^ 0x85a308d3u),
		aura_hash01(seed_value ^ salt_value ^ 0x13198a2eu)
	);
}


vec3 aura_time_offset(float time, float speed) {
	float phase = time * speed;
	return vec3(
		sin(phase * 0.71) * 0.18 + cos(phase * 0.23) * 0.11,
		cos(phase * 0.53) * 0.17 + sin(phase * 0.37) * 0.09,
		sin(phase * 0.43) * 0.16 + cos(phase * 0.67) * 0.10
	);
}


float aura_noise_scalar(vec3 normalized_position, float time, uint seed_value, float scale, float speed) {
	vec3 sample_position = fract(
		normalized_position * scale * 0.31
		+ aura_seed_offset(seed_value, AURA_SOURCE_SALT)
		+ aura_time_offset(time, speed)
	);
	return texture(aura_flow_noise, sample_position).r;
}


float sample_shape_field(
	vec3 source_direction,
	float emission_time,
	uint shape_seed,
	float shape_scale,
	float shape_speed
) {
	float shape_noise = aura_noise_scalar(
		normalize(source_direction),
		emission_time,
		shape_seed,
		max(shape_scale, 0.01),
		shape_speed
	);
	return smoothstep(0.18, 0.82, shape_noise);
}


vec3 aura_noise_vector(vec3 normalized_position, float time, uint seed_value, float scale, float speed) {
	vec3 sample_position = fract(
		normalized_position * scale * 0.31
		+ aura_seed_offset(seed_value, AURA_FLOW_SALT)
		+ aura_time_offset(time, speed)
	);
	float noise_x = texture(aura_flow_noise, fract(sample_position + vec3(0.13, 0.37, 0.59))).r;
	float noise_y = texture(aura_flow_noise, fract(sample_position + vec3(0.47, 0.71, 0.23))).r;
	float noise_z = texture(aura_flow_noise, fract(sample_position + vec3(0.83, 0.19, 0.41))).r;
	return vec3(noise_x, noise_y, noise_z) * 2.0 - 1.0;
}


vec3 sample_base_flow(
	vec3 position_local,
	float sphere_radius,
	float time,
	uint flow_seed,
	float radial_speed,
	float radial_variation,
	float tangential_strength,
	float flow_scale,
	float flow_speed
) {
	float safe_radius = max(sphere_radius, 0.0001);
	vec3 normalized_position = position_local / safe_radius;
	float distance_from_center = length(position_local);
	vec3 radial_direction = distance_from_center > 0.0001
		? position_local / distance_from_center
		: vec3(0.0, 1.0, 0.0);
	vec3 noise_vector = aura_noise_vector(
		normalized_position,
		time,
		flow_seed,
		flow_scale,
		flow_speed
	);
	vec3 tangent = noise_vector - radial_direction * dot(noise_vector, radial_direction);
	float radial_noise = aura_noise_scalar(
		normalized_position + vec3(0.31, 0.17, 0.43),
		time,
		flow_seed,
		flow_scale * 0.72,
		flow_speed * 0.83
	);
	float radial_factor = mix(1.0 - radial_variation, 1.0 + radial_variation, radial_noise);
	return safe_radius * (
		radial_direction * radial_speed * radial_factor
		+ tangent * tangential_strength
	);
}


float sample_source_strength(
	vec3 source_direction,
	float emission_time,
	uint source_seed,
	float source_scale,
	float source_speed,
	float source_min_strength
) {
	float source_noise = aura_noise_scalar(
		normalize(source_direction),
		emission_time,
		source_seed,
		source_scale,
		source_speed
	);
	source_noise = smoothstep(0.14, 0.86, source_noise);
	return mix(source_min_strength, 1.0, source_noise);
}
