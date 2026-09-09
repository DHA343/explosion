shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;

instance uniform float progress = 0.0;
uniform sampler2D cross_gradient : source_color, filter_linear, repeat_disable;
uniform sampler2D ring_gradient : source_color, filter_linear, repeat_disable;
uniform float flow_speed = 1.3;
uniform float flow_direction = 0.0;
uniform float flow_position = 0.0;
uniform float flow_width = 1.4;
uniform float ring_color_offset : hint_range(0.0, 1.0) = 0.0;
uniform float inner_color_offset : hint_range(0.0, 1.0) = 0.15;
uniform float ring_peak_width : hint_range(0.01, 0.12) = 0.065;
uniform float ring_min_width_ratio : hint_range(0.1, 0.8) = 0.4;
instance uniform int variant = 1;
instance uniform float flare_size = 1.0;
instance uniform float brightness = 1.6;
// Initial angle, total rotation multiplier, deceleration start, strength.
instance uniform vec4 rotation_profile = vec4(0.0, 1.0, 0.25, 0.9);
instance uniform bool stepped = false;
instance uniform float stepped_fps = 24.0;
instance uniform float duration = 0.5;
instance uniform float flow_speed_offset = 0.0;
instance uniform float flow_direction_offset = 0.0;
instance uniform float flow_position_offset = 0.0;
instance uniform float flow_width_offset = 0.0;
// Sector center, sector width, island count, irregularity.
instance uniform vec4 breakup_shape = vec4(3.14159, 2.8, 4.0, 0.65);
instance uniform vec4 breakup_time = vec4(0.29, 0.40, 0.55, 0.0);
instance uniform float breakup_seed = 1.0;
// Godot supports 16 instance uniform slots; keep both per-instance Halo values
// together so the existing CrossFlare instance API can fit within that limit.
instance uniform vec2 halo_parameters = vec2(0.3, 0.03);

