shader_type spatial;

render_mode unshaded, blend_premul_alpha, cull_disabled, depth_draw_never;

uniform vec4 particle_color = vec4(0.20, 0.75, 1.0, 1.0);
uniform float particle_lifetime = 1.8;
uniform float opacity = 0.32;
uniform float emission_strength = 1.4;

varying vec4 particle_custom;


void vertex() {
	particle_custom = INSTANCE_CUSTOM;
}


void fragment() {
	vec2 centered_uv = UV * 2.0 - 1.0;
	float radial_distance = length(centered_uv);
	float particle_mask = 1.0 - smoothstep(0.40, 1.0, radial_distance);
	float age = particle_custom.x / max(particle_lifetime, 0.0001);
	float life_fade = smoothstep(0.0, 0.08, age)
		* (1.0 - smoothstep(0.60, 1.0, age));
	float final_alpha = particle_mask * life_fade * particle_custom.w * opacity;

	ALBEDO = particle_color.rgb;
	EMISSION = particle_color.rgb * emission_strength;
	ALPHA = final_alpha;
}
