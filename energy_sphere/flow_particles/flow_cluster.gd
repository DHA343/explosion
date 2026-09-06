@tool
class_name FlowCluster
extends Node3D

const NOISE_OFFSET_X := Vector3(17.1, 43.7, 11.8)
const NOISE_OFFSET_Y := Vector3(29.6, 7.4, 53.2)
const NOISE_OFFSET_Z := Vector3(61.3, 31.9, 19.5)
const MIN_VECTOR_LENGTH_SQUARED := 0.000001

var cluster_lifetime_min: float = 3.0
var cluster_lifetime_max: float = 6.0
var cluster_radius_min_ratio: float = 1.0
var cluster_radius_max_ratio: float = 1.12
var cluster_radius_bias: float = 2.0
var cluster_radial_wander_ratio: float = 0.04
var cluster_radial_follow: float = 2.0
var cluster_outward_drift_ratio: float = 0.10
var cluster_speed: float = 0.45
var cluster_speed_variation: float = 0.25
var cluster_flow_scale: float = 0.8
var cluster_flow_evolution_speed: float = 0.25
var cluster_steering_strength: float = 0.8
var cluster_max_turn_speed: float = 35.0
var plume_length_ratio: float = 0.45
var plume_width_ratio: float = 0.18
var plume_taper: float = 0.75
var plume_density_power: float = 2.0
var cluster_size_variation: float = 0.25
var particles_per_cluster: int = 180
var particle_lifetime_min: float = 1.0
var particle_lifetime_max: float = 2.0
var particle_size_min_ratio: float = 0.010
var particle_size_max_ratio: float = 0.020
var plume_outward_speed: float = 0.12
var plume_bend_strength: float = 0.16
var plume_bend_speed: float = 0.45
var particle_turbulence_strength: float = 0.22
var particle_turbulence_scale: float = 3.0
var particle_turbulence_speed: float = 0.65
var particle_radial_turbulence: float = 0.35
var plume_cohesion: float = 2.0
var purple_color: Color = Color(0.54, 0.24, 1.0, 1.0)
var cyan_color: Color = Color(0.15, 0.88, 1.0, 1.0)
var cyan_ratio: float = 0.50
var cluster_brightness_variation: float = 0.25
var cluster_saturation_variation: float = 0.10
var particle_brightness_variation: float = 0.12
var cluster_pulse_amount: float = 0.10
var cluster_pulse_speed: float = 1.2
var opacity: float = 0.60
var emission_strength: float = 2.2
var silhouette_width: float = 0.65
var front_back_opacity: float = 0.08

var radius: float = 0.5:
	set(value):
		radius = value
		if is_node_ready():
			_update_shader_parameters()

@onready var _particles: GPUParticles3D = $Particles
@onready var _process_material: ShaderMaterial = $Particles.process_material as ShaderMaterial
@onready var _render_material: ShaderMaterial = $Particles.draw_pass_1.material as ShaderMaterial

var _rng := RandomNumberGenerator.new()
var _noise := FastNoiseLite.new()
var _cluster_seed: int = 0
var _elapsed_time: float = 0.0
var _cluster_age: float = 0.0
var _cluster_lifetime: float = 3.0
var _spawn_radius_ratio: float = 1.0
var _current_radius_ratio: float = 1.0
var _speed_multiplier: float = 1.0
var _size_multiplier: float = 1.0
var _radial := Vector3.UP
var _heading := Vector3.RIGHT
var _cluster_color := Color.WHITE
var _cluster_brightness_multiplier: float = 1.0
var _pulse_phase: float = 0.0
var _cluster_alpha: float = 0.0
var _initialized: bool = false


func _ready() -> void:
	assert(_process_material != null, "FlowCluster requires a particle process ShaderMaterial.")
	assert(_render_material != null, "FlowCluster requires a particle render ShaderMaterial.")
	_particles.local_coords = true
	_particles.one_shot = false
	_particles.fixed_fps = 60
	_particles.interpolate = true
	_particles.fract_delta = true
	_particles.trail_enabled = false
	_particles.use_fixed_seed = true
	_update_shader_parameters()


func initialize(cluster_seed: int, enabled: bool) -> void:
	_cluster_seed = cluster_seed
	_rng.seed = cluster_seed
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.fractal_octaves = 2
	_noise.frequency = 1.0
	_noise.seed = cluster_seed
	_particles.seed = cluster_seed
	_particles.amount = particles_per_cluster
	_elapsed_time = 0.0
	_initialized = false
	set_enabled(enabled)


func set_enabled(enabled: bool) -> void:
	if enabled:
		process_mode = Node.PROCESS_MODE_INHERIT
		visible = true
		if not _initialized and not Engine.is_editor_hint():
			_respawn()
	else:
		process_mode = Node.PROCESS_MODE_DISABLED
		_particles.emitting = false
		visible = false
		_initialized = false


