shader_type spatial;

uniform vec4 color_a : source_color = vec4(1.0);
uniform vec4 color_b : source_color = vec4(1.0);

uniform float distortion_strength : hint_range(0.0, 0.5, 0.01) = 0.1;
uniform float noise_scale : hint_range(0.1, 10.0, 0.01) = 1.0;
uniform float noise_speed : hint_range(0.0, 5.0, 0.01) = 1.0;
uniform sampler3D noise_texture : repeat_enable;

uniform float sphere_radius : hint_range(0.01, 1.0, 0.01) = 0.5;
uniform float core_ratio : hint_range(0.01, 1.0, 0.01) = 0.3;
uniform float intensity : hint_range(0.1, 16.0, 0.01) = 2.0;

uniform float core_ratio_modulation_amount : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float intensity_modulation_amount : hint_range(0.0, 4.0, 0.01) = 0.0;
uniform float modulation_speed : hint_range(0.0, 10.0, 0.1) = 2.0;
uniform float modulation_noise_speed : hint_range(0.0, 10.0, 0.01) = 3.0;
uniform float noise_amount : hint_range(0.0, 1.0, 0.01) = 1.0;

uniform float color_bias : hint_range(0.1, 4.0, 0.01) = 1.0;


float get_core_modulation() {
	float periodic_wave = sin(TIME * modulation_speed);
	float noise_wave = texture(
		noise_texture,
		vec3(0.371, 0.617, fract(TIME * modulation_noise_speed))
	).r * 2.0 - 1.0;

	return periodic_wave + noise_wave * noise_amount;
}


void fragment() {
	vec3 p = VERTEX - NODE_POSITION_VIEW;
	float along = dot(p, VIEW);
	vec3 radial = p - VIEW * along;
	float radial_distance = length(radial);

	vec2 uv = radial.xy / (sphere_radius * 2.0) + vec2(0.5);
	vec2 scaled_uv = (uv - vec2(0.5)) * noise_scale + vec2(0.5);
	vec3 noise_coord = vec3(
		scaled_uv,
		TIME * noise_speed
	);
	float distortion_noise = texture(noise_texture, noise_coord).r;

	float core_modulation = get_core_modulation();
	float modulation_range = 1.0 + noise_amount;
	float color_mix = clamp(
		core_modulation / modulation_range * 0.5 + 0.5,
		0.0,
		1.0
	);
	color_mix = pow(color_mix, color_bias);

	float modulated_core_ratio = core_ratio + core_modulation * core_ratio_modulation_amount;
	float modulated_intensity = intensity + core_modulation * intensity_modulation_amount;

	float core_radius = max(
		sphere_radius * modulated_core_ratio,
		0.0001
	);

	float signed_noise = distortion_noise * 2.0 - 1.0;
	float radius_scale = max(
		1.0 + signed_noise * distortion_strength,
		0.05
	);
	float distorted_radius = core_radius * radius_scale;

	float normalized_distance = radial_distance / distorted_radius;
	float glow = exp(-(normalized_distance * normalized_distance));

	vec3 core_color = mix(
		color_a.rgb,
		color_b.rgb,
		color_mix
	);

	ALBEDO = vec3(0.0);
	EMISSION = core_color * glow * modulated_intensity;
	ALPHA = glow;
}