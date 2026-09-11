shader_type spatial;

render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, fog_disabled;

instance uniform vec4 line_color : source_color = vec4(0.08, 0.72, 1.0, 1.0);
instance uniform float line_intensity = 2.0;
instance uniform float line_kind = 0.0;
instance uniform float line_width : hint_range(0.01, 0.18, 0.005) = 0.06;
instance uniform vec2 line_cross_offset = vec2(0.0);
instance uniform float line_wave_amplitude : hint_range(0.0, 0.10, 0.005) = 0.025;
instance uniform float line_wave_phase : hint_range(0.0, 1.0, 0.01) = 0.0;
instance uniform vec2 line_wave_direction = vec2(1.0, 0.0);
instance uniform vec2 line_noise_offset = vec2(0.0);

uniform float stream_wave_amplitude : hint_range(0.0, 0.60, 0.01) = 0.20;
uniform float stream_wave_cycles : hint_range(0.5, 3.0, 0.05) = 1.5;
uniform float stream_wave_speed : hint_range(0.0, 2.0, 0.05) = 0.50;
uniform float stream_wave_outer_scale : hint_range(0.0, 1.0, 0.05) = 0.60;
uniform float stream_wave_peak_position : hint_range(0.20, 0.70, 0.01) = 0.45;
uniform float stream_wave_inner_scale : hint_range(0.0, 0.50, 0.05) = 0.10;

uniform float line_wave_cycles : hint_range(1.0, 5.0, 0.10) = 2.5;
uniform float line_wave_speed : hint_range(0.0, 3.0, 0.05) = 0.80;
uniform float line_wave_noise_amount : hint_range(0.0, 0.50, 0.05) = 0.20;
uniform float line_wave_inner_amplitude : hint_range(0.0, 0.03, 0.001) = 0.005;
uniform float edge_softness : hint_range(0.0, 0.40, 0.01) = 0.12;
uniform float edge_erosion_strength : hint_range(0.0, 1.0, 0.05) = 0.30;
uniform float body_variation_strength : hint_range(0.0, 0.60, 0.05) = 0.15;
uniform float width_gradient_strength : hint_range(0.0, 1.0, 0.05) = 0.45;
uniform float width_gradient_power : hint_range(0.5, 3.0, 0.1) = 1.4;
uniform float width_noise_strength : hint_range(0.0, 0.35, 0.01) = 0.10;

uniform float inner_offset_scale : hint_range(0.25, 1.0, 0.05) = 0.50;
uniform float outer_fade_length : hint_range(0.02, 0.20, 0.01) = 0.08;
uniform float inner_taper_length : hint_range(0.05, 0.35, 0.01) = 0.18;
uniform float inner_taper_power : hint_range(1.0, 4.0, 0.1) = 1.8;
uniform float inner_fade_length : hint_range(0.03, 0.25, 0.01) = 0.12;
uniform float inner_erosion_strength : hint_range(0.0, 0.60, 0.05) = 0.25;
uniform float radius_scale = 1.0;

uniform float white_segment_length : hint_range(0.05, 0.25, 0.01) = 0.12;
uniform vec4 white_segments[3];


float hash_value(float value) {
	return fract(sin(value * 127.1 + line_noise_offset.x * 311.7)
		* 43758.5453);
}


float smooth_noise(float value) {
	float cell = floor(value);
	float fraction = fract(value);
	float first = hash_value(cell);
	float second = hash_value(cell + 1.0);
	return mix(first, second, smoothstep(0.0, 1.0, fraction));
}


float hash_value_2d(vec2 value) {
	return fract(sin(dot(value, vec2(127.1, 311.7))) * 43758.5453);
}


float smooth_noise_2d(vec2 value) {
	vec2 cell = floor(value);
	vec2 fraction = fract(value);
	vec2 smooth_fraction = smoothstep(vec2(0.0), vec2(1.0), fraction);
	float lower_left = hash_value_2d(cell);
	float lower_right = hash_value_2d(cell + vec2(1.0, 0.0));
	float upper_left = hash_value_2d(cell + vec2(0.0, 1.0));
	float upper_right = hash_value_2d(cell + vec2(1.0, 1.0));
	float lower = mix(lower_left, lower_right, smooth_fraction.x);
	float upper = mix(upper_left, upper_right, smooth_fraction.x);
	return mix(lower, upper, smooth_fraction.y);
}


float stream_envelope(float progress) {
	float peak = stream_wave_peak_position;
	if (progress < peak) {
		float outer_to_peak = smoothstep(0.0, peak, progress);
		return mix(stream_wave_outer_scale, 1.0, outer_to_peak);
	}

	float peak_to_inner = smoothstep(peak, 1.0, progress);
	return mix(1.0, stream_wave_inner_scale, peak_to_inner);
}


float stream_wave_at(float flow_progress) {
	return sin(flow_progress * stream_wave_cycles * TAU - TIME * stream_wave_speed * TAU)
		* stream_wave_amplitude * stream_envelope(flow_progress) * radius_scale;
}


