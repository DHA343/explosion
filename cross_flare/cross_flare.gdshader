shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;

instance uniform float progress = 0.0;
uniform sampler2D cross_gradient : source_color, filter_linear, repeat_disable;
uniform sampler2D ring_gradient : source_color, filter_linear, repeat_disable;
uniform bool ring_use_cross_gradient = true;
uniform float flow_speed : hint_range(0.0, 5.0, 0.1) = 2.0;
uniform float flow_width : hint_range(0.1, 3.0, 0.1) = 2.0;
instance uniform vec2 variant_size = vec2(1.0, 1.0);
// intensity, duration, halo strength, halo width.
instance uniform vec4 effect_parameters = vec4(1.6, 0.5, 0.3, 0.03);
// Initial angle and rotation speed in radians per second.
instance uniform float initial_angle = 0.0;
instance uniform float rotation_speed_radians = 3.1415927;
// Flow direction and position are selected once for each CrossFlare instance.
instance uniform vec2 color_flow_parameters = vec2(0.0, 0.0);
// Sector center, sector width, island count, irregularity.
instance uniform vec4 breakup_shape = vec4(3.14159, 2.8, 4.0, 0.65);
instance uniform vec4 breakup_time = vec4(0.29, 0.40, 0.55, 0.0);
instance uniform float breakup_seed = 1.0;
// Stepped state and its sampling rate are updated together by CrossFlare.
instance uniform vec2 stepped_parameters = vec2(0.0, 24.0);
instance uniform vec4 motion_timing_a = vec4(0.36, 0.38, 0.82, 0.46);
instance uniform vec4 motion_timing_b = vec4(0.70, 0.68, 0.85, 0.70);
instance uniform vec2 motion_timing_c = vec2(0.86, 0.30);
instance uniform vec2 ring_shape = vec2(0.065, 0.4);
// Breakup strength, start, fragment count, irregularity.
instance uniform vec4 tail_parameters = vec4(0.0, 0.84, 4.0, 0.65);

const float HALO_MIN_WIDTH_RATIO = 0.2;
const float CROSS_REFERENCE_WIDTH = 0.055;
const float RING_COLOR_OFFSET = 0.0;
const float INNER_COLOR_OFFSET = 0.15;
const float RING_FADE_SOFTNESS = 0.4;
const float RING_END_SOFTNESS = 0.06;

vec3 sample_flow_gradient(sampler2D gradient_texture, vec2 point,
		float extra_offset, float sampled_elapsed) {
	vec2 axis = vec2(cos(color_flow_parameters.x), sin(color_flow_parameters.x));
	float centered_elapsed = sampled_elapsed - effect_parameters.y * 0.5;
	float position = dot(point, axis) / max(flow_width, 0.05) + 0.5
		+ color_flow_parameters.y
		+ extra_offset
		- centered_elapsed * flow_speed;
	return texture(gradient_texture, vec2(clamp(position, 0.0, 1.0), 0.5)).rgb;
}

int variant_value() {
	return int(variant_size.x + 0.5);
}

float noise_value(float index) {
	return fract(sin(index * 127.1 + breakup_seed * 311.7) * 43758.5453);
}

float ring_weakness(float azimuth, float sector, float center) {
	float count = clamp(floor(breakup_shape.z + 0.5), 3.0, 5.0);
	float total_weight = 0.0;
	for (int i = 0; i < 5; i++) {
		if (float(i) < count) {
			total_weight += mix(1.0, mix(0.35, 1.65, noise_value(float(i) + 31.0)), breakup_shape.w);
		}
	}
	float cursor = center - sector * 0.5;
	float weakness = 0.0;
	for (int i = 0; i < 5; i++) {
		if (float(i) < count) {
			float weight = mix(1.0, mix(0.35, 1.65, noise_value(float(i) + 31.0)), breakup_shape.w);
			float cell = sector * weight / total_weight;
			float jitter = (noise_value(float(i) + 1.0) - 0.5) * 0.18 * breakup_shape.w;
			float location = cursor + (0.5 + jitter) * cell;
			float spread = cell * mix(0.12, 0.42, breakup_time.z)
				* mix(1.0, mix(0.55, 1.0, noise_value(float(i) + 11.0)), breakup_shape.w);
			float delta = abs(atan(sin(azimuth - location), cos(azimuth - location)));
			float strength = mix(1.0, mix(0.6, 1.4, noise_value(float(i) + 51.0)), breakup_shape.w);
			weakness += strength * exp(-pow(delta / max(spread, 0.001), 2.0));
			cursor += cell;
		}
	}
	float from_center = abs(atan(sin(azimuth - center), cos(azimuth - center)));
	float sector_mask = sector > 6.28 ? 1.0
		: 1.0 - smoothstep(sector * 0.45, sector * 0.5, from_center);
	return weakness * sector_mask;
}