func update_visibility_aabb(length_ratio: float, width_ratio: float) -> void:
	if not is_node_ready():
		return
	var extent := radius * (length_ratio + width_ratio + 0.75)
	_particles.visibility_aabb = AABB(Vector3.ONE * -extent, Vector3.ONE * extent * 2.0)


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not _initialized:
		return

	_elapsed_time += delta
	_cluster_age += delta
	if _cluster_age >= _cluster_lifetime:
		_cluster_alpha = 0.0
		_update_render_parameters()
		_respawn()
		return

	var age_normalized := clampf(_cluster_age / _cluster_lifetime, 0.0, 1.0)
	var fade_in := smoothstep(0.0, 0.15, age_normalized)
	var fade_out := 1.0 - smoothstep(0.80, 1.0, age_normalized)
	_cluster_alpha = fade_in * fade_out

	var time_offset := _elapsed_time * cluster_flow_evolution_speed
	var time_vector := Vector3(time_offset * 0.71, -time_offset * 0.43, time_offset * 0.59)
	var noise_position := _radial * cluster_flow_scale
	var noise_vector := Vector3(
		_noise.get_noise_3d(noise_position.x + NOISE_OFFSET_X.x + time_vector.x,
			noise_position.y + NOISE_OFFSET_X.y + time_vector.y,
			noise_position.z + NOISE_OFFSET_X.z + time_vector.z),
		_noise.get_noise_3d(noise_position.x + NOISE_OFFSET_Y.x + time_vector.x,
			noise_position.y + NOISE_OFFSET_Y.y + time_vector.y,
			noise_position.z + NOISE_OFFSET_Y.z + time_vector.z),
		_noise.get_noise_3d(noise_position.x + NOISE_OFFSET_Z.x + time_vector.x,
			noise_position.y + NOISE_OFFSET_Z.y + time_vector.y,
			noise_position.z + NOISE_OFFSET_Z.z + time_vector.z)
	)
	var tangent_noise := noise_vector - _radial * noise_vector.dot(_radial)
	var steering := tangent_noise - _heading * tangent_noise.dot(_heading)
	var signed_steering := _radial.dot(_heading.cross(steering))
	var max_turn_radians := deg_to_rad(cluster_max_turn_speed) * delta
	var turn := clampf(signed_steering * cluster_steering_strength * delta,
		-max_turn_radians, max_turn_radians)
	_heading = _heading.rotated(_radial, turn).normalized()

	var step := _heading * cluster_speed * _speed_multiplier * delta
	_radial = (_radial + step).normalized()
	_heading -= _radial * _heading.dot(_radial)
	if _heading.length_squared() <= MIN_VECTOR_LENGTH_SQUARED:
		_heading = _random_tangent(_radial)
	else:
		_heading = _heading.normalized()

	var outward_progress := smoothstep(0.65, 1.0, age_normalized)
	var lifetime_outward_drift := cluster_outward_drift_ratio * outward_progress
	var radial_wander := _noise.get_noise_3dv(_radial * cluster_flow_scale + Vector3(13.0, 29.0, 47.0)) \
		* cluster_radial_wander_ratio
	var target_radius_ratio := _spawn_radius_ratio + radial_wander + lifetime_outward_drift
	var follow_weight := 1.0 - exp(-cluster_radial_follow * delta)
	_current_radius_ratio = lerpf(_current_radius_ratio, target_radius_ratio, follow_weight)

	position = _radial * radius * _current_radius_ratio
	basis = Basis(_heading, _radial, _heading.cross(_radial).normalized())
	_update_render_parameters()


func _respawn() -> void:
	_particles.emitting = false
	_cluster_lifetime = _rng.randf_range(cluster_lifetime_min, cluster_lifetime_max)
	_cluster_age = 0.0
	_spawn_radius_ratio = lerpf(cluster_radius_min_ratio, cluster_radius_max_ratio,
		pow(_rng.randf(), cluster_radius_bias))
	_current_radius_ratio = _spawn_radius_ratio
	_speed_multiplier = _rng.randf_range(1.0 - cluster_speed_variation, 1.0 + cluster_speed_variation)
	_size_multiplier = _rng.randf_range(1.0 - cluster_size_variation, 1.0 + cluster_size_variation)
	_radial = _random_sphere_direction()
	_heading = _random_tangent(_radial)
	_cluster_color = cyan_color if _rng.randf() < cyan_ratio else purple_color
	_cluster_color = _vary_color(_cluster_color)
	_cluster_brightness_multiplier = _rng.randf_range(1.0 - cluster_brightness_variation,
		1.0 + cluster_brightness_variation)
	_pulse_phase = _rng.randf_range(0.0, TAU)
	_cluster_alpha = 0.0
	position = _radial * radius * _current_radius_ratio
	basis = Basis(_heading, _radial, _heading.cross(_radial).normalized())
	_update_shader_parameters()
	_update_render_parameters()
	_particles.restart(true)
	_particles.emitting = true
	_cluster_alpha = 0.0
	_initialized = true