float line_wave_at(float flow_progress) {
	const float NOISE_FREQUENCY = 11.0;
	const float NOISE_SPEED = 0.22;
	float phase = flow_progress * line_wave_cycles * TAU - TIME * line_wave_speed * TAU
		+ line_wave_phase * TAU;
	float sine_wave = sin(phase);
	float noise = smooth_noise(flow_progress * NOISE_FREQUENCY - TIME * NOISE_SPEED);
	float inner_blend = smoothstep(
		1.0 - inner_taper_length,
		1.0,
		flow_progress
	);
	float amplitude = mix(line_wave_amplitude, line_wave_inner_amplitude, inner_blend);
	return (sine_wave + (noise * 2.0 - 1.0) * line_wave_noise_amount)
		* amplitude * radius_scale;
}


float inner_width_factor(float flow_progress) {
	float taper_start = 1.0 - inner_taper_length;
	if (flow_progress <= taper_start) {
		return 1.0;
	}

	float taper_progress = clamp(
		(1.0 - flow_progress) / max(inner_taper_length, 0.001),
		0.0,
		1.0
	);
	return pow(taper_progress, inner_taper_power);
}


float endpoint_alpha(float flow_progress) {
	float outer_alpha = smoothstep(0.0, outer_fade_length, flow_progress);
	float inner_alpha = 1.0 - smoothstep(1.0 - inner_fade_length, 1.0, flow_progress);
	float inner_region = smoothstep(1.0 - inner_fade_length, 1.0, flow_progress);
	float erosion_noise = smooth_noise(flow_progress * 48.0 + line_noise_offset.y);
	float erosion = inner_region * inner_erosion_strength
		* smoothstep(0.48, 0.92, erosion_noise);
	return outer_alpha * inner_alpha * (1.0 - erosion);
}


float white_segment_mask(float flow_progress) {
	if (line_kind < 1.5) {
		return 1.0;
	}

	float mask = 0.0;
	for (int index = 0; index < 3; index++) {
		vec4 segment = white_segments[index];
		float active = step(0.5, segment.y);
		float start = segment.x;
		float finish = start + white_segment_length;
		float inside = step(start, flow_progress) * step(flow_progress, finish);
		mask = max(mask, inside * active);
	}
	return mask;
}


float white_segment_shape(float flow_progress) {
	if (line_kind < 1.5) {
		return 1.0;
	}

	float shape = 0.0;
	for (int index = 0; index < 3; index++) {
		vec4 segment = white_segments[index];
		float active = step(0.5, segment.y);
		float segment_progress = (flow_progress - segment.x) / max(white_segment_length, 0.001);
		float inside = step(0.0, segment_progress) * step(segment_progress, 1.0);
		float tip_factor = 1.0 - abs(segment_progress * 2.0 - 1.0);
		shape = max(shape, max(tip_factor, 0.0) * inside * active);
	}
	return shape;
}


vec3 normalized_or_fallback(vec3 value, vec3 fallback) {
	float value_length = length(value);
	if (value_length > 0.001) {
		return value / value_length;
	}
	return normalize(fallback);
}


