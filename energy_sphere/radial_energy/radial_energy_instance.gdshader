shader_type spatial;
render_mode unshaded, cull_back, blend_mix, depth_draw_never;

uniform float intensity : hint_range(0.0, 8.0, 0.1) = 1.0;
uniform float edge_softness : hint_range(0.01, 1.0, 0.01) = 0.5;
instance uniform float peak_position_ratio : hint_range(0.05, 0.95) = 0.67;
instance uniform float roundness_power : hint_range(1.0, 8.0) = 2.0;
instance uniform float deceleration_power : hint_range(1.0, 8.0) = 2.0;
instance uniform float length_shrink_start_ratio : hint_range(0.0, 0.99) = 0.72;
instance uniform float length_shrink_power : hint_range(1.0, 8.0) = 1.0;
instance uniform float thickness_shrink_start_ratio : hint_range(0.0, 0.99) = 0.60;
instance uniform float thickness_shrink_power : hint_range(1.0, 8.0) = 2.0;
instance uniform float fade_start_ratio : hint_range(0.0, 0.99) = 0.78;
instance uniform float fade_power : hint_range(1.0, 8.0) = 2.0;

const float MIN_LENGTH = 0.0001;
const float PROFILE_SAMPLE_STEP = 0.001;

varying float instance_strength;
varying float instance_alpha;

float effect_progress(float time_t, float start_ratio) {
	return clamp((time_t - start_ratio) / (1.0 - start_ratio), 0.0, 1.0);
}

float profile_radius(float longitudinal) {
	float side_t = 0.0;
	if (longitudinal < peak_position_ratio) {
		side_t = 1.0 - longitudinal / peak_position_ratio;
	} else {
		side_t = (longitudinal - peak_position_ratio) / (1.0 - peak_position_ratio);
	}
	return pow(
		max(1.0 - pow(clamp(side_t, 0.0, 1.0), roundness_power), 0.0),
		1.0 / roundness_power
	);
}

float profile_radius_rate(float longitudinal) {
	float lower = max(longitudinal - PROFILE_SAMPLE_STEP, 0.0);
	float upper = min(longitudinal + PROFILE_SAMPLE_STEP, 1.0);
	return (profile_radius(upper) - profile_radius(lower)) / max(upper - lower, MIN_LENGTH);
}

void vertex() {
	vec4 instance_data = INSTANCE_CUSTOM;
	float longitudinal = UV.y;
	float travel_radius = max(length(MODEL_MATRIX[1].xyz), MIN_LENGTH);
	float movement_t = 1.0 - pow(1.0 - instance_data.r, deceleration_power);
	float length_t = effect_progress(instance_data.r, length_shrink_start_ratio);
	float thickness_t = effect_progress(instance_data.r, thickness_shrink_start_ratio);
	float fade_t = effect_progress(instance_data.r, fade_start_ratio);
	float length_factor = 1.0 - pow(length_t, length_shrink_power);
	float thickness_factor = pow(1.0 - thickness_t, thickness_shrink_power);
	float fade_factor = 1.0 - pow(fade_t, fade_power);
	instance_strength = instance_data.b;
	instance_alpha = fade_factor;
	float radius = instance_data.g * 0.5 * thickness_factor;
	float full_length = min(instance_data.a / travel_radius, 1.0);
	float current_length = full_length * length_factor;
	float center_position = movement_t - full_length * 0.5;
	float tail_position = center_position - current_length * 0.5;
	float axial_position = tail_position + current_length * longitudinal;
	float axial_rate = current_length;

	float angle = UV.x * PI * 2.0;
	vec2 radial_direction = vec2(cos(angle), sin(angle));
	float profile_radius_value = radius * profile_radius(longitudinal);
	float radius_rate = radius * profile_radius_rate(longitudinal);
	VERTEX = vec3(
		radial_direction.x * profile_radius_value,
		axial_position,
		radial_direction.y * profile_radius_value
	);
	vec3 profile_normal = vec3(
		radial_direction.x * axial_rate,
		-radius_rate,
		radial_direction.y * axial_rate
	);
	if (length(profile_normal) > MIN_LENGTH) {
		NORMAL = normalize(profile_normal);
	} else {
		NORMAL = vec3(radial_direction.x, 0.0, radial_direction.y);
	}
}

void fragment() {
	float facing = max(dot(normalize(NORMAL), normalize(VIEW)), 0.0);
	float edge_alpha = smoothstep(0.0, edge_softness, facing);
	ALBEDO = vec3(intensity * instance_strength);
	ALPHA = instance_alpha * edge_alpha;
}
