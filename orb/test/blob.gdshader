shader_type spatial;
render_mode unshaded, world_vertex_coords, depth_prepass_alpha;

uniform vec3 sphere_center_world = vec3(0.0);
uniform float sphere_radius = 3.0;

uniform float deform : hint_range(0.0, 1.0) = 0.0;
uniform float final_radial_scale : hint_range(0.05, 1.0) = 0.25;
uniform float final_tangent_scale : hint_range(1.0, 3.0) = 1.6;
uniform float blob_radius = 0.35;
uniform float contact_range : hint_range(0.0, 2.0) = 0.6;
uniform float contact_softness : hint_range(0.01, 1.0) = 0.25;
uniform float adhesion_range : hint_range(0.0, 2.0) = 0.4;
uniform float adhesion_softness : hint_range(0.01, 1.0) = 0.25;
uniform float noise_strength : hint_range(0.0, 0.2) = 0.06;
uniform float noise_frequency : hint_range(0.5, 3.0) = 1.5;
uniform vec3 noise_seed = vec3(0.0);
uniform float tangent_aspect : hint_range(0.75, 1.3) = 1.0;
uniform float tangent_rotation : hint_range(0.0, 6.283185) = 0.0;
uniform vec4 blob_color : source_color = vec4(1.0);
uniform float emission_intensity : hint_range(0.0, 8.0) = 3.0;
uniform float fade : hint_range(0.0, 1.0) = 1.0;

float hash_value(vec3 value) {
	return fract(sin(dot(value, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float value_noise(vec3 position_value) {
	vec3 cell = floor(position_value);
	vec3 fraction = fract(position_value);
	vec3 interpolation = fraction * fraction * (3.0 - 2.0 * fraction);

	float bottom_left = mix(hash_value(cell), hash_value(cell + vec3(1.0, 0.0, 0.0)), interpolation.x);
	float bottom_right = mix(hash_value(cell + vec3(0.0, 1.0, 0.0)), hash_value(cell + vec3(1.0, 1.0, 0.0)), interpolation.x);
	float top_left = mix(hash_value(cell + vec3(0.0, 0.0, 1.0)), hash_value(cell + vec3(1.0, 0.0, 1.0)), interpolation.x);
	float top_right = mix(hash_value(cell + vec3(0.0, 1.0, 1.0)), hash_value(cell + vec3(1.0, 1.0, 1.0)), interpolation.x);
	float bottom = mix(bottom_left, bottom_right, interpolation.y);
	float top = mix(top_left, top_right, interpolation.y);
	return mix(bottom, top, interpolation.z);
}

void vertex() {
	vec3 blob_center = MODEL_MATRIX[3].xyz;

	vec3 radial = normalize(blob_center - sphere_center_world);

	vec3 offset = VERTEX - blob_center;
	float noise_value = value_noise(normalize(offset) * noise_frequency + noise_seed);
	vec3 irregular_offset = offset
		+ normalize(offset) * (noise_value * 2.0 - 1.0) * noise_strength * blob_radius;

	float axial_amount = dot(irregular_offset, radial);

	vec3 axial = radial * axial_amount;
	vec3 tangent = irregular_offset - axial;

	float surface_gap = max(
		sphere_radius - length(blob_center + irregular_offset - sphere_center_world),
		0.0
	);
	float normalized_gap = surface_gap / max(blob_radius, 0.0001);
	float contact_mask = 1.0 - smoothstep(
		contact_range,
		contact_range + contact_softness,
		normalized_gap
	);
	float local_deform = deform * contact_mask;

	float radial_scale = mix(1.0, final_radial_scale, local_deform);
	float tangent_scale = mix(1.0, final_tangent_scale, local_deform);
	vec3 reference_axis = vec3(0.0, 1.0, 0.0);

	if (abs(radial.y) > 0.99) {
		reference_axis = vec3(1.0, 0.0, 0.0);
	}

	vec3 tangent_axis_a = normalize(cross(reference_axis, radial));
	vec3 tangent_axis_b = cross(radial, tangent_axis_a);
	vec3 rotated_axis_a = tangent_axis_a * cos(tangent_rotation)
		+ tangent_axis_b * sin(tangent_rotation);
	vec3 rotated_axis_b = cross(radial, rotated_axis_a);
	float tangent_a = dot(tangent, rotated_axis_a);
	float tangent_b = dot(tangent, rotated_axis_b);

	vec3 deformed_offset =
		axial * radial_scale
		+ rotated_axis_a * tangent_a * tangent_scale * tangent_aspect
		+ rotated_axis_b * tangent_b * tangent_scale / tangent_aspect;

	vec3 p = blob_center + deformed_offset;

	vec3 sphere_offset = p - sphere_center_world;
	float sphere_distance = length(sphere_offset);
	vec3 surface_position = sphere_center_world
		+ sphere_offset / sphere_distance
		* sphere_radius;
	float adhesion_surface_gap = sphere_radius - sphere_distance;
	float normalized_surface_gap = adhesion_surface_gap / max(blob_radius, 0.0001);
	float adhesion_proximity = 1.0 - smoothstep(
		adhesion_range,
		adhesion_range + adhesion_softness,
		normalized_surface_gap
	);
	float adhesion = max(
		adhesion_proximity * local_deform,
		step(sphere_radius, sphere_distance)
	);
	p = mix(p, surface_position, adhesion);

	VERTEX = p;
}

void fragment() {
	ALBEDO = blob_color.rgb;
	EMISSION = blob_color.rgb * emission_intensity * fade;
	ALPHA = fade;
}
