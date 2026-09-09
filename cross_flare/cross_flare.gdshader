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
instance uniform int variant = 1;
instance uniform float flare_size = 1.0;
instance uniform float brightness = 1.6;
instance uniform float initial_angle = 0.0;
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
instance uniform vec2 edge_style = vec2(0.008, 0.3);

vec3 sample_flow_gradient(sampler2D gradient_texture, vec2 point,
		float extra_offset, float sampled_elapsed) {
	float final_flow_speed = flow_speed + flow_speed_offset;
	float final_flow_direction = flow_direction + flow_direction_offset;
	float final_flow_position = flow_position + flow_position_offset;
	float final_flow_width = max(0.05, flow_width + flow_width_offset);
	vec2 axis = vec2(cos(final_flow_direction), sin(final_flow_direction));
	float position = dot(point, axis) / final_flow_width + 0.5
		+ final_flow_position + extra_offset - sampled_elapsed * final_flow_speed;
	return texture(gradient_texture, vec2(clamp(position, 0.0, 1.0), 0.5)).rgb;
}

float noise_value(float index) {
	return fract(sin(index * 127.1 + breakup_seed * 311.7) * 43758.5453);
}

float arc_distance(float azimuth, float radius, float amount, float sector, float center) {
	float count = clamp(floor(breakup_shape.z + 0.5), 3.0, 5.0);
	float total_weight = 0.0;
	for (int i = 0; i < 5; i++) {
		if (float(i) < count) {
			total_weight += mix(1.0, mix(0.35, 1.65, noise_value(float(i) + 31.0)), breakup_shape.w);
		}
	}
	float cursor = center - sector * 0.5;
	float nearest_gap = 10.0;
	for (int i = 0; i < 5; i++) {
		if (float(i) < count) {
			float weight = mix(1.0, mix(0.35, 1.65, noise_value(float(i) + 31.0)), breakup_shape.w);
			float cell = sector * weight / total_weight;
			float jitter = (noise_value(float(i) + 1.0) - 0.5) * 0.18 * breakup_shape.w;
			float location = cursor + (0.5 + jitter) * cell;
			float half_gap = cell * breakup_time.z * 0.5
				* mix(1.0, mix(0.25, 1.0, noise_value(float(i) + 11.0)), breakup_shape.w) * amount;
			float delta = abs(atan(sin(azimuth - location), cos(azimuth - location)));
			nearest_gap = min(nearest_gap, (delta - half_gap) * radius);
			cursor += cell;
		}
	}
	return -nearest_gap;
}

vec2 rotate_point(vec2 point, float angle) {
	float c = cos(angle);
	float s = sin(angle);
	return mat2(vec2(c, -s), vec2(s, c)) * point;
}

vec4 motion_at(float age) {
	float growth = smoothstep(0.0, 0.36, age);
	float contraction = 1.0 - smoothstep(0.76, 1.0, age);
	float shortening = 1.0 - smoothstep(0.46, 0.9, age);
	float long_arm = max(0.001, 0.68 * growth * contraction);
	float short_arm = max(0.001, long_arm * mix(0.015, 0.93, shortening));
	float width = max(0.001, 0.055 * growth * (1.0 - smoothstep(0.38, 1.0, age)));
	vec4 pose = vec4(long_arm, short_arm, width, -0.4 + 2.0 * age);
	if (variant == 1) {
		pose = vec4(short_arm, long_arm, width, -0.8 + 1.6 * age);
	} else if (variant == 2) {
		float squash = smoothstep(0.045, 0.13, age) * (1.0 - smoothstep(0.24, 0.34, age));
		float burst = exp(-pow((age - 0.36) / 0.075, 2.0));
		pose.y *= mix(1.0, 0.22, squash);
		pose.z += 0.09 * squash + 0.23 * burst;
		pose.w = 1.7 * age;
	}
	return pose;
}

float cross_distance(vec2 point, vec2 reach, float width) {
	vec2 q = abs(point);
	float horizontal = q.y - width * pow(max(1.0 - q.x / reach.x, 0.0), 2.4);
	float vertical = q.x - width * pow(max(1.0 - q.y / reach.y, 0.0), 2.4);
	return min(max(horizontal, q.x - reach.x), max(vertical, q.y - reach.y));
}

vec3 crescent(vec2 point, vec2 color_point, float radius, float thick_angle,
		float breakup, float palette_offset, float sector, float center,
		float sampled_elapsed) {
	float azimuth = atan(point.y, point.x);
	float thickness_bias = pow(0.5 + 0.5 * cos(azimuth - thick_angle), 1.2);
	float taper = mix(mix(0.28, 0.10, breakup), 1.0, thickness_bias);
	float width = 0.042 * taper;
	float ring_distance = abs(length(point) - radius) - width;
	if (breakup > 0.0) {
		float cut = arc_distance(azimuth, radius, breakup, sector, center);
		ring_distance = mix(ring_distance, max(ring_distance, cut), smoothstep(0.0, 0.15, breakup));
	}
	float aa = max(fwidth(ring_distance), 0.001) + edge_style.x;
	float line = 1.0 - smoothstep(-aa, aa, ring_distance);
	float outside = max(ring_distance, 0.0);
	float haze = exp(-outside * outside / 0.0004) * edge_style.y * taper;
	vec3 tint = sample_flow_gradient(ring_gradient, color_point, palette_offset, sampled_elapsed);
	return tint * (line + haze);
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
	vec2 point = rotate_point(color_plane, initial_angle);
	vec2 q = rotate_point(point, pose.w);
	float shape_distance = cross_distance(q, pose.xy, pose.z);
	// abs/min at the thin centerline cancel screen derivatives. Use the
	// unmodified coordinates so opposite sides receive identical filtering.
	float pixel_width = 0.5 * (length(dFdx(q)) + length(dFdy(q)));
	float aa = max(pixel_width, 0.001) + edge_style.x;
	float body = 1.0 - smoothstep(-aa, aa, shape_distance);
	float outside = max(shape_distance, 0.0);
	float tip_fade = 1.0 - smoothstep(0.65, 1.02, max(abs(q.x) / pose.x, abs(q.y) / pose.y));
	float halo = exp(-outside * outside / 0.0009) * edge_style.y * tip_fade;
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
		float ring_fade = smoothstep(0.0533333, 0.1333333, sampled_progress)
			* (1.0 - smoothstep(0.3333333, 0.4666667, sampled_progress));
		float breakup = smoothstep(breakup_time.x, max(breakup_time.x + 0.001, breakup_time.y),
			sampled_progress);
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
		radiance += crescent(ring_point, color_plane, radius, thick_angle, breakup,
			ring_color_offset, sector, thick_angle + breakup_shape.x, sampled_elapsed) * ring_fade;
		if (variant == 2) {
			float inner_radius = radius * 0.53;
			float inner_fade = 1.0 - smoothstep(0.2666667, 0.3333333, sampled_progress);
			radiance += crescent(ring_point, color_plane, inner_radius, thick_angle + PI,
				smoothstep(0.2666667, 0.3333333, sampled_progress),
				ring_color_offset + inner_color_offset, 2.8, thick_angle + TAU, sampled_elapsed)
				* ring_fade * inner_fade;
		}
	}
	float border = 1.0 - smoothstep(1.1, 1.2, max(abs(color_plane.x), abs(color_plane.y)));
	ALBEDO = radiance * brightness * border;
	ALPHA = raw_progress > 0.0 && raw_progress < 1.0 ? 1.0 : 0.0;
}
