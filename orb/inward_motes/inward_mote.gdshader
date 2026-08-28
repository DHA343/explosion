shader_type spatial;
render_mode unshaded, blend_add, cull_disabled;

uniform vec4 blob_color : source_color = vec4(1.0);
uniform float emission_intensity : hint_range(0.0, 8.0, 0.1) = 2.4;
uniform float edge_softness : hint_range(0.01, 1.0, 0.01) = 0.25;

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
	vec2 centered_uv = UV - vec2(0.5);
	float radial_distance = length(centered_uv) * 2.0;
	float softness_start = max(1.0 - edge_softness, 0.0);
	float edge_alpha = 1.0 - smoothstep(softness_start, 1.0, radial_distance);
	float opacity = edge_alpha * COLOR.a;

	ALBEDO = blob_color.rgb * opacity;
	EMISSION = blob_color.rgb * emission_intensity * opacity;
	ALPHA = opacity;
}