vec2 rotate_point(vec2 point, float angle) {
	float c = cos(angle);
	float s = sin(angle);
	return mat2(vec2(c, -s), vec2(s, c)) * point;
}

float rotation_angle(float age) {
	return rotation_speed_radians * effect_parameters.y * age;
}

vec4 motion_at(float age) {
	float rotation = rotation_angle(age);
	float growth = smoothstep(0.0, motion_timing_a.x, age);
	float contraction = mix(1.0, 0.55,
		smoothstep(motion_timing_a.w, motion_timing_b.x, age));
	float stretch = smoothstep(motion_timing_b.w, motion_timing_c.x, age);
	float long_arm = max(0.001, 0.68 * growth * mix(contraction, 1.15, stretch));
	float short_arm = max(0.001, 0.68 * growth * 0.93 * contraction
		* (1.0 - smoothstep(motion_timing_b.y, motion_timing_b.z, age)));
	float width_fade = smoothstep(motion_timing_a.y, motion_timing_a.z, age);
	float width = max(0.001, 0.055 * growth * mix(1.0, motion_timing_c.y, width_fade));
	vec4 pose = vec4(long_arm, short_arm, width, -0.4 + rotation);
	if (variant_value() == 1) {
		pose = vec4(short_arm, long_arm, width, -0.8 + rotation);
	} else if (variant_value() == 2) {
		float squash = smoothstep(0.045, 0.13, age) * (1.0 - smoothstep(0.24, 0.34, age));
		float burst = exp(-pow((age - 0.36) / 0.075, 2.0));
		pose.y *= mix(1.0, 0.22, squash);
		pose.z += 0.09 * squash + 0.23 * burst;
		pose.w = rotation;
	}
	return pose;
}

float tail_opacity(vec2 point, float age) {
	if (tail_parameters.x <= 0.0) {
		return 1.0;
	}
	float coordinate = (variant_value() == 1 ? point.y : point.x) / 0.782;
	float count = tail_parameters.z;
	float cell = 2.0 / count;
	float weakness = 0.0;
	for (int i = 0; i < 5; i++) {
		if (float(i) < count - 1.0) {
			float jitter = (noise_value(float(i) + 81.0) - 0.5) * 0.5 * tail_parameters.w;
			float center = -1.0 + (float(i) + 1.0 + jitter) * cell;
			float spread = cell * mix(0.20, 0.10 + 0.22 * noise_value(float(i) + 91.0),
				tail_parameters.w);
			float strength = mix(1.0, 0.6 + noise_value(float(i) + 101.0), tail_parameters.w);
			weakness += exp(-pow((coordinate - center) / spread, 2.0)) * strength;
		}
	}
	float erosion = smoothstep(tail_parameters.y, 1.0, age);
	float remaining = max(0.0, 1.0 - erosion * (1.0 + weakness * 2.0));
	return mix(1.0, smoothstep(0.0, 0.35, remaining), tail_parameters.x);
}

