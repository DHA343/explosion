shader_type spatial;

render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform vec4 particle_color : source_color = vec4(0.18, 0.78, 1.0, 1.0);
uniform float particle_lifetime = 2.0;
uniform float particle_opacity = 0.34;
uniform float particle_emission_strength = 1.55;
uniform float view_front_visibility = 0.08;
uniform float view_falloff_power = 2.1;

varying float particle_age;
varying float particle_density;
varying vec3 particle_center_world;


void vertex() {
	particle_age = INSTANCE_CUSTOM.x / max(particle_lifetime, 0.0001);
	particle_density = INSTANCE_CUSTOM.z;
	particle_center_world = MODEL_MATRIX[3].xyz;
}


void fragment() {
	vec2 centered_uv = UV * 2.0 - 1.0;
	float radial_distance = length(centered_uv);
	float particle_shape = 1.0 - smoothstep(0.35, 1.0, radial_distance);
	float fade_in = smoothstep(0.0, 0.08, particle_age);
	float fade_out = 1.0 - smoothstep(0.64, 1.0, particle_age);
	float life_fade = fade_in * fade_out;

	vec3 particle_from_center = particle_center_world - NODE_POSITION_WORLD;
	float particle_distance = length(particle_from_center);
	vec3 radial_direction = particle_distance > 0.0001
		? particle_from_center / particle_distance
		: vec3(0.0, 1.0, 0.0);
	vec3 view_direction = normalize(CAMERA_POSITION_WORLD - particle_center_world);
	float view_dot = abs(dot(radial_direction, view_direction));
	float edge_factor = 1.0 - view_dot;
	float view_weight = mix(
		view_front_visibility,
		1.0,
		pow(clamp(edge_factor, 0.0, 1.0), view_falloff_power)
	);
	float final_alpha = particle_shape * life_fade * particle_density * particle_opacity * view_weight;

	ALBEDO = particle_color.rgb;
	EMISSION = particle_color.rgb * particle_emission_strength * final_alpha;
	ALPHA = final_alpha;
}
