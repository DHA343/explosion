shader_type spatial;

render_mode unshaded, blend_add, cull_disabled, depth_draw_never, depth_test_disabled;

uniform float effect_time = 0.0;
uniform vec4 halo_color : source_color = vec4(0.22, 0.68, 1.0, 1.0);
uniform float halo_emission : hint_range(0.0, 4.0, 0.1) = 1.25;


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
	vec2 field_position = (UV - vec2(0.5)) * 2.0;
	float field_radius = length(field_position);
	float angle = atan(field_position.y, field_position.x);
	float broad_variation = sin(angle * 7.0 + effect_time * 5.0);
	broad_variation += sin(angle * 11.0 - effect_time * 3.5) * 0.5;
	float core_haze = exp(-field_radius * field_radius * 8.0) * 0.42;
	float interaction_haze = exp(-pow((field_radius - 0.52) / 0.3, 2.0));
	interaction_haze *= mix(0.08, 0.18, broad_variation * 0.5 + 0.5);
	float outer_fade = 1.0 - smoothstep(0.72, 1.0, field_radius);
	float halo_mask = (core_haze + interaction_haze) * outer_fade;
	ALBEDO = halo_color.rgb * halo_mask * 0.2;
	EMISSION = halo_color.rgb * halo_mask * halo_emission;
	ALPHA = clamp(halo_mask * 0.48, 0.0, 0.28);
}
