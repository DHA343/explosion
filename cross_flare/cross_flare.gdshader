shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;

instance uniform float progress = 0.0;
uniform sampler2D cross_gradient : source_color, filter_linear, repeat_disable;
uniform sampler2D ring_gradient : source_color, filter_linear, repeat_disable;
uniform float color_angle : hint_range(-3.14, 3.14) = 0.0;
uniform float color_offset : hint_range(-1.0, 1.0) = 0.0;
uniform float color_span : hint_range(0.1, 2.0) = 1.4;
uniform float ring_color_offset : hint_range(0.0, 1.0) = 0.0;
uniform float inner_color_offset : hint_range(0.0, 1.0) = 0.15;
instance uniform int ring_style = 1;
instance uniform float flare_size = 1.0;
instance uniform float brightness = 1.6;
instance uniform float initial_angle = 0.0;
instance uniform bool stepped = false;
uniform bool flowing = true;
// Angle, signed travel per lifetime, starting offset, band width multiplier.
instance uniform vec4 color_flow = vec4(0.0, 0.65, 0.0, 1.0);
// Sector center, sector width, island count, irregularity.
instance uniform vec4 breakup_shape = vec4(3.14159, 2.8, 4.0, 0.65);
instance uniform vec4 breakup_time = vec4(0.29, 0.40, 0.55, 0.0);
instance uniform float breakup_seed = 1.0;
instance uniform vec2 edge_style = vec2(0.008, 0.3);

vec3 plane_color(vec2 point) {
	vec2 axis = vec2(cos(color_angle + color_flow.x), sin(color_angle + color_flow.x));
	float position = dot(point, axis) / (color_span * color_flow.w) + 0.5 + color_offset;
	position += color_flow.z - (progress - 0.5) * color_flow.y;
	return texture(cross_gradient, vec2(clamp(position, 0.0, 1.0), 0.5)).rgb;
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

// Continuous motion; stepped playback only samples this timeline less often.
vec4 motion_at(float age) {
	float growth = smoothstep(0.0, 0.36, age);
	float contraction = 1.0 - smoothstep(0.76, 1.0, age);
	float shortening = 1.0 - smoothstep(0.46, 0.9, age);
	float long_arm = max(0.001, 0.68 * growth * contraction);
	float short_arm = max(0.001, long_arm * mix(0.015, 0.93, shortening));
	float width = max(0.001, 0.055 * growth * (1.0 - smoothstep(0.38, 1.0, age)));
	vec4 pose = vec4(long_arm, short_arm, width, -0.4 + 2.0 * age);
	if (ring_style == 1) {
		pose = vec4(short_arm, long_arm, width, -0.8 + 1.6 * age);
	} else if (ring_style == 2) {
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
		float breakup, float palette_offset, float sector, float center) {
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
	float color_position = fract(azimuth / TAU + 0.5 + palette_offset);
	vec3 tint = texture(ring_gradient, vec2(color_position, 0.5)).rgb;
	if (flowing) {
		tint = plane_color(color_point);
	}
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
	float frame = clamp(progress, 0.0, 1.0) * 15.0;
	if (stepped) {
		frame = floor(frame + 0.0001);
	}
	vec4 pose = motion_at(frame / 15.0);
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
	vec2 color_point = rotate_point(q, color_angle);
	float color_position = clamp(color_point.x / color_span + 0.5 + color_offset, 0.0, 1.0);
	vec3 tint = texture(cross_gradient, vec2(color_position, 0.5)).rgb;
	vec3 center_tint = texture(cross_gradient, vec2(clamp(0.5 + color_offset, 0.0, 1.0), 0.5)).rgb;
	if (flowing) {
		tint = plane_color(color_plane);
		center_tint = plane_color(vec2(0.0));
	}
	float fade = smoothstep(0.0, 0.7, frame) * (1.0 - smoothstep(11.0, 15.0, frame));
	vec3 radiance = tint * (body + halo) * fade;
	float spark = exp(-dot(point, point) / 0.0006);
	radiance += mix(center_tint, vec3(1.0), 0.5) * spark
		* (1.0 - smoothstep(0.0, 2.0, frame)) * smoothstep(0.0, 0.015, progress);
	if (ring_style > 0) {
		float expansion = smoothstep(1.0, 5.8, frame);
		float radius = mix(0.07, 0.77, expansion);
		float ring_fade = smoothstep(0.8, 2.0, frame) * (1.0 - smoothstep(5.0, 7.0, frame));
		float breakup = smoothstep(breakup_time.x, max(breakup_time.x + 0.001, breakup_time.y), frame / 15.0);
		vec2 ring_point = point;
		float thick_angle = 0.0;
		if (ring_style == 1) {
			ring_point = rotate_point(point, mix(-0.7, 0.15, expansion));
			ring_point.x /= mix(0.35, 0.92, expansion);
			thick_angle = -0.5;
		} else {
			ring_point.x /= 0.86;
		}
		float sector = breakup_shape.y;
		if (ring_style == 2 && breakup_time.w < 0.5) {
			sector = TAU;
		}
		radiance += crescent(ring_point, color_plane, radius, thick_angle, breakup, ring_color_offset,
			sector, thick_angle + breakup_shape.x)
			* ring_fade;
		if (ring_style == 2) {
			float inner_radius = radius * 0.53;
			float inner_fade = 1.0 - smoothstep(4.0, 5.0, frame);
			radiance += crescent(ring_point, color_plane, inner_radius, thick_angle + PI,
				smoothstep(4.0, 5.0, frame), ring_color_offset + inner_color_offset,
				2.8, thick_angle + TAU) * ring_fade * inner_fade;
		}
	}
	float border = 1.0 - smoothstep(1.1, 1.2, max(abs(color_plane.x), abs(color_plane.y)));
	ALBEDO = radiance * brightness * border;
	ALPHA = progress > 0.0 && progress < 1.0 ? 1.0 : 0.0;
}


