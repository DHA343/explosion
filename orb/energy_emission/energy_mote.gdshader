shader_type spatial;
render_mode unshaded, blend_add, cull_disabled;

uniform float deform : hint_range(0.0, 1.0) = 0.0;
uniform float impact_strength : hint_range(0.0, 1.0) = 0.7;
uniform vec2 impact_axis = vec2(1.0, 0.0);
uniform float impact_visibility : hint_range(0.0, 1.0) = 1.0;
uniform vec4 blob_color : source_color = vec4(1.0);
uniform float emission_intensity : hint_range(0.0, 8.0) = 2.0;
uniform float fade : hint_range(0.0, 1.0) = 1.0;
uniform float shape_seed = 0.0;

void vertex() {
	float shape_angle = atan(VERTEX.y, VERTEX.x);
	float edge_distortion = 1.0
		+ sin(shape_angle * 3.0 + shape_seed * TAU) * 0.04
		+ sin(shape_angle * 7.0 + shape_seed * 17.0) * 0.02
		+ sin(shape_angle * 11.0 + shape_seed * 29.0) * 0.01;
	vec2 distorted_vertex = VERTEX.xy * edge_distortion;
	vec2 impact_tangent = vec2(-impact_axis.y, impact_axis.x);
	float impact_axis_position = dot(distorted_vertex, impact_axis);
	float impact_tangent_position = dot(distorted_vertex, impact_tangent);
	float effective_impact_strength = impact_strength * impact_visibility;
	float final_radial_scale = mix(1.0, 0.35, effective_impact_strength);
	float final_tangent_scale = mix(1.0, 1.5, effective_impact_strength);
	float radial_scale = mix(1.0, final_radial_scale, deform);
	float tangent_scale = mix(1.0, final_tangent_scale, deform);
	vec2 impact_vertex = impact_axis * impact_axis_position * radial_scale
		+ impact_tangent * impact_tangent_position * tangent_scale;
	VERTEX.xy = impact_vertex;
}

void fragment() {
	float radial_distance = length(UV - vec2(0.5)) * 2.0;
	float edge_fade = 1.0 - smoothstep(0.55, 1.0, radial_distance);
	float opacity = edge_fade * fade;
	ALBEDO = blob_color.rgb * opacity;
	EMISSION = blob_color.rgb * emission_intensity * opacity;
	ALPHA = opacity;
}
