shader_type spatial;

render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;

uniform vec4 line_color : source_color = vec4(0.08, 0.72, 1.0, 1.0);
uniform float line_intensity : hint_range(0.5, 5.0, 0.1) = 2.0;
uniform float line_kind = 0.0;
uniform float line_width : hint_range(0.01, 0.18, 0.005) = 0.06;
uniform float line_offset : hint_range(-0.30, 0.30, 0.01) = 0.0;
uniform float line_wave_amplitude : hint_range(0.0, 0.10, 0.005) = 0.025;
uniform float line_wave_phase : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform vec2 line_noise_offset = vec2(0.0);

uniform float stream_wave_amplitude : hint_range(0.0, 0.60, 0.01) = 0.20;
uniform float stream_wave_cycles : hint_range(0.5, 3.0, 0.05) = 1.5;
uniform float stream_wave_speed : hint_range(0.0, 2.0, 0.05) = 0.50;
uniform float stream_wave_outer_scale : hint_range(0.0, 1.0, 0.05) = 0.60;
uniform float stream_wave_peak_position : hint_range(0.20, 0.70, 0.01) = 0.45;
uniform float stream_wave_inner_scale : hint_range(0.0, 0.50, 0.05) = 0.10;

uniform float line_wave_cycles : hint_range(1.0, 5.0, 0.10) = 2.5;
uniform float line_wave_speed : hint_range(0.0, 3.0, 0.05) = 0.80;
uniform float line_wave_noise_amount : hint_range(0.0, 0.50, 0.05) = 0.20;

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


float stream_envelope(float progress) {
	float peak = clamp(stream_wave_peak_position, 0.20, 0.70);
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
	return (sine_wave + (noise * 2.0 - 1.0) * line_wave_noise_amount)
		* line_wave_amplitude * radius_scale;
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
	float softness = min(0.025, white_segment_length * 0.25);
	for (int index = 0; index < 3; index++) {
		vec4 segment = white_segments[index];
		float active = step(0.5, segment.y);
		float start = segment.x;
		float finish = start + white_segment_length;
		float leading = smoothstep(start, start + softness, flow_progress);
		float trailing = 1.0 - smoothstep(finish - softness, finish, flow_progress);
		mask = max(mask, leading * trailing * active);
	}
	return mask;
}


void vertex() {
	float path_progress = clamp(UV.x, 0.0, 1.0);
	float flow_progress = 1.0 - path_progress;
	vec3 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 world_tangent = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 view_direction = normalize(CAMERA_POSITION_WORLD - world_position);
	vec3 ribbon_direction = cross(world_tangent, view_direction);
	if (length(ribbon_direction) < 0.001) {
		ribbon_direction = cross(world_tangent, vec3(0.0, 1.0, 0.0));
	}
	if (length(ribbon_direction) < 0.001) {
		ribbon_direction = cross(world_tangent, vec3(1.0, 0.0, 0.0));
	}
	ribbon_direction = normalize(ribbon_direction);

	float side = UV.y * 2.0 - 1.0;
	float width_factor = inner_width_factor(flow_progress);
	float offset_scale = mix(1.0, inner_offset_scale, smoothstep(0.0, 1.0, flow_progress));
	float center_displacement = stream_wave_at(flow_progress)
		+ line_offset * offset_scale * radius_scale
		+ line_wave_at(flow_progress);
	float width = line_width * width_factor * radius_scale;
	float displacement = center_displacement + side * width * 0.5;
	world_position += ribbon_direction * displacement;

	vec3 view_position = (VIEW_MATRIX * vec4(world_position, 1.0)).xyz;
	MODELVIEW_MATRIX = mat4(1.0);
	VERTEX = view_position;
}


void fragment() {
	float path_progress = clamp(UV.x, 0.0, 1.0);
	float flow_progress = 1.0 - path_progress;
	float edge_width = max(fwidth(UV.y) * 1.5, 0.002);
	float edge_alpha = smoothstep(0.0, edge_width, UV.y)
		* (1.0 - smoothstep(1.0 - edge_width, 1.0, UV.y));
	float alpha = endpoint_alpha(flow_progress) * edge_alpha * white_segment_mask(flow_progress);

	vec3 radiance = line_color.rgb * line_intensity;
	ALBEDO = radiance;
	EMISSION = radiance;
	ALPHA = alpha * line_color.a;
}
