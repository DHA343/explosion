shader_type particles;

#include "res://energy_sphere/aura_flow/shared/aura_flow_common.gdshaderinc"

uniform float sphere_radius = 0.5;
uniform float particle_size_min_ratio = 0.008;
uniform float particle_size_max_ratio = 0.016;
uniform uint flow_seed = 2048u;
uniform float radial_speed = 0.20;
uniform float radial_variation = 0.35;
uniform float tangential_strength = 0.46;
uniform float flow_scale = 0.78;
uniform float flow_speed = 0.20;
uniform uint source_seed = 343u;
uniform float source_scale = 1.45;
uniform float source_speed = 0.16;
uniform float source_min_strength = 0.32;
uniform float source_contrast = 1.35;


void start() {
	uint random_state = aura_hash_u32(NUMBER ^ RANDOM_SEED ^ 0xa511e9b3u);
	float vertical = 1.0 - 2.0 * aura_hash01(random_state);
	float angle = TAU * aura_hash01(random_state + 0x9e3779b9u);
	float horizontal = sqrt(max(1.0 - vertical * vertical, 0.0));
	vec3 radial_direction = vec3(
		cos(angle) * horizontal,
		vertical,
		sin(angle) * horizontal
	);
	float source_strength = sample_source_strength(
		radial_direction,
		TIME,
		source_seed,
		source_scale,
		source_speed,
		source_min_strength
	);
	float source_factor = pow(source_strength, source_contrast);
	float particle_size = sphere_radius * mix(
		particle_size_min_ratio,
		particle_size_max_ratio,
		aura_hash01(random_state + 0x85a308d3u)
	) * mix(0.78, 1.22, source_factor);
	float spawn_ratio = mix(1.0, 1.025, aura_hash01(random_state + 0x243f6a88u));
	vec3 spawn_position = radial_direction * sphere_radius * spawn_ratio;

	TRANSFORM = mat4(
		vec4(particle_size, 0.0, 0.0, 0.0),
		vec4(0.0, particle_size, 0.0, 0.0),
		vec4(0.0, 0.0, particle_size, 0.0),
		vec4(spawn_position, 1.0)
	);
	CUSTOM.x = 0.0;
	CUSTOM.y = mix(0.84, 1.16, aura_hash01(random_state + 0x13198a2eu));
	CUSTOM.z = mix(0.48, 1.0, source_factor);
}


void process() {
	CUSTOM.x += DELTA;
	vec3 current_position = TRANSFORM[3].xyz;
	VELOCITY = sample_base_flow(
		current_position,
		sphere_radius,
		TIME,
		flow_seed,
		radial_speed,
		radial_variation,
		tangential_strength,
		flow_scale,
		flow_speed
	) * CUSTOM.y;
}
