shader_type spatial;

render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;

uniform sampler2D streaks_texture : source_color;

uniform float fade_inner_ratio : hint_range(0.0, 1.0, 0.01) = 0.75;
uniform float fade_outer_ratio : hint_range(0.0, 1.0, 0.01) = 0.95;


void vertex() {
	mat4 billboard_world = mat4(
		vec4(
			normalize(INV_VIEW_MATRIX[0].xyz)
			* length(MODEL_MATRIX[0].xyz),
			0.0
		),
		vec4(
			normalize(INV_VIEW_MATRIX[1].xyz)
			* length(MODEL_MATRIX[1].xyz),
			0.0
		),
		vec4(
			normalize(INV_VIEW_MATRIX[2].xyz)
			* length(MODEL_MATRIX[2].xyz),
			0.0
		),
		MODEL_MATRIX[3]
	);

	MODELVIEW_MATRIX = VIEW_MATRIX * billboard_world;
}


void fragment() {
	vec4 streaks = texture(streaks_texture, UV);

	float radial_ratio = length(UV - vec2(0.5)) * 2.0;

	float radial_fade = 1.0 - smoothstep(
		fade_inner_ratio,
		fade_outer_ratio,
		radial_ratio
	);

	EMISSION = streaks.rgb * radial_fade;
	ALPHA = streaks.a * radial_fade;
}