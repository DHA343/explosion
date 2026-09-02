shader_type spatial;

render_mode unshaded, blend_add, cull_disabled, depth_draw_never, depth_test_disabled;

const int MAX_FILAMENTS = 16;

uniform float core_radius : hint_range(0.2, 0.6, 0.01) = 0.4;
uniform float surface_radius : hint_range(0.75, 1.0, 0.01) = 0.94;
uniform int filament_count : hint_range(1, 16, 1) = 14;
uniform float filament_body_width : hint_range(0.045, 0.065, 0.001) = 0.052;
uniform float filament_core_width : hint_range(0.022, 0.035, 0.001) = 0.028;
uniform float filament_softness : hint_range(0.002, 0.05, 0.001) = 0.014;
uniform float bend_strength : hint_range(0.0, 0.12, 0.001) = 0.045;
uniform float tip_bulge : hint_range(0.0, 1.0, 0.01) = 0.7;
uniform float width_variation : hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float source_lobe_size : hint_range(0.02, 0.15, 0.005) = 0.09;
uniform float source_lobe_strength : hint_range(0.0, 1.5, 0.05) = 0.8;

uniform float interaction_distance : hint_range(0.02, 0.3, 0.01) = 0.15;
uniform float contact_tangent_size : hint_range(0.03, 0.3, 0.01) = 0.12;
uniform float contact_radial_size : hint_range(0.01, 0.15, 0.005) = 0.045;
uniform float contact_softness : hint_range(0.005, 0.08, 0.001) = 0.025;
uniform float bridge_width : hint_range(0.005, 0.08, 0.001) = 0.032;
uniform float bridge_softness : hint_range(0.005, 0.08, 0.001) = 0.03;
uniform float bridge_strength : hint_range(0.0, 1.5, 0.05) = 1.0;
uniform float contact_color_mix : hint_range(0.0, 2.0, 0.05) = 0.65;
uniform float contact_emission_gain : hint_range(0.0, 4.0, 0.05) = 2.6;

uniform float effect_time = 0.0;
uniform float animation_speed : hint_range(0.0, 6.0, 0.05) = 5.8;
uniform float growth_ratio : hint_range(0.1, 0.6, 0.01) = 0.42;
uniform float contact_ratio : hint_range(0.3, 0.8, 0.01) = 0.45;
uniform float dissolve_ratio : hint_range(0.6, 0.95, 0.01) = 0.8;
uniform float centerline_motion_strength : hint_range(0.0, 0.05, 0.001) = 0.012;
uniform float centerline_motion_speed : hint_range(0.0, 2.0, 0.05) = 0.9;
uniform float shape_instability_strength : hint_range(0.0, 0.5, 0.01) = 0.22;
uniform float shape_instability_speed : hint_range(0.0, 2.0, 0.05) = 1.15;

uniform float breakup_strength : hint_range(0.0, 1.0, 0.01) = 0.62;
uniform float breakup_scale : hint_range(1.0, 10.0, 0.1) = 5.0;
uniform float breakup_speed : hint_range(0.0, 2.0, 0.05) = 0.95;

uniform float random_seed : hint_range(0.0, 100.0, 0.1) = 17.0;
uniform float reach_variation : hint_range(0.0, 0.3, 0.01) = 0.15;
uniform float lifetime_variation : hint_range(0.0, 0.6, 0.01) = 0.25;
uniform float contact_onset_variation : hint_range(0.0, 0.2, 0.01) = 0.12;

uniform vec4 filament_body_color : source_color = vec4(0.25, 0.7, 1.0, 1.0);
uniform vec4 filament_core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 contact_color : source_color = vec4(0.85, 0.92, 1.2, 1.0);
uniform float filament_body_emission : hint_range(0.0, 10.0, 0.1) = 2.5;
uniform float filament_core_emission : hint_range(0.0, 10.0, 0.1) = 5.0;


