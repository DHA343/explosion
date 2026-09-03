shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

uniform float emission_energy : hint_range(0.0, 8.0) = 2.6;
uniform float density_power : hint_range(0.2, 2.0) = 1.25;
uniform float opacity : hint_range(0.0, 1.0) = 0.14;
uniform float tip_softness : hint_range(0.0, 1.0) = 0.1;

varying vec4 ray_data;

void vertex() {
	ray_data = INSTANCE_CUSTOM;
	VERTEX.xz *= ray_data.g;
	NORMAL.xz *= ray_data.g;
	NORMAL = normalize(NORMAL);
}

void fragment() {
	float length_mask = 1.0 - smoothstep(
		ray_data.r - tip_softness,
		ray_data.r,
		UV.y
	);
	float view_thickness = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float density = pow(clamp(view_thickness, 0.0, 1.0), density_power);
	density = smoothstep(0.06, 0.96, density);
	float luminous_density = density * mix(0.32, 1.0, density);
	float strength = length_mask * COLOR.r * ray_data.b;

	ALBEDO = vec3(1.0) * luminous_density * strength;
	EMISSION = vec3(1.0) * emission_energy * luminous_density * strength;
	ALPHA = clamp(luminous_density * strength * opacity, 0.0, 0.26);
}
