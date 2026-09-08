shader_type spatial;

render_mode unshaded, blend_add, cull_disabled, depth_draw_never, depth_test_disabled, fog_disabled;

#include "res://energy_sphere/aura_flow/shared/aura_flow_common.gdshaderinc"

const int RAYMARCH_STEPS = 12;
const int BACKTRACE_STEPS = 3;

uniform float sphere_radius = 0.5;
uniform float volume_radius = 1.8;
uniform vec4 cyan_color : source_color = vec4(0.18, 0.78, 1.0, 1.0);
uniform vec4 purple_color : source_color = vec4(0.58, 0.25, 1.0, 1.0);
uniform float cyan_haze_density = 0.92;
uniform float purple_haze_density = 0.72;
uniform float haze_opacity = 0.42;
uniform float haze_emission_strength = 2.0;

uniform uint flow_seed = 2048u;
uniform float radial_speed = 0.20;
uniform float radial_variation = 0.35;
uniform float tangential_strength = 0.46;
uniform float flow_scale = 0.78;
uniform float flow_speed = 0.20;

uniform float source_scale = 1.45;
uniform float source_speed = 0.16;
uniform float source_min_strength = 0.32;
uniform float source_contrast = 1.35;
uniform uint cyan_seed = 343u;
uniform uint purple_seed = 1343u;
uniform uint shape_seed = 7001u;
uniform float shape_scale = 0.78;
uniform float shape_speed = 0.05;
uniform float shape_contrast = 1.45;

uniform float haze_lifetime_min = 0.35;
uniform float haze_lifetime_max = 2.6;
uniform float haze_lifetime_fade_start = 0.72;
uniform float haze_dilution_power = 0.7;

uniform float view_front_visibility = 0.08;
uniform float view_falloff_power = 2.1;

varying vec3 proxy_position_local;
varying vec3 camera_position_local;


void vertex() {
	proxy_position_local = VERTEX;
	camera_position_local = (inverse(MODEL_MATRIX) * vec4(CAMERA_POSITION_WORLD, 1.0)).xyz;
}

vec2 ray_sphere_intersection(vec3 ray_origin, vec3 ray_direction, float sphere_radius_value) {
	float projection = dot(ray_origin, ray_direction);
	float offset = dot(ray_origin, ray_origin) - sphere_radius_value * sphere_radius_value;
	float discriminant = projection * projection - offset;
	if (discriminant < 0.0) {
		return vec2(-1.0);
	}
	float root = sqrt(discriminant);
	return vec2(-projection - root, -projection + root);
}


vec2 segment_sphere_intersection(
	vec3 segment_start,
	vec3 segment_end,
	float sphere_radius_value
) {
	vec3 segment_vector = segment_end - segment_start;
	float segment_length = length(segment_vector);
	if (segment_length <= 0.0001) {
		return vec2(-1.0);
	}
	vec3 segment_direction = segment_vector / segment_length;
	vec2 ray_range = ray_sphere_intersection(
		segment_start,
		segment_direction,
		sphere_radius_value
	);
	if (ray_range.y < 0.0 || ray_range.x > segment_length) {
		return vec2(-1.0);
	}
	return vec2(
		max(ray_range.x, 0.0) / segment_length,
		ray_range.y / segment_length
	);
}


void trace_source(
	vec3 initial_position,
	float sample_time,
	vec3 radial_direction,
	float source_radius,
	inout float reached_source,
	inout vec3 source_direction,
	inout float trace_time
) {
	vec3 trace_position = initial_position;
	trace_time = 0.0;
	reached_source = 0.0;
	source_direction = radial_direction;

	for (int backtrace_index = 0; backtrace_index < BACKTRACE_STEPS; backtrace_index++) {
		if (reached_source == 0.0) {
			float current_radius = length(trace_position);
			float remaining_distance = current_radius - source_radius;

			if (remaining_distance <= 0.0001) {
				reached_source = 1.0;
				source_direction = normalize(trace_position);
			} else {
				vec3 current_radial_direction = trace_position / current_radius;
				vec3 flow = sample_base_flow(
					trace_position,
					source_radius,
					sample_time - trace_time,
					flow_seed,
					radial_speed,
					radial_variation,
					tangential_strength,
					flow_scale,
					flow_speed
				);

				float radial_velocity = dot(flow, current_radial_direction);

				if (radial_velocity <= 0.0001) {
					reached_source = -1.0;
				} else {
					vec3 tangential_flow = flow
						- current_radial_direction * radial_velocity;
					int remaining_steps = BACKTRACE_STEPS - backtrace_index;
					float radial_step = remaining_distance / float(remaining_steps);
					float step_time = radial_step / radial_velocity;
					vec3 direction_offset = tangential_flow
						* step_time
						/ max(current_radius, 0.0001);
					vec3 next_direction = normalize(
						current_radial_direction - direction_offset
					);
					float next_radius = current_radius - radial_step;
					vec3 next_position = next_direction * next_radius;

					trace_time += step_time;

					if (next_radius <= source_radius + 0.0001) {
						reached_source = 1.0;
						source_direction = next_direction;
					} else {
						trace_position = next_position;
					}
				}
			}
		}
	}
}


