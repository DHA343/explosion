shader_type spatial;

render_mode unshaded, blend_premul_alpha, depth_draw_always;

uniform sampler2D captured_texture : filter_linear, repeat_disable;
uniform sampler3D distortion_noise : filter_linear, repeat_enable;

uniform float distortion_strength : hint_range(0.0, 0.02, 0.0005) = 0.007;
uniform float distortion_scale : hint_range(0.25, 8.0, 0.05) = 0.6;
uniform float distortion_evolution_speed : hint_range(0.0, 50.0, 1.0) = 10.0;

varying vec3 local_surface_direction;


void vertex() {
	local_surface_direction = normalize(NORMAL);
}


void fragment() {
	vec3 p =
		normalize(local_surface_direction)
		* distortion_scale;

	float n0 = texture(
		distortion_noise,
		p + vec3(0.17, 0.41, 0.73)
	).r;

	float n1 = texture(
		distortion_noise,
		p + vec3(0.63, 0.19, 0.37)
	).r;

	float n2 = texture(
		distortion_noise,
		p + vec3(0.31, 0.83, 0.11)
	).r;

	float n3 = texture(
		distortion_noise,
		p + vec3(0.79, 0.53, 0.67)
	).r;

	float n4 = texture(
		distortion_noise,
		p + vec3(0.47, 0.13, 0.89)
	).r;

	float n5 = texture(
		distortion_noise,
		p + vec3(0.07, 0.71, 0.43)
	).r;

	float n6 = texture(
		distortion_noise,
		p + vec3(0.91, 0.29, 0.59)
	).r;

	float n7 = texture(
		distortion_noise,
		p + vec3(0.37, 0.97, 0.23)
	).r;

	float x0 = n0 - n1;
	float x1 = n2 - n3;

	float y0 = n4 - n5;
	float y1 = n6 - n7;

	float t =
		TIME * distortion_evolution_speed;

	float tx = t;
	float ty = t * 0.87 + 1.37;

	float distortion_x =
		(
			x0 * cos(tx)
			+ x1 * sin(tx)
		)
		* 0.70710678;

	float distortion_y =
		(
			y0 * cos(ty)
			+ y1 * sin(ty)
		)
		* 0.70710678;

	vec2 distortion_offset =
		vec2(
			distortion_x,
			distortion_y
		)
		* distortion_strength
		* vec2(0.5625, 1.0);

	vec2 sample_uv =
		SCREEN_UV
		+ distortion_offset;

	vec4 source =
		texture(
			captured_texture,
			sample_uv
		);

	ALBEDO = source.rgb;
	ALPHA = source.a;
}
