shader_type spatial;
render_mode unshaded, world_vertex_coords, blend_add, depth_prepass_alpha;

uniform vec3 sphere_center_world = vec3(0.0);
uniform float sphere_radius = 0.5;

uniform float deform : hint_range(0.0, 1.0) = 0.0;
uniform float impact_strength : hint_range(0.0, 1.0) = 0.7;
uniform vec4 blob_color : source_color = vec4(1.0);
uniform float emission_intensity : hint_range(0.0, 8.0) = 2.0;
uniform float fade : hint_range(0.0, 1.0) = 1.0;

void vertex() {
	vec3 blob_center = MODEL_MATRIX[3].xyz;
	vec3 radial = normalize(blob_center - sphere_center_world);
	vec3 offset = VERTEX - blob_center;
	vec3 axial = radial * dot(offset, radial);
	vec3 tangent = offset - axial;
	float final_radial_scale = mix(1.0, 0.35, impact_strength);
	float final_tangent_scale = mix(1.0, 1.5, impact_strength);
	float radial_scale = mix(1.0, final_radial_scale, deform);
	float tangent_scale = mix(1.0, final_tangent_scale, deform);
	vec3 p = blob_center + axial * radial_scale + tangent * tangent_scale;
	vec3 sphere_offset = p - sphere_center_world;
	float sphere_distance = length(sphere_offset);

	if (sphere_distance > sphere_radius) {
		p = sphere_center_world + sphere_offset / sphere_distance * sphere_radius;
	}

	VERTEX = p;
}

void fragment() {
	ALBEDO = blob_color.rgb;
	EMISSION = blob_color.rgb * emission_intensity * fade;
	ALPHA = fade;
}
