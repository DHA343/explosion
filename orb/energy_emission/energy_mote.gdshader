shader_type spatial;
render_mode unshaded, blend_add, cull_disabled;

uniform float deform : hint_range(0.0, 1.0) = 0.0;
uniform float impact_strength : hint_range(0.0, 1.0) = 0.7;
uniform vec2 radial_axis = vec2(1.0, 0.0);
uniform vec4 blob_color : source_color = vec4(1.0);
uniform float emission_intensity : hint_range(0.0, 8.0) = 2.0;
uniform float fade : hint_range(0.0, 1.0) = 1.0;

void vertex() {
	vec2 tangent_axis = vec2(-radial_axis.y, radial_axis.x);
	float radial_position = dot(VERTEX.xy, radial_axis);
	float tangent_position = dot(VERTEX.xy, tangent_axis);
	float final_radial_scale = mix(1.0, 0.35, impact_strength);
	float final_tangent_scale = mix(1.0, 1.5, impact_strength);
	float radial_scale = mix(1.0, final_radial_scale, deform);
	float tangent_scale = mix(1.0, final_tangent_scale, deform);
	VERTEX.xy = radial_axis * radial_position * radial_scale
		+ tangent_axis * tangent_position * tangent_scale;
}

void fragment() {
	float radial_distance = length(UV - vec2(0.5)) * 2.0;
	float edge_fade = 1.0 - smoothstep(0.55, 1.0, radial_distance);
	float opacity = edge_fade * fade;
	ALBEDO = blob_color.rgb * opacity;
	EMISSION = blob_color.rgb * emission_intensity * opacity;
	ALPHA = opacity;
}
