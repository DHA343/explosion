shader_type spatial;
render_mode unshaded, cull_back, blend_mix, depth_draw_never;

uniform float intensity : hint_range(0.0, 8.0, 0.1) = 1.0;
uniform float edge_softness : hint_range(0.01, 1.0, 0.01) = 0.5;
instance uniform float peak_position_ratio : hint_range(0.05, 0.95) = 0.67;
instance uniform float peak_end_position_ratio : hint_range(0.05, 0.95) = 0.75;
instance uniform float roundness_power : hint_range(1.0, 8.0) = 2.0;
instance uniform bool collision_deformation = false;
instance uniform float length_end_scale : hint_range(0.0, 2.0) = 0.0;
instance uniform float length_change_power : hint_range(0.1, 8.0) = 1.0;
instance uniform float thickness_end_scale : hint_range(0.0, 2.0) = 0.0;
instance uniform float thickness_change_power : hint_range(0.1, 8.0) = 2.0;
instance uniform float fade_power : hint_range(0.1, 8.0) = 2.0;

const float MIN_LENGTH = 0.0001;
const float PROFILE_SAMPLE_STEP = 0.001;

varying float instance_brightness;
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
	float longitudinal = UV.y;
	float travel_radius = max(length(MODEL_MATRIX[1].xyz), MIN_LENGTH);
	float movement_t = instance_data.r;
	float disappearance_t = instance_data.g;
	float length_change_t = pow(disappearance_t, length_change_power);
	float thickness_change_t = pow(disappearance_t, thickness_change_power);
	float current_peak_position = peak_position_ratio;
	if (collision_deformation) {
		length_change_t = 1.0 - pow(1.0 - disappearance_t, length_change_power);
		thickness_change_t = 1.0 - pow(1.0 - disappearance_t, thickness_change_power);
		current_peak_position = mix(
			peak_position_ratio,
			peak_end_position_ratio,
			thickness_change_t
		);
	}
	float length_factor = mix(
		1.0,
		length_end_scale,
		length_change_t
	);
	float thickness_factor = mix(
		1.0,
		thickness_end_scale,
		thickness_change_t
	);
	float fade_t = COLOR.a;
	float fade_factor = 1.0 - pow(fade_t, fade_power);
	instance_brightness = COLOR.r;
	instance_alpha = fade_factor;
	float radius = instance_data.b * 0.5 * thickness_factor;
	float full_length = min(instance_data.a / travel_radius, 1.0);
	float current_length = full_length * length_factor;
	float center_position = movement_t - full_length * 0.5;
	float tail_position = center_position - current_length * 0.5;
	if (collision_deformation) {
		tail_position = movement_t - current_length;
	}
	float axial_position = tail_position + current_length * longitudinal;
	float axial_rate = current_length;

	float angle = UV.x * PI * 2.0;
	vec2 radial_direction = vec2(cos(angle), sin(angle));
	float profile_radius_value = radius * profile_radius(longitudinal, current_peak_position);
	float radius_rate = radius * profile_radius_rate(longitudinal, current_peak_position);
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
	ALBEDO = vec3(intensity * instance_brightness);
	ALPHA = instance_alpha * edge_alpha;
}