func _random_sphere_direction() -> Vector3:
	var z := 1.0 - 2.0 * _rng.randf()
	var phi := TAU * _rng.randf()
	var xy := sqrt(max(1.0 - z * z, 0.0))
	return Vector3(cos(phi) * xy, z, sin(phi) * xy)


func _random_tangent(radial: Vector3) -> Vector3:
	var reference_axis := Vector3.UP if absf(radial.y) < 0.9 else Vector3.RIGHT
	var tangent_a := (reference_axis - radial * reference_axis.dot(radial)).normalized()
	var tangent_b := radial.cross(tangent_a).normalized()
	var angle := _rng.randf_range(0.0, TAU)
	return (tangent_a * cos(angle) + tangent_b * sin(angle)).normalized()


func _vary_color(base_color: Color) -> Color:
	var saturation := clampf(base_color.s * _rng.randf_range(1.0 - cluster_saturation_variation,
		1.0 + cluster_saturation_variation), 0.0, 1.0)
	return Color.from_hsv(base_color.h, saturation, base_color.v, base_color.a)


func _update_shader_parameters() -> void:
	if not is_node_ready():
		return
	_process_material.set_shader_parameter(&"sphere_radius", radius)
	_process_material.set_shader_parameter(&"plume_length", radius * plume_length_ratio * _size_multiplier)
	_process_material.set_shader_parameter(&"plume_width", radius * plume_width_ratio * _size_multiplier)
	_process_material.set_shader_parameter(&"plume_taper", plume_taper)
	_process_material.set_shader_parameter(&"plume_density_power", plume_density_power)
	_process_material.set_shader_parameter(&"particle_lifetime_min", particle_lifetime_min)
	_process_material.set_shader_parameter(&"particle_lifetime_max", particle_lifetime_max)
	_process_material.set_shader_parameter(&"particle_size_min_ratio", particle_size_min_ratio)
	_process_material.set_shader_parameter(&"particle_size_max_ratio", particle_size_max_ratio)
	_process_material.set_shader_parameter(&"particle_brightness_variation", particle_brightness_variation)
	_process_material.set_shader_parameter(&"plume_outward_speed", plume_outward_speed)
	_process_material.set_shader_parameter(&"plume_bend_strength", plume_bend_strength)
	_process_material.set_shader_parameter(&"plume_bend_speed", plume_bend_speed)
	_process_material.set_shader_parameter(&"particle_turbulence_strength", particle_turbulence_strength)
	_process_material.set_shader_parameter(&"particle_turbulence_scale", particle_turbulence_scale)
	_process_material.set_shader_parameter(&"particle_turbulence_speed", particle_turbulence_speed)
	_process_material.set_shader_parameter(&"particle_radial_turbulence", particle_radial_turbulence)
	_process_material.set_shader_parameter(&"plume_cohesion", plume_cohesion)
	_process_material.set_shader_parameter(&"cluster_seed", float(_cluster_seed))
	_process_material.set_shader_parameter(&"cluster_color", _cluster_color)
	_update_render_parameters()


func _update_render_parameters() -> void:
	if not is_node_ready():
		return
	_render_material.set_shader_parameter(&"cluster_center_world", global_position)
	_render_material.set_shader_parameter(&"cluster_radial_world", global_basis.y)
	_render_material.set_shader_parameter(&"sphere_radius", radius)
	_render_material.set_shader_parameter(&"actual_plume_length", radius * plume_length_ratio * _size_multiplier)
	_render_material.set_shader_parameter(&"cluster_brightness_multiplier", _cluster_brightness_multiplier)
	_render_material.set_shader_parameter(&"pulse_phase", _pulse_phase)
	_render_material.set_shader_parameter(&"cluster_pulse_amount", cluster_pulse_amount)
	_render_material.set_shader_parameter(&"cluster_pulse_speed", cluster_pulse_speed)
	_render_material.set_shader_parameter(&"cluster_alpha", _cluster_alpha)
	_render_material.set_shader_parameter(&"silhouette_width", silhouette_width)
	_render_material.set_shader_parameter(&"front_back_opacity", front_back_opacity)
	_render_material.set_shader_parameter(&"opacity", opacity)
	_render_material.set_shader_parameter(&"emission_strength", emission_strength)