vec3 sample_flow_gradient(sampler2D gradient_texture, vec2 point,
		float extra_offset, float sampled_elapsed) {
	float final_flow_speed = flow_speed + flow_speed_offset;
	float final_flow_direction = flow_direction + flow_direction_offset;
	float final_flow_position = flow_position + flow_position_offset;
	float final_flow_width = max(0.05, flow_width + flow_width_offset);
	vec2 axis = vec2(cos(final_flow_direction), sin(final_flow_direction));
	float centered_elapsed = sampled_elapsed - duration * 0.5;
	float position = dot(point, axis) / final_flow_width + 0.5
		+ final_flow_position
		+ extra_offset
		- centered_elapsed * final_flow_speed;
	return texture(gradient_texture, vec2(clamp(position, 0.0, 1.0), 0.5)).rgb;
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
			float spread = cell * mix(0.12, 0.42, breakup_time.z / 0.65)
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

float rotation_progress(float age) {
	float start = clamp(rotation_profile.z, 0.0, 0.8);
	float strength = clamp(rotation_profile.w, 0.0, 0.95);
	strength *= variant == 1 ? 1.0 : (variant == 2 ? 0.85 : 0.9);
	float span = 1.0 - start;
	float u = clamp((age - start) / span, 0.0, 1.0);
	// Integral of a smooth speed reduction; normalize to retain the total angle.
	float travel = age - strength * span * (u * u * u - 0.5 * u * u * u * u);
	float total = 1.0 - strength * span * 0.5;
	float acceleration = variant == 0 ? min(0.16, start * 0.8) : 0.0;
	if (acceleration > 0.0) {
		float a = clamp(age / acceleration, 0.0, 1.0);
		float ramp = a - a * a * a + 0.5 * a * a * a * a;
		travel -= 0.65 * acceleration * ramp;
		total -= 0.65 * acceleration * 0.5;
	}
	return travel / total * rotation_profile.y;
}

vec4 motion_at(float age) {
	float rotation = rotation_progress(age);
	float growth = smoothstep(0.0, 0.36, age);
	float contraction = 1.0 - smoothstep(0.76, 1.0, age);
	float shortening = 1.0 - smoothstep(0.46, 0.9, age);
	float long_arm = max(0.001, 0.68 * growth * contraction);
	float short_arm = max(0.001, long_arm * mix(0.015, 0.93, shortening));
	float width = max(0.001, 0.055 * growth * (1.0 - smoothstep(0.38, 1.0, age)));
	vec4 pose = vec4(long_arm, short_arm, width, -0.4 + 2.0 * rotation);
	if (variant == 1) {
		pose = vec4(short_arm, long_arm, width, -0.8 + 1.6 * rotation);
	} else if (variant == 2) {
		float squash = smoothstep(0.045, 0.13, age) * (1.0 - smoothstep(0.24, 0.34, age));
		float burst = exp(-pow((age - 0.36) / 0.075, 2.0));
		pose.y *= mix(1.0, 0.22, squash);
		pose.z += 0.09 * squash + 0.23 * burst;
		pose.w = 1.7 * rotation;
	}
	return pose;
}

float cross_distance(vec2 point, vec2 reach, float width) {
	vec2 q = abs(point);
	float horizontal_t = q.x / max(reach.x, 0.001);
	float vertical_t = q.y / max(reach.y, 0.001);
	float horizontal_width = width * pow(max(1.0 - horizontal_t, 0.0), 2.4);
	float vertical_width = width * pow(max(1.0 - vertical_t, 0.0), 2.4);
	float horizontal_body = q.y - horizontal_width;
	float vertical_body = q.x - vertical_width;
	float horizontal_tip = length(vec2(max(q.x - reach.x, 0.0), q.y));
	float vertical_tip = length(vec2(q.x, max(q.y - reach.y, 0.0)));
	float horizontal = mix(horizontal_body, horizontal_tip, step(reach.x, q.x));
	float vertical = mix(vertical_body, vertical_tip, step(reach.y, q.y));
	return min(horizontal, vertical);
}

vec3 crescent(vec2 point, vec2 color_point, float radius, float thick_angle,
		float decay_start, float decay_end, float palette_offset, float sector, float center,
		float sampled_elapsed) {
	float azimuth = atan(point.y, point.x);
	float thickness_bias = pow(0.5 + 0.5 * cos(azimuth - thick_angle), 1.2);
	float age = sampled_elapsed / duration;
	float taper = mix(0.28, 1.0, thickness_bias);
	float growth = smoothstep(0.015, max(0.04, min(0.22, decay_start)), age);
	float decay = smoothstep(decay_start, decay_end, age);
	float weakness = ring_weakness(azimuth, sector, center);
	// Preserve the angular thickness profile; below the width floor, fade coverage instead.
	float remaining = max(0.0, taper * (1.0 - decay) - weakness * decay * 0.8);
	float energy = remaining / taper;
	float width_energy = max(ring_min_width_ratio, energy);
	float opacity = smoothstep(0.0, ring_min_width_ratio, energy);
	float width = ring_peak_width * growth * taper * width_energy;
	float ring_distance = abs(length(point) - radius) - width;
	float pixel_width = 0.5 * (length(dFdx(point)) + length(dFdy(point)));
	float aa = max(pixel_width, 0.001);
	float line = 1.0 - smoothstep(-aa, aa, ring_distance);
	float outside = max(ring_distance, 0.0);
	float ring_halo_width = max(halo_parameters.y * 0.7, 0.001);
	float halo_distance = outside / ring_halo_width;
	float haze = exp(-halo_distance * halo_distance) * halo_parameters.x * taper;
	vec3 tint = sample_flow_gradient(ring_gradient, color_point, palette_offset, sampled_elapsed);
	return tint * (line + haze) * growth * opacity;
}

void vertex() {
	vec3 world_scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz),
		length(MODEL_MATRIX[2].xyz));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * world_scale.x,
		INV_VIEW_MATRIX[1] * world_scale.y, INV_VIEW_MATRIX[2] * world_scale.z, MODEL_MATRIX[3]);
	VERTEX *= flare_size * 1.2;
}