vec2 cross_metrics(vec2 point, vec2 reach, float width, float age) {
	vec2 q = abs(point);
	float horizontal_t = q.x / max(reach.x, 0.001);
	float vertical_t = q.y / max(reach.y, 0.001);
	float horizontal_width = width * pow(max(1.0 - horizontal_t, 0.0), 2.4);
	float vertical_width = width * pow(max(1.0 - vertical_t, 0.0), 2.4);
	// The final streak retains a broad body; only its ends taper to zero.
	float streak = smoothstep(motion_timing_b.y, motion_timing_b.z, age);
	if (variant_value() == 1) {
		vertical_width = mix(vertical_width,
			width * sqrt(max(1.0 - vertical_t * vertical_t, 0.0)), streak);
	} else {
		horizontal_width = mix(horizontal_width,
			width * sqrt(max(1.0 - horizontal_t * horizontal_t, 0.0)), streak);
	}
	float horizontal_body = q.y - horizontal_width;
	float vertical_body = q.x - vertical_width;
	float horizontal_tip = length(vec2(max(q.x - reach.x, 0.0), q.y));
	float vertical_tip = length(vec2(q.x, max(q.y - reach.y, 0.0)));
	float horizontal = mix(horizontal_body, horizontal_tip, step(reach.x, q.x));
	float vertical = mix(vertical_body, vertical_tip, step(reach.y, q.y));
	if (horizontal <= vertical) {
		return vec2(horizontal, horizontal_width);
	}
	return vec2(vertical, vertical_width);
}

vec3 crescent(vec2 point, vec2 color_point, float radius, float thick_angle,
		float decay_start, float decay_end, float palette_offset, float sector, float center,
		float sampled_elapsed) {
	float azimuth = atan(point.y, point.x);
	float thickness_bias = pow(0.5 + 0.5 * cos(azimuth - thick_angle), 1.2);
	float age = sampled_elapsed / effect_parameters.y;
	float taper = mix(0.28, 1.0, thickness_bias);
	float growth = smoothstep(0.015, max(0.04, min(0.22, decay_start)), age);
	float decay = smoothstep(decay_start, decay_end, age);
	float weakness = ring_weakness(azimuth, sector, center);
	// Preserve the width floor while fading independently across a broader energy range.
	float signed_energy = 1.0 - decay - weakness * decay * 0.8 / taper;
	float energy = max(0.0, signed_energy);
	float width_energy = max(ring_shape.y, energy);
	float opacity = smoothstep(0.0, RING_FADE_SOFTNESS, energy);
	// Convert the energy gradient to local distance so steep cuts also receive a soft edge.
	vec2 point_dx = dFdx(point);
	vec2 point_dy = dFdy(point);
	float determinant = point_dx.x * point_dy.y - point_dx.y * point_dy.x;
	float end_opacity = 1.0;
	if (abs(determinant) > 0.00000001 && RING_END_SOFTNESS > 0.0) {
		vec2 energy_screen = vec2(dFdx(signed_energy), dFdy(signed_energy));
		vec2 energy_gradient = vec2(
			energy_screen.x * point_dy.y - energy_screen.y * point_dx.y,
			point_dx.x * energy_screen.y - point_dy.x * energy_screen.x) / determinant;
		float end_distance = energy / max(length(energy_gradient), 0.0001);
		end_opacity = smoothstep(0.0, RING_END_SOFTNESS, end_distance);
	}
	opacity *= end_opacity;
	float width = ring_shape.x * growth * taper * width_energy;
	float ring_distance = abs(length(point) - radius) - width;
	float aa = max(fwidth(ring_distance), 0.001);
	float line = 1.0 - smoothstep(-aa, aa, ring_distance);
	float outside = max(ring_distance, 0.0);
	float local_width_factor = clamp(width / max(ring_shape.x, 0.001),
		HALO_MIN_WIDTH_RATIO, 1.0);
	float ring_halo_width = max(effect_parameters.w * 0.7 * local_width_factor, 0.001);
	float halo_distance = outside / ring_halo_width;
	float outside_mask = 1.0 - line;
	float haze = exp(-halo_distance * halo_distance) * effect_parameters.z * taper * outside_mask;

	vec3 tint;
	if (ring_use_cross_gradient) {
		tint = sample_flow_gradient(
			cross_gradient,
			color_point,
			palette_offset,
			sampled_elapsed
		);
	} else {
		tint = sample_flow_gradient(
			ring_gradient,
			color_point,
			palette_offset,
			sampled_elapsed
		);
	}

	return tint * (line + haze) * growth * opacity;
}

void vertex() {
	vec3 world_scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz),
		length(MODEL_MATRIX[2].xyz));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * world_scale.x,
		INV_VIEW_MATRIX[1] * world_scale.y, INV_VIEW_MATRIX[2] * world_scale.z, MODEL_MATRIX[3]);
	VERTEX *= variant_size.y * 1.2;
}

