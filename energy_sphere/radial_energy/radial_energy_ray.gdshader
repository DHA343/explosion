shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

uniform float emission_energy : hint_range(0.0, 8.0) = 2.6;
uniform float density_power : hint_range(0.2, 2.0) = 1.25;
uniform float opacity : hint_range(0.0, 1.0) = 0.14;

const float CAP_LENGTH = 0.0425;
const float INNER_THICKNESS_RATIO = 0.45;
const float TAPER_POWER = 1.35;

varying vec4 ray_data;

void vertex() {
	ray_data = INSTANCE_CUSTOM;
	if (ray_data.r < CAP_LENGTH * 2.0) {
		VERTEX.y *= ray_data.r;
	} else if (VERTEX.y > 1.0 - CAP_LENGTH) {
		VERTEX.y += ray_data.r - 1.0;
	} else if (VERTEX.y > CAP_LENGTH) {
		float body_progress = (ray_data.r - CAP_LENGTH * 2.0) / (1.0 - CAP_LENGTH * 2.0);
		VERTEX.y = CAP_LENGTH + (VERTEX.y - CAP_LENGTH) * body_progress;
	}

	float taper = pow(UV.y, TAPER_POWER);
	float thickness_profile = mix(INNER_THICKNESS_RATIO, 1.0, taper);
	float cap_scale = min(ray_data.r / (CAP_LENGTH * 2.0), 1.0);
	float thickness = ray_data.g * thickness_profile * cap_scale;
	VERTEX.xz *= thickness;
	NORMAL.xz *= thickness;
	NORMAL = normalize(NORMAL);
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