void vertex() {
	float path_progress = clamp(UV.x, 0.0, 1.0);
	float flow_progress = 1.0 - path_progress;
	vec3 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 world_tangent = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
	vec3 local_x_world = (MODEL_MATRIX * vec4(vec3(1.0, 0.0, 0.0), 0.0)).xyz;
	vec3 local_y_world = (MODEL_MATRIX * vec4(vec3(0.0, 1.0, 0.0), 0.0)).xyz;
	vec3 local_z_world = (MODEL_MATRIX * vec4(vec3(0.0, 0.0, 1.0), 0.0)).xyz;
	world_tangent = normalized_or_fallback(world_tangent, local_x_world);
	local_x_world = normalized_or_fallback(local_x_world, vec3(1.0, 0.0, 0.0));
	local_y_world = normalized_or_fallback(local_y_world, vec3(0.0, 1.0, 0.0));
	local_z_world = normalized_or_fallback(local_z_world, vec3(0.0, 0.0, 1.0));

	// Build a camera-independent 2D cross-section around the path tangent.
	vec3 cross_axis_b = local_z_world - world_tangent * dot(local_z_world, world_tangent);
	if (length(cross_axis_b) <= 0.001) {
		cross_axis_b = local_y_world - world_tangent * dot(local_y_world, world_tangent);
	}
	if (length(cross_axis_b) <= 0.001) {
		cross_axis_b = local_x_world - world_tangent * dot(local_x_world, world_tangent);
	}
	cross_axis_b = normalized_or_fallback(cross_axis_b, local_y_world);
	vec3 cross_axis_a = normalized_or_fallback(
		cross(world_tangent, cross_axis_b),
		local_x_world
	);

	float offset_scale = mix(1.0, inner_offset_scale, smoothstep(0.0, 1.0, flow_progress));
	vec3 stream_displacement = cross_axis_a * stream_wave_at(flow_progress);
	vec3 cross_offset = (
		cross_axis_a * line_cross_offset.x
		+ cross_axis_b * line_cross_offset.y
	) * offset_scale * radius_scale;
	vec3 line_wave_direction_world = normalized_or_fallback(
		cross_axis_a * line_wave_direction.x
		+ cross_axis_b * line_wave_direction.y,
		cross_axis_a
	);
	vec3 line_displacement = line_wave_direction_world * line_wave_at(flow_progress);
	vec3 center_world_position = world_position + stream_displacement + cross_offset + line_displacement;

	// Only ribbon width follows the camera; its center and all wave directions do not.
	vec3 view_direction = normalized_or_fallback(
		CAMERA_POSITION_WORLD - center_world_position,
		local_z_world
	);
	vec3 ribbon_width_direction = cross(world_tangent, view_direction);
	if (length(ribbon_width_direction) <= 0.001) {
		ribbon_width_direction = cross(world_tangent, local_z_world);
	}
	if (length(ribbon_width_direction) <= 0.001) {
		ribbon_width_direction = cross(world_tangent, local_y_world);
	}
	if (length(ribbon_width_direction) <= 0.001) {
		ribbon_width_direction = cross(world_tangent, local_x_world);
	}
	ribbon_width_direction = normalized_or_fallback(ribbon_width_direction, local_y_world);

	const float WIDTH_NOISE_FREQUENCY = 4.0;
	const float WIDTH_NOISE_FLOW_SPEED = 0.10;
	const float WIDTH_NOISE_OFFSET_SCALE = 0.21;
	float width_noise = smooth_noise(
		flow_progress * WIDTH_NOISE_FREQUENCY
		- TIME * WIDTH_NOISE_FLOW_SPEED
		+ line_noise_offset.x * WIDTH_NOISE_OFFSET_SCALE
	);
	float width_noise_factor = 1.0
		+ (width_noise * 2.0 - 1.0) * width_noise_strength;
	float colored_width_noise_factor = line_kind > 1.5 ? 1.0 : width_noise_factor;
	float white_shape = white_segment_shape(flow_progress);
	float width = line_width
		* colored_width_noise_factor
		* inner_width_factor(flow_progress)
		* white_shape
		* radius_scale;
	float side = UV.y * 2.0 - 1.0;
	vec3 final_world_position = center_world_position
		+ ribbon_width_direction * (side * width * 0.5);
	vec3 view_position = (VIEW_MATRIX * vec4(final_world_position, 1.0)).xyz;
	MODELVIEW_MATRIX = mat4(1.0);
	VERTEX = view_position;
}


void fragment() {
	float path_progress = clamp(UV.x, 0.0, 1.0);
	float flow_progress = 1.0 - path_progress;
	const float EROSION_LENGTH_FREQUENCY = 5.0;
	const float EROSION_WIDTH_FREQUENCY = 8.0;
	const float EDGE_OFFSET_SCALE = 0.08;
	const float BODY_FREQUENCY = 6.0;
	const float BODY_FLOW_SPEED = 0.08;
	float center_distance = abs(UV.y * 2.0 - 1.0);
	float core_mask = 1.0 - smoothstep(0.25, 0.75, center_distance);
	float erosion_noise = smooth_noise_2d(
		vec2(
			flow_progress * EROSION_LENGTH_FREQUENCY,
			UV.y * EROSION_WIDTH_FREQUENCY
		) + line_noise_offset
	);
	float edge_offset = (erosion_noise - 0.5)
		* edge_erosion_strength * EDGE_OFFSET_SCALE;
	float safe_edge_softness = max(edge_softness, 0.001);
	float soft_edge = 1.0 - smoothstep(
		1.0 - safe_edge_softness + edge_offset,
		1.0 + edge_offset,
		center_distance
	);
	float edge_region = 1.0 - core_mask;
	float erosion_multiplier = line_kind > 1.5 ? 0.35 : 1.0;
	float erosion = erosion_noise * edge_erosion_strength
		* edge_region * erosion_multiplier;
	float edge_width = max(fwidth(UV.y) * 1.5, 0.002);
	float edge_aa = smoothstep(0.0, edge_width, UV.y)
		* (1.0 - smoothstep(1.0 - edge_width, 1.0, UV.y));
	float alpha = endpoint_alpha(flow_progress)
		* edge_aa
		* soft_edge
		* (1.0 - erosion)
		* white_segment_mask(flow_progress);
	float body_noise = smooth_noise(
		flow_progress * BODY_FREQUENCY
		- TIME * BODY_FLOW_SPEED
		+ line_noise_offset.y * 0.17
	);
	float body_variation = 1.0
		+ (body_noise * 2.0 - 1.0) * body_variation_strength;
	float width_gradient = pow(
		max(1.0 - center_distance, 0.0),
		width_gradient_power
	);
	float width_radiance_factor = mix(
		1.0 - width_gradient_strength,
		1.0,
		width_gradient
	);

	vec3 radiance = line_color.rgb
		* line_intensity
		* body_variation
		* width_radiance_factor;
	ALBEDO = radiance;
	EMISSION = radiance;
	ALPHA = alpha;
}