void fragment() {
	float raw_progress = clamp(progress, 0.0, 1.0);
	float raw_elapsed = raw_progress * effect_parameters.y;
	float sampled_elapsed = raw_elapsed;
	if (stepped_parameters.x > 0.5) {
		sampled_elapsed = floor(raw_elapsed * stepped_parameters.y + 0.00001) / stepped_parameters.y;
	}
	sampled_elapsed = min(sampled_elapsed, effect_parameters.y);
	float sampled_progress = effect_parameters.y > 0.0
		? clamp(sampled_elapsed / effect_parameters.y, 0.0, 1.0)
		: 0.0;

	vec4 pose = motion_at(sampled_progress);
	vec2 color_plane = (UV * 2.0 - 1.0) * 1.2;
	vec2 point = rotate_point(color_plane, initial_angle);
	vec2 q = rotate_point(point, pose.w);
	vec2 cross_data = cross_metrics(q, pose.xy, pose.z, sampled_progress);
	float shape_distance = cross_data.x;
	float local_width = cross_data.y;
	// abs/min at the thin centerline cancel screen derivatives. Use the
	// unmodified coordinates so opposite sides receive identical filtering.
	float pixel_width = 0.5 * (length(dFdx(q)) + length(dFdy(q)));
	float aa = max(pixel_width, 0.001);
	float body = 1.0 - smoothstep(-aa, aa, shape_distance);
	float outside = max(shape_distance, 0.0);
	float local_width_factor = clamp(local_width / CROSS_REFERENCE_WIDTH,
		HALO_MIN_WIDTH_RATIO, 1.0);
	float effective_halo_width = max(effect_parameters.w * local_width_factor, 0.001);
	float halo_distance = outside / effective_halo_width;
	float outside_mask = 1.0 - body;
	float halo = exp(-halo_distance * halo_distance) * effect_parameters.z * outside_mask;
	vec3 tint = sample_flow_gradient(cross_gradient, color_plane, 0.0, sampled_elapsed);
	vec3 center_tint = sample_flow_gradient(cross_gradient, vec2(0.0), 0.0, sampled_elapsed);
	float fade = smoothstep(0.0, 0.0466667, sampled_progress)
		* (1.0 - smoothstep(0.90, 1.0, sampled_progress))
		* tail_opacity(q, sampled_progress);
	vec3 radiance = tint * (body + halo) * fade;
	float spark = exp(-dot(point, point) / 0.0006);
	radiance += mix(center_tint, vec3(1.0), 0.5) * spark
		* (1.0 - smoothstep(0.0, 0.1333333, sampled_progress))
		* smoothstep(0.0, 0.015, sampled_progress);
	if (variant_value() > 0) {
		float expansion = smoothstep(0.0666667, 0.3866667, sampled_progress);
		float radius = mix(0.07, 0.77, expansion);
		float decay_start = max(0.04, breakup_time.x - 0.035);
		float decay_end = max(decay_start + 0.08, breakup_time.y + 0.07);
		vec2 ring_point = point;
		float thick_angle = 0.0;
		if (variant_value() == 1) {
			ring_point = rotate_point(point, mix(-0.7, 0.15, expansion));
			ring_point.x /= mix(0.35, 0.92, expansion);
			thick_angle = -0.5;
		} else {
			ring_point.x /= 0.86;
		}
		float sector = breakup_shape.y;
		if (variant_value() == 2 && breakup_time.w < 0.5) {
			sector = TAU;
		}
		radiance += crescent(ring_point, color_plane, radius, thick_angle, decay_start, decay_end,
			RING_COLOR_OFFSET, sector, thick_angle + breakup_shape.x, sampled_elapsed);
		if (variant_value() == 2) {
			float inner_radius = radius * 0.53;
			radiance += crescent(ring_point, color_plane, inner_radius, thick_angle + PI,
				decay_start * 0.72, decay_end * 0.72,
				RING_COLOR_OFFSET + INNER_COLOR_OFFSET, 2.8, thick_angle + TAU, sampled_elapsed);
		}
	}
	float border = 1.0 - smoothstep(1.1, 1.2, max(abs(color_plane.x), abs(color_plane.y)));
	ALBEDO = radiance * effect_parameters.x * border;
	ALPHA = raw_progress > 0.0 && raw_progress < 1.0 ? 1.0 : 0.0;
}