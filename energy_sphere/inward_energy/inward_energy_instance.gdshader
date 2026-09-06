shader_type spatial;
render_mode unshaded, cull_back, blend_mix, depth_draw_never;

uniform float intensity : hint_range(0.0, 8.0, 0.1) = 1.0;
uniform float edge_softness : hint_range(0.01, 1.0, 0.01) = 0.5;
instance uniform float peak_position_ratio : hint_range(0.05, 0.95) = 0.67;
instance uniform float roundness_power : hint_range(1.0, 8.0) = 2.0;
instance uniform float despawn_radius_ratio : hint_range(0.0, 1.0) = 0.18;

const float MIN_LENGTH = 0.0001;
const float PROFILE_SAMPLE_STEP = 0.001;

varying float instance_alpha;


float profile_radius(float longitudinal, float peak_position) {
	float side_t = 0.0;
	if (longitudinal < peak_position) {
		side_t = 1.0 - longitudinal / peak_position;
	} else {
		side_t = (longitudinal - peak_position) / (1.0 - peak_position);
	}
	return pow(
		max(1.0 - pow(clamp(side_t, 0.0, 1.0), roundness_power), 0.0),
		1.0 / roundness_power
	);
}


float profile_radius_rate(float longitudinal, float peak_position) {
	float lower = max(longitudinal - PROFILE_SAMPLE_STEP, 0.0);
	float upper = min(longitudinal + PROFILE_SAMPLE_STEP, 1.0);
	return (
		profile_radius(upper, peak_position) - profile_radius(lower, peak_position)
		) / max(upper - lower, MIN_LENGTH);
}


void vertex() {
	vec4 instance_data = INSTANCE_CUSTOM;
	float sphere_radius = max(length(MODEL_MATRIX[1].xyz), MIN_LENGTH);
	float movement_t = instance_data.r;
	float spawn_radius_ratio = length(MODEL_MATRIX[3].xyz) / sphere_radius;
	float current_radius_ratio = mix(
		spawn_radius_ratio,
		despawn_radius_ratio,
		movement_t
	);
	float current_offset = current_radius_ratio - spawn_radius_ratio;
	float current_length = min(instance_data.b / sphere_radius, 1.0);
	float longitudinal = UV.y;
	float axial_position = current_offset - current_length * longitudinal;

	float angle = UV.x * PI * 2.0;
	vec2 radial_direction = vec2(cos(angle), sin(angle));
	float profile_value = profile_radius(longitudinal, peak_position_ratio);
	float profile_rate = profile_radius_rate(longitudinal, peak_position_ratio);
	float radius = instance_data.g * 0.5;
	float axial_rate = -current_length;
	VERTEX = vec3(
		radial_direction.x * radius * profile_value,
		axial_position,
		radial_direction.y * radius * profile_value
	);
	vec3 profile_normal = vec3(
		radial_direction.x * axial_rate,
		-radius * profile_rate,
		radial_direction.y * axial_rate
	);
	if (length(profile_normal) > MIN_LENGTH) {
		NORMAL = normalize(profile_normal);
	} else {
		NORMAL = vec3(radial_direction.x, 0.0, radial_direction.y);
	}
	instance_alpha = 1.0;
}


void fragment() {
	float facing = max(dot(normalize(NORMAL), normalize(VIEW)), 0.0);
	float edge_alpha = smoothstep(0.0, edge_softness, facing);
	ALBEDO = vec3(intensity);
	ALPHA = instance_alpha * edge_alpha;
}