float hash_11(float value) {
	return fract(sin(value * 127.1 + random_seed * 31.7) * 43758.5453);
}


float value_noise(float value) {
	float cell = floor(value);
	float fraction = fract(value);
	float eased = fraction * fraction * (3.0 - 2.0 * fraction);
	return mix(hash_11(cell), hash_11(cell + 1.0), eased);
}


float soft_union(float first_field, float second_field) {
	return 1.0 - (1.0 - first_field) * (1.0 - second_field);
}


void vertex() {
	mat4 billboard_world = mat4(
		vec4(normalize(INV_VIEW_MATRIX[0].xyz) * length(MODEL_MATRIX[0].xyz), 0.0),
		vec4(normalize(INV_VIEW_MATRIX[1].xyz) * length(MODEL_MATRIX[1].xyz), 0.0),
		vec4(normalize(INV_VIEW_MATRIX[2].xyz) * length(MODEL_MATRIX[2].xyz), 0.0),
		MODEL_MATRIX[3]
	);
	MODELVIEW_MATRIX = VIEW_MATRIX * billboard_world;
}


void fragment() {
	vec2 field_position = (UV - vec2(0.5)) * 2.0;
	float field_radius = length(field_position);
	float body_field = 0.0;
	float core_field = 0.0;
	float contact_field = 0.0;
	float body_brightness_field = 0.0;
	float core_brightness_field = 0.0;
	float contact_brightness_field = 0.0;
	float contact_peak_field = 0.0;
	float active_time = effect_time * animation_speed;

	for (int index = 0; index < MAX_FILAMENTS; index++) {
		if (index < filament_count) {
			float slot_identity = float(index) + random_seed * 0.173;
			float life_scale = mix(1.0 - lifetime_variation, 1.0 + lifetime_variation,
				hash_11(slot_identity + 4.7));
			float phase_offset = hash_11(slot_identity + 8.9) * 3.0;
			float cycle_time = active_time / max(life_scale, 0.1) + phase_offset;
			float cycle_index = floor(cycle_time);
			float life_phase = fract(cycle_time);
			float event_identity = slot_identity + cycle_index * 53.173;

			float angle = hash_11(event_identity + 1.3) * PI * 2.0;
			vec2 radial_direction = vec2(cos(angle), sin(angle));
			vec2 tangent_direction = vec2(-radial_direction.y, radial_direction.x);
			float radial_position = dot(field_position, radial_direction);
			float tangent_position = dot(field_position, tangent_direction);
			float fade_in = smoothstep(0.0, 0.06, life_phase);
			float fade_out = 1.0 - smoothstep(0.7, 0.92, life_phase);
			float event_visibility = fade_in * fade_out;

			float width_selector = hash_11(event_identity + 10.3);
			float body_width_random = hash_11(event_identity + 42.7);
			float core_width_random = hash_11(event_identity + 46.1);
			float event_body_width_multiplier = 1.0;
			float event_core_width_multiplier = 1.0;
			float event_mass = 0.15;
			if (width_selector < 0.25) {
				event_body_width_multiplier = mix(0.75, 1.05, body_width_random);
				event_core_width_multiplier = mix(0.85, 1.0, core_width_random);
			} else if (width_selector < 0.7) {
				event_body_width_multiplier = mix(1.15, 1.7, body_width_random);
				event_core_width_multiplier = mix(1.0, 1.2, core_width_random);
				event_mass = 0.55;
			} else {
				event_body_width_multiplier = mix(1.85, 2.6, body_width_random);
				event_core_width_multiplier = mix(1.2, 1.45, core_width_random);
				event_mass = 1.0;
			}
			event_body_width_multiplier = mix(1.0, event_body_width_multiplier,
				width_variation);
			event_core_width_multiplier = mix(1.0, event_core_width_multiplier,
				width_variation);
			float reach_offset = (hash_11(event_identity + 12.1) * 2.0 - 1.0)
				* reach_variation;
			float maximum_reach = surface_radius * (0.92 + reach_offset);
			float growth = smoothstep(0.04, growth_ratio, life_phase);
			float tip_radius = mix(core_radius - 0.08, maximum_reach, growth);
			float tip_instability = value_noise(event_identity * 11.4
				+ active_time * shape_instability_speed) * 2.0 - 1.0;
			tip_radius += tip_instability * filament_body_width * shape_instability_strength;
			float shell_distance = surface_radius - tip_radius;
			float contact_offset = (hash_11(event_identity + 16.4) * 2.0 - 1.0)
				* contact_onset_variation;
			float contact_proximity = 1.0 - smoothstep(0.0, interaction_distance,
				shell_distance - contact_offset);
			float contact_timing = smoothstep(contact_ratio - 0.11, contact_ratio + 0.03,
				life_phase + contact_offset * 0.35);
			float contact_growth = contact_proximity * contact_timing;

			float root_radius = core_radius - 0.13;
			float filament_length = max(tip_radius - root_radius, 0.01);
			float along_filament = clamp((radial_position - root_radius) / filament_length,
				0.0, 1.0);
			float bend_phase = hash_11(event_identity + 22.8) * PI * 2.0;
			float bend_direction = hash_11(event_identity + 25.2) * 2.0 - 1.0;
			float event_bend = bend_strength * mix(0.75, 1.15,
				hash_11(event_identity + 27.9));
			float static_curve = bend_direction * event_bend * sin(along_filament * PI)
				* (0.72 + 0.28 * sin(bend_phase + along_filament * 2.3));
			float temporal_curve_noise = value_noise(event_identity * 9.7
				+ along_filament * 1.8 + active_time * centerline_motion_speed);
			float temporal_curve = (temporal_curve_noise * 2.0 - 1.0)
				* centerline_motion_strength * sin(along_filament * PI);
			float curve_offset = static_curve + temporal_curve;
			float instability_noise = value_noise(along_filament * 3.2
				+ event_identity * 7.1 + active_time * shape_instability_speed);
			float ambient_instability = mix(1.0 - shape_instability_strength,
				1.0 + shape_instability_strength, instability_noise);
			float shape_noise = value_noise(along_filament * 3.5 + event_identity * 7.1
				+ active_time * shape_instability_speed * 0.45);
			float local_width_variation = mix(0.75, 1.25, shape_noise);
			float source_body = exp(-pow((along_filament - 0.16) / 0.22, 2.0));
			float body_pulse = exp(-pow((along_filament - 0.32) / 0.18, 2.0));
			float middle_neck = exp(-pow((along_filament - 0.56) / 0.2, 2.0));
			float width_profile = mix(1.08, 0.72,
				smoothstep(0.05, 0.68, along_filament));
			width_profile += smoothstep(0.72, 1.0, along_filament) * 0.12;
			width_profile *= 1.0 + event_mass * (source_body * 0.38 + body_pulse * 0.28);
			width_profile *= 1.0 - event_mass * middle_neck * 0.38;
			float tip_expansion = 1.0 + tip_bulge * contact_growth
				* smoothstep(0.68, 1.0, along_filament);
			float detach_phase = smoothstep(0.62, 0.84, life_phase);
			float tip_neck_region = smoothstep(0.7, 0.96, along_filament);
			float tip_detach_width = mix(1.0, 0.28, detach_phase * tip_neck_region);
			float breakup_phase = smoothstep(dissolve_ratio, 0.96, life_phase);
			float breakup_noise = value_noise(along_filament * breakup_scale
				+ event_identity * 13.6 + active_time * breakup_speed);
			float unstable_width = mix(1.0, 0.18 + breakup_noise * 0.82,
				breakup_phase * breakup_strength);
			float body_current_width = filament_body_width * event_body_width_multiplier
				* local_width_variation
				* width_profile * tip_expansion * ambient_instability * unstable_width
				* tip_detach_width;
			float core_current_width = filament_core_width * event_core_width_multiplier
				* mix(0.86, 1.12, shape_noise) * width_profile
				* mix(1.0, tip_expansion, 0.38) * mix(0.94, 1.06, instability_noise)
				* unstable_width * mix(1.0, 0.38, detach_phase * tip_neck_region);

			float edge_noise = value_noise(along_filament * 6.0 + event_identity * 9.2
				- active_time * shape_instability_speed);
			float transverse_distance = abs(tangent_position - curve_offset)
				* mix(0.9, 1.1, edge_noise);
			float normalized_body_width = transverse_distance
				/ max(body_current_width + filament_softness * 0.25, 0.001);
			float normalized_core_width = transverse_distance
				/ max(core_current_width + filament_softness * 0.08, 0.001);
			float filament_body_mask = exp(-normalized_body_width
				* normalized_body_width * 1.1);
			float filament_core_mask = exp(-normalized_core_width
				* normalized_core_width * 1.5);
			float flow_noise = value_noise(along_filament * 2.4 + event_identity * 5.6
				+ active_time * shape_instability_speed * 0.72);
			float stream_noise = value_noise(along_filament * 5.2
				+ event_identity * 8.4 - active_time * shape_instability_speed * 0.9);
			float body_cohesion = mix(0.64, 1.0,
				smoothstep(0.18, 0.78, stream_noise));
			float core_cohesion = mix(0.18, 1.0,
				smoothstep(0.3, 0.72, stream_noise));
			filament_body_mask *= mix(0.72, 1.0, flow_noise) * body_cohesion;
			filament_core_mask *= mix(0.78, 1.0, flow_noise) * core_cohesion;
			float root_fade = smoothstep(root_radius - 0.02, core_radius + 0.07,
				radial_position);
			float tip_fade = 1.0 - smoothstep(tip_radius - filament_softness * 1.5,
				tip_radius + filament_softness, radial_position);
			float forward_mask = smoothstep(root_radius - 0.04, root_radius,
				radial_position);
			filament_body_mask *= root_fade * tip_fade * forward_mask;
			filament_core_mask *= root_fade * tip_fade * forward_mask;

			float breakup_threshold = mix(0.18, 0.72, breakup_phase * breakup_strength);
			float continuity = smoothstep(breakup_threshold - 0.13,
				breakup_threshold + 0.08, breakup_noise);
			filament_body_mask *= mix(1.0, continuity, breakup_phase);
			filament_core_mask *= mix(1.0, continuity, breakup_phase);
			filament_body_mask *= event_visibility;
			filament_core_mask *= event_visibility;

			float tip_drift = (value_noise(event_identity * 5.9
				+ active_time * shape_instability_speed * 0.5) * 2.0 - 1.0)
				* filament_body_width * mix(0.6, 1.4, event_mass);
			float tip_size = filament_body_width * event_body_width_multiplier
				* mix(1.0, 1.45, event_mass) + filament_softness * 0.7;
			vec2 tip_coordinate = vec2(
				(tangent_position - tip_drift) / max(tip_size, 0.001),
				(radial_position - tip_radius) / max(tip_size * 0.95, 0.001)
			);
			float tip_lobe_mask = exp(-dot(tip_coordinate, tip_coordinate) * 1.15);
			tip_lobe_mask *= smoothstep(0.16, growth_ratio, life_phase)
				* mix(0.38, 0.82, event_mass) * event_visibility
				* (1.0 - smoothstep(0.6, 0.8, life_phase));

			float source_size_random = hash_11(event_identity + 29.4);
			float source_width_influence = mix(0.85, 1.0, source_size_random);
			if (width_selector >= 0.25 && width_selector < 0.7) {
				source_width_influence = mix(1.0, 1.15, source_size_random);
			} else if (width_selector >= 0.7) {
				source_width_influence = mix(1.15, 1.35, source_size_random);
			}
			float source_size = source_lobe_size * source_width_influence
				* mix(0.9, 1.1, instability_noise);
			float source_push = smoothstep(0.0, growth_ratio, life_phase);
			float source_center = core_radius + 0.015 + source_push * 0.045;
			vec2 source_coordinate = vec2(
				tangent_position / max(source_size, 0.001),
				(radial_position - source_center) / max(source_size * 0.9, 0.001)
			);
			float source_lobe_mask = exp(-dot(source_coordinate, source_coordinate) * 1.35);
			float source_linger = mix(1.0, 0.35,
				smoothstep(growth_ratio + 0.06, dissolve_ratio + 0.06, life_phase));
			source_lobe_mask *= source_lobe_strength * event_visibility * source_linger;

			float tangent_extent = contact_tangent_size
				* mix(0.72, 1.28, hash_11(event_identity + 31.7));
			float radial_extent = contact_radial_size
				* mix(0.78, 1.2, hash_11(event_identity + 35.1));
			tangent_extent *= mix(0.92, 1.08, event_mass);
			float contact_instability = mix(0.94, 1.06, value_noise(event_identity * 4.3
				+ active_time * shape_instability_speed));
			tangent_extent *= contact_instability;
			radial_extent /= contact_instability;
			float curved_shell_radius = sqrt(max(surface_radius * surface_radius
				- tangent_position * tangent_position, 0.0));
			float inward_distance = curved_shell_radius - radial_position;
			float contact_axis = tangent_position / max(tangent_extent, 0.001);
			float contact_surface_noise = value_noise(contact_axis * 1.7
				+ event_identity * 6.2 + active_time * shape_instability_speed * 0.4);
			float contact_surface_offset = (contact_surface_noise * 2.0 - 1.0)
				* radial_extent * shape_instability_strength * 0.8;
			vec2 contact_coordinate = vec2(contact_axis,
				(inward_distance - radial_extent * 0.32 - contact_surface_offset)
				/ max(radial_extent, 0.001));
			float contact_distance = length(contact_coordinate);
			float contact_mask = exp(-contact_distance * contact_distance * 1.1);
			contact_mask *= 1.0 - smoothstep(0.82, 1.0 + contact_softness
				/ max(radial_extent, 0.001), contact_distance);
			float inside_shell = 1.0 - smoothstep(surface_radius,
				surface_radius + contact_softness, field_radius);
			float contact_peak = smoothstep(0.34, 0.45, life_phase)
				* (1.0 - smoothstep(0.65, 0.78, life_phase));
			float contact_fade = 1.0 - smoothstep(0.78, 0.93, life_phase);
			contact_mask *= contact_growth * contact_fade * inside_shell;

			float contact_anchor = surface_radius - radial_extent * 0.3;
			float bridge_gap = max(contact_anchor - tip_radius, 0.0);
			float bridge_center = (tip_radius + contact_anchor) * 0.5;
			float bridge_radial_extent = max(bridge_gap * 0.56 + bridge_softness * 0.35,
				bridge_softness);
			float bridge_event_width = bridge_width * mix(0.72, 1.3,
				hash_11(event_identity + 37.8));
			bridge_event_width *= mix(0.85, 1.2, event_mass);
			bridge_event_width *= mix(0.9, 1.1, instability_noise);
			float bridge_along = clamp((radial_position - tip_radius)
				/ max(contact_anchor - tip_radius, 0.001), 0.0, 1.0);
			float bridge_end_proximity = abs(bridge_along * 2.0 - 1.0);
			float bridge_neck_profile = mix(0.55, 1.0,
				smoothstep(0.08, 0.9, bridge_end_proximity));
			float bridge_detach_width = mix(1.0, 0.2, detach_phase);
			vec2 bridge_coordinate = vec2(
				tangent_position / max(bridge_event_width * bridge_neck_profile
					* bridge_detach_width
					+ bridge_softness * 0.2, 0.001),
				(radial_position - bridge_center) / max(bridge_radial_extent, 0.001)
			);
			float bridge_distance = length(bridge_coordinate);
			float bridge_mask = exp(-bridge_distance * bridge_distance * 1.15);
			bridge_mask *= 1.0 - smoothstep(1.15, 1.75, bridge_distance);
			float bridge_growth = smoothstep(0.05, 0.85, contact_proximity)
				* max(contact_timing, contact_growth);
			bridge_mask *= bridge_strength * bridge_growth * event_visibility;

			float tip_core_mask = pow(clamp(tip_lobe_mask, 0.0, 1.0), 1.75) * 0.72;
			float bridge_core_mask = pow(clamp(bridge_mask, 0.0, 1.0), 1.65) * 0.78;
			float source_core_mask = pow(clamp(source_lobe_mask, 0.0, 1.0), 1.8) * 0.58;
			float local_body_field = soft_union(source_lobe_mask, filament_body_mask);
			local_body_field = soft_union(local_body_field, tip_lobe_mask);
			local_body_field = soft_union(local_body_field, bridge_mask);
			local_body_field = soft_union(local_body_field, contact_mask * 0.55);
			float local_core_field = soft_union(source_core_mask, filament_core_mask);
			local_core_field = soft_union(local_core_field, tip_core_mask);
			local_core_field = soft_union(local_core_field, bridge_core_mask);

			float brightness_selector = hash_11(event_identity + 50.8);
			float brightness_random = hash_11(event_identity + 54.2);
			float brightness = mix(0.45, 0.7, brightness_random);
			if (brightness_selector >= 0.25 && brightness_selector < 0.75) {
				brightness = mix(0.75, 1.05, brightness_random);
			} else if (brightness_selector >= 0.75) {
				brightness = mix(1.15, 1.5, brightness_random);
			}
			body_field = soft_union(body_field, local_body_field);
			core_field = soft_union(core_field, local_core_field);
			contact_field = soft_union(contact_field, contact_mask);
			body_brightness_field = max(body_brightness_field,
				local_body_field * brightness);
			core_brightness_field = max(core_brightness_field,
				local_core_field * brightness);
			contact_brightness_field = max(contact_brightness_field,
				contact_mask * brightness);
			contact_peak_field = max(contact_peak_field, contact_mask * contact_peak);
		}
	}

	float circular_fade = 1.0 - smoothstep(surface_radius,
		surface_radius + contact_softness, field_radius);
	body_field *= circular_fade;
	core_field *= circular_fade;
	contact_field *= circular_fade;
	float body_brightness = clamp(body_brightness_field / max(body_field, 0.001),
		0.45, 1.5);
	float core_brightness = clamp(core_brightness_field / max(core_field, 0.001),
		0.45, 1.5);
	float contact_brightness = clamp(contact_brightness_field
		/ max(contact_field, 0.001), 0.45, 1.5);
	float contact_peak = clamp(contact_peak_field / max(contact_field, 0.001), 0.0, 1.0);
	float contact_core = pow(clamp(contact_field, 0.0, 1.0), 1.45);
	vec3 contact_energy_color = mix(filament_core_color.rgb, contact_color.rgb,
		clamp(contact_color_mix, 0.0, 1.0));
	vec3 body_energy = filament_body_color.rgb * body_field
		* filament_body_emission * body_brightness;
	vec3 core_energy = filament_core_color.rgb * core_field
		* filament_core_emission * core_brightness;
	vec3 contact_energy = contact_energy_color * contact_core
		* filament_body_emission * contact_brightness
		* (1.0 + contact_peak * contact_emission_gain);
	ALBEDO = filament_body_color.rgb * body_field * 0.45
		+ filament_core_color.rgb * core_field * 0.55
		+ contact_energy_color * contact_core * 0.55;
	EMISSION = body_energy + core_energy + contact_energy;
	ALPHA = clamp(max(max(body_field, core_field), contact_field) * 0.92, 0.0, 1.0);
}