void fragment() {
	float raw_progress = clamp(progress, 0.0, 1.0);
	float raw_elapsed = raw_progress * duration;
	float sampled_elapsed = raw_elapsed;
	if (stepped) {
		sampled_elapsed = floor(raw_elapsed * stepped_fps + 0.00001) / stepped_fps;
	}
	sampled_elapsed = min(sampled_elapsed, duration);
	float sampled_progress = duration > 0.0
		? clamp(sampled_elapsed / duration, 0.0, 1.0)
		: 0.0;

	vec4 pose = motion_at(sampled_progress);
	vec2 color_plane = (UV * 2.0 - 1.0) * 1.2;
	vec2 point = rotate_point(color_plane, rotation_profile.x);
	vec2 q = rotate_point(point, pose.w);
	float shape_distance = cross_distance(q, pose.xy, pose.z);
	// abs/min at the thin centerline cancel screen derivatives. Use the
	// unmodified coordinates so opposite sides receive identical filtering.
	float pixel_width = 0.5 * (length(dFdx(q)) + length(dFdy(q)));
	float aa = max(pixel_width, 0.001);
	float body = 1.0 - smoothstep(-aa, aa, shape_distance);
	float outside = max(shape_distance, 0.0);
	float halo_distance = outside / max(halo_parameters.y, 0.001);
	float halo = exp(-halo_distance * halo_distance) * halo_parameters.x;
	vec3 tint = sample_flow_gradient(cross_gradient, color_plane, 0.0, sampled_elapsed);
	vec3 center_tint = sample_flow_gradient(cross_gradient, vec2(0.0), 0.0, sampled_elapsed);
	float fade = smoothstep(0.0, 0.0466667, sampled_progress)
		* (1.0 - smoothstep(0.7333333, 1.0, sampled_progress));
	vec3 radiance = tint * (body + halo) * fade;
	float spark = exp(-dot(point, point) / 0.0006);
	radiance += mix(center_tint, vec3(1.0), 0.5) * spark
		* (1.0 - smoothstep(0.0, 0.1333333, sampled_progress))
		* smoothstep(0.0, 0.015, sampled_progress);
	if (variant > 0) {
		float expansion = smoothstep(0.0666667, 0.3866667, sampled_progress);
		float radius = mix(0.07, 0.77, expansion);
		float decay_start = max(0.04, breakup_time.x - 0.035);
		float decay_end = max(decay_start + 0.08, breakup_time.y + 0.07);
		vec2 ring_point = point;
		float thick_angle = 0.0;
		if (variant == 1) {
			ring_point = rotate_point(point, mix(-0.7, 0.15, expansion));
			ring_point.x /= mix(0.35, 0.92, expansion);
			thick_angle = -0.5;
		} else {
			ring_point.x /= 0.86;
		}
		float sector = breakup_shape.y;
		if (variant == 2 && breakup_time.w < 0.5) {
			sector = TAU;
		}
		radiance += crescent(ring_point, color_plane, radius, thick_angle, decay_start, decay_end,
			ring_color_offset, sector, thick_angle + breakup_shape.x, sampled_elapsed);
		if (variant == 2) {
			float inner_radius = radius * 0.53;
			radiance += crescent(ring_point, color_plane, inner_radius, thick_angle + PI,
				decay_start * 0.72, decay_end * 0.72,
				ring_color_offset + inner_color_offset, 2.8, thick_angle + TAU, sampled_elapsed);
		}
	}
	float border = 1.0 - smoothstep(1.1, 1.2, max(abs(color_plane.x), abs(color_plane.y)));
	ALBEDO = radiance * brightness * border;
	ALPHA = raw_progress > 0.0 && raw_progress < 1.0 ? 1.0 : 0.0;
}
