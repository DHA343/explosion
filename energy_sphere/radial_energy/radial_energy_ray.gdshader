shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

uniform float emission_energy : hint_range(0.0, 8.0) = 2.6;
uniform float density_power : hint_range(0.2, 2.0) = 1.25;
uniform float opacity : hint_range(0.0, 1.0) = 0.14;

const float CAP_LENGTH = 0.0425;

uniform float inner_thickness_ratio = 0.45;
uniform float taper_power = 1.35;

varying vec4 ray_data;

void vertex() {
	ray_data = INSTANCE_CUSTOM;
	vec3 original_vertex = VERTEX;
	vec3 original_normal = NORMAL;
	float axial_scale = 1.0;
	if (ray_data.r < CAP_LENGTH * 2.0) {
		VERTEX.y *= ray_data.r;
		axial_scale = ray_data.r;
	} else if (VERTEX.y > 1.0 - CAP_LENGTH) {
		VERTEX.y += ray_data.r - 1.0;
	} else if (VERTEX.y > CAP_LENGTH) {
		float body_progress = (ray_data.r - CAP_LENGTH * 2.0) / (1.0 - CAP_LENGTH * 2.0);
		VERTEX.y = CAP_LENGTH + (VERTEX.y - CAP_LENGTH) * body_progress;
		axial_scale = body_progress;
	}

	float longitudinal = min(UV.y, 1.0 - CAP_LENGTH);
	float taper = pow(longitudinal, taper_power);
	float thickness_profile = mix(inner_thickness_ratio, 1.0, taper);
	float thickness = ray_data.g * thickness_profile;
	float profile_rate = 0.0;
	if (UV.y < 1.0 - CAP_LENGTH) {
		profile_rate = (1.0 - inner_thickness_ratio) * taper_power
			* pow(max(UV.y, 0.0001), taper_power - 1.0);
	}
	VERTEX.xz *= thickness;

	float normal_thickness = max(thickness, 0.0001);
	float normal_axial_scale = max(axial_scale, 0.0001);
	float normal_profile = max(thickness_profile, 0.0001);
	vec3 transformed_normal = vec3(
		original_normal.x / normal_thickness,
		original_normal.y / normal_axial_scale,
		original_normal.z / normal_thickness
	);
	transformed_normal.y -= profile_rate * (
		original_vertex.x * original_normal.x + original_vertex.z * original_normal.z
	) / (normal_profile * normal_axial_scale);
	NORMAL = normalize(transformed_normal);
}

void fragment() {
	float view_thickness = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float density = pow(clamp(view_thickness, 0.0, 1.0), density_power);
	density = smoothstep(0.06, 0.96, density);
	float luminous_density = density * mix(0.32, 1.0, density);
	float strength = COLOR.r * ray_data.b;

	ALBEDO = vec3(1.0) * luminous_density * strength;
	EMISSION = vec3(1.0) * emission_energy * luminous_density * strength;
	ALPHA = clamp(luminous_density * strength * opacity, 0.0, 0.26);
}
