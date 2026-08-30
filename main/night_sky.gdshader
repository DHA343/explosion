shader_type sky;
render_mode use_debanding;

uniform vec4 zenith_color : source_color = vec4(0.003, 0.007, 0.025, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.025, 0.045, 0.11, 1.0);
uniform vec4 star_color : source_color = vec4(0.72, 0.82, 1.0, 1.0);
uniform float star_density : hint_range(0.001, 0.03, 0.001) = 0.009;
uniform float star_intensity : hint_range(0.0, 8.0, 0.05) = 2.2;
uniform float milky_way_intensity : hint_range(0.0, 1.0, 0.01) = 0.12;

float hash_21(vec2 value) {
	vec3 value_3 = fract(vec3(value.xyx) * 0.1031);
	value_3 += dot(value_3, value_3.yzx + 33.33);
	return fract((value_3.x + value_3.y) * value_3.z);
}

float value_noise(vec2 position) {
	vec2 cell = floor(position);
	vec2 local_position = fract(position);
	vec2 smooth_position = local_position * local_position * (3.0 - 2.0 * local_position);
	float bottom = mix(hash_21(cell), hash_21(cell + vec2(1.0, 0.0)), smooth_position.x);
	float top = mix(hash_21(cell + vec2(0.0, 1.0)), hash_21(cell + vec2(1.0, 1.0)), smooth_position.x);
	return mix(bottom, top, smooth_position.y);
}

void sky() {
	vec3 direction = normalize(EYEDIR);
	float sky_height = clamp(direction.y * 0.5 + 0.5, 0.0, 1.0);
	float zenith_mix = smoothstep(0.12, 0.92, sky_height);
	vec3 color = mix(horizon_color.rgb, zenith_color.rgb, zenith_mix);

	vec2 spherical_uv = vec2(
		atan(direction.z, direction.x) / TAU + 0.5,
		asin(clamp(direction.y, -1.0, 1.0)) / PI + 0.5
	);
	vec2 star_grid_size = vec2(900.0, 450.0);
	vec2 star_grid_position = spherical_uv * star_grid_size;
	vec2 star_cell = floor(star_grid_position);
	vec2 star_local_position = fract(star_grid_position) - 0.5;

	float star_random = hash_21(star_cell);
	float star_exists = step(1.0 - star_density, star_random);
	float star_radius = mix(0.035, 0.16, hash_21(star_cell + vec2(19.7, 71.3)));
	float star_shape = 1.0 - smoothstep(star_radius, star_radius * 2.2, length(star_local_position));
	float twinkle = mix(0.72, 1.18, 0.5 + 0.5 * sin(TIME * 1.4 + star_random * 47.0));
	float above_horizon = smoothstep(-0.03, 0.12, direction.y);
	float star = star_exists * star_shape * twinkle * above_horizon;

	vec3 galactic_normal = normalize(vec3(0.24, 0.91, 0.34));
	float galactic_distance = abs(dot(direction, galactic_normal));
	float milky_way = pow(max(0.0, 1.0 - galactic_distance * 5.5), 3.0);
	float milky_noise = mix(0.35, 1.0, value_noise(spherical_uv * vec2(240.0, 120.0)));
	milky_way *= milky_noise * above_horizon * milky_way_intensity;

	color += star_color.rgb * star * star_intensity;
	color += vec3(0.18, 0.24, 0.42) * milky_way;
	COLOR = color;
}