void fragment() {
	vec3 ray_origin = camera_position_local;
	vec3 ray_direction = normalize(proxy_position_local - ray_origin);

	float transmittance = 1.0;
	vec3 accumulated_emission = vec3(0.0);
	bool camera_inside_volume = length(ray_origin) < volume_radius;
	bool use_raymarch_face = camera_inside_volume ? !FRONT_FACING : FRONT_FACING;
	if (use_raymarch_face) {
		vec2 proxy_range = ray_sphere_intersection(ray_origin, ray_direction, volume_radius);
		float ray_start = max(proxy_range.x, 0.0);
		float ray_end = proxy_range.y;
		vec2 sphere_range = ray_sphere_intersection(ray_origin, ray_direction, sphere_radius);
		if (sphere_range.y >= 0.0) {
			if (sphere_range.x > ray_start) {
				ray_end = min(ray_end, sphere_range.x);
			} else if (sphere_range.x < 0.0 && sphere_range.y >= ray_start) {
				ray_end = ray_start;
			}
		}

		if (ray_end > ray_start) {
			float step_length = (ray_end - ray_start) / float(RAYMARCH_STEPS);
			for (int raymarch_index = 0; raymarch_index < RAYMARCH_STEPS; raymarch_index++) {
			float sample_distance = ray_start + (float(raymarch_index) + 0.5) * step_length;
			vec3 sample_position = ray_origin + ray_direction * sample_distance;
			float sample_radius = length(sample_position);
			vec3 radial_direction = sample_radius > 0.0001
				? sample_position / sample_radius
				: vec3(0.0, 1.0, 0.0);
			vec3 view_direction = normalize(ray_origin - sample_position);
			float reached_source = 0.0;
			vec3 source_direction = radial_direction;
			float trace_time = 0.0;
			float surface_distance = max(sample_radius - sphere_radius, 0.0);
			float max_radial_velocity = sphere_radius * radial_speed * (1.0 + radial_variation);
			bool lifetime_reachable = max_radial_velocity > 0.0001
				&& surface_distance / max_radial_velocity < haze_lifetime_max;
			if (lifetime_reachable) {
				trace_source(
					sample_position,
					TIME,
					radial_direction,
					sphere_radius,
					reached_source,
					source_direction,
					trace_time
				);
			}

			float cyan_density = 0.0;
			float purple_density = 0.0;
			if (reached_source > 0.5) {
				float emission_time = TIME - trace_time;
				float shape = sample_shape_field(
					source_direction,
					emission_time,
					shape_seed,
					shape_scale,
					shape_speed
				);
				float shape_factor = pow(
					clamp(shape, 0.0, 1.0),
					max(shape_contrast, 0.001)
				);
				float lifetime = mix(
					haze_lifetime_min,
					haze_lifetime_max,
					shape_factor
				);
				float age_ratio = trace_time / max(lifetime, 0.001);
				float survival = 1.0 - smoothstep(
					clamp(haze_lifetime_fade_start, 0.0, 0.999),
					1.0,
					age_ratio
				);
				if (age_ratio >= 1.0) {
					survival = 0.0;
				}
				float radius_ratio = sample_radius / max(sphere_radius, 0.0001);
				float dilution = pow(
					1.0 / max(radius_ratio, 1.0),
					max(haze_dilution_power, 0.0)
				);
				float cyan_source = sample_source_strength(
					source_direction,
					emission_time,
					cyan_seed,
					source_scale,
					source_speed,
					source_min_strength
				);
				float purple_source = sample_source_strength(
					source_direction,
					emission_time,
					purple_seed,
					source_scale,
					source_speed,
					source_min_strength
				);
				float cyan_factor = pow(cyan_source, source_contrast);
				float purple_factor = pow(purple_source, source_contrast);
				cyan_density = cyan_factor * survival * dilution;
				purple_density = purple_factor * survival * dilution;
			}

			float view_dot = abs(dot(radial_direction, view_direction));
			float edge_factor = 1.0 - view_dot;
			float view_weight = mix(
				view_front_visibility,
				1.0,
				pow(clamp(edge_factor, 0.0, 1.0), view_falloff_power)
			);
			float visible_cyan_density = cyan_density * cyan_haze_density * view_weight;
			float visible_purple_density = purple_density * purple_haze_density * view_weight;
			float sample_density = visible_cyan_density + visible_purple_density;
			float sample_alpha = clamp(
				sample_density * step_length / max(sphere_radius, 0.0001) * 0.65 * haze_opacity,
				0.0,
				0.65
			);
			vec3 sample_emission = cyan_color.rgb * visible_cyan_density
				+ purple_color.rgb * visible_purple_density;
			accumulated_emission += sample_emission
				* step_length / max(sphere_radius, 0.0001)
				* haze_emission_strength
				* haze_opacity
				* transmittance;
			transmittance *= 1.0 - sample_alpha;
			}
		}
	}

	ALBEDO = accumulated_emission;
	EMISSION = vec3(0.0);
	ALPHA = 1.0;
}
