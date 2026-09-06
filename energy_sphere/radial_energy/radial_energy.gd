class_name RadialEnergy
extends Node3D

const MAX_DIRECTION_ATTEMPTS := 8
const MAX_DIRECTION_DOT := 0.94
const MIN_DURATION := 0.01
const MIN_TRAVEL_RADIUS := 0.01
const MAX_MISS_RADIUS_RATIO := 0.99

var radius: float = 0.5:
	set(value):
		radius = value
		if is_node_ready():
			_update_instance_layout()

@export_group("Position")
@export_range(0.1, 1.5, 0.001) var radius_ratio: float = 0.88:
	set(value):
		radius_ratio = value
		if is_node_ready():
			_update_instance_layout()

@export_range(-0.5, 0.5, 0.001) var collision_offset_ratio: float = 0.0:
	set(value):
		collision_offset_ratio = value
		if is_node_ready():
			_update_instance_layout()

@export_range(-0.5, 0.5, 0.001) var miss_offset_ratio: float = 0.0:
	set(value):
		miss_offset_ratio = value
		if is_node_ready():
			_update_instance_layout()

@export_range(-0.5, 0.5, 0.001) var impact_mark_offset_ratio: float = 0.0:
	set(value):
		impact_mark_offset_ratio = value
		if is_node_ready():
			_update_instance_layout()

@export_group("")
@export_range(1, 100, 1) var instance_count: int = 40:
	set(value):
		instance_count = value
		if is_node_ready():
			_reset_instances()

@export var random_seed: int = 72819

@export_group("Distribution")
@export_range(0.0, 1.0, 0.01) var collision_ratio: float = 0.6:
	set(value):
		collision_ratio = value
		if is_node_ready():
			_reset_instances()

@export_group("Behavior")
@export var collision_profile: RadialEnergyCollisionProfile = preload(
	"res://energy_sphere/radial_energy/default_collision_profile.tres"
):
	set(value):
		collision_profile = value
		if is_node_ready() and collision_profile != null:
			_update_collision_profile()

@export var miss_profile: RadialEnergyMissProfile = preload(
	"res://energy_sphere/radial_energy/default_miss_profile.tres"
):
	set(value):
		miss_profile = value
		if is_node_ready() and miss_profile != null:
			_update_miss_profile()

@export_group("Shape")
@export_range(0.01, 0.5, 0.01, "suffix:m") var length: float = 0.16
@export_range(0.01, 0.5, 0.01, "suffix:m") var length_variation: float = 0.04
@export_range(0.01, 0.5, 0.01, "suffix:m") var thickness: float = 0.07
@export_range(0.0, 0.5, 0.01, "suffix:m") var thickness_variation: float = 0.03
@export_range(0.05, 0.95, 0.01) var peak_position_ratio: float = 0.67:
	set(value):
		peak_position_ratio = value
		if is_node_ready():
			_update_instance_shape()

@export_range(1.0, 8.0, 0.1) var roundness_power: float = 2.0:
	set(value):
		roundness_power = value
		if is_node_ready():
			_update_instance_shape()

var _collision_data: Array[RadialEnergyInstance] = []
var _miss_data: Array[RadialEnergyInstance] = []
var _rng := RandomNumberGenerator.new()

@onready var _collision_instances: RadialEnergyInstances = $CollisionInstances
@onready var _miss_instances: RadialEnergyInstances = $MissInstances
@onready var _impact_marks: RadialEnergyImpactMarks = $ImpactMarks


func _ready() -> void:
	assert(collision_profile != null, "RadialEnergy requires a collision profile.")
	assert(miss_profile != null, "RadialEnergy requires a miss profile.")
	_update_instance_shape()
	_update_collision_profile()
	_update_miss_profile()
	_reset_instances()


func _process(delta: float) -> void:
	_advance_collision_instances(delta)
	_advance_miss_instances(delta)
	_collision_instances.update_dynamic_data(
		_collision_data, length, length_variation, thickness, thickness_variation
	)
	_miss_instances.update_dynamic_data(
		_miss_data, length, length_variation, thickness, thickness_variation
	)
	_impact_marks.update_dynamic_data(
		_collision_data, thickness, thickness_variation,
		collision_profile.impact_mark_size_multiplier
	)


func _reset_instances() -> void:
	_rng.seed = random_seed
	_collision_data.clear()
	_miss_data.clear()

	var collision_count := int(round(instance_count * collision_ratio))
	for _instance_index in range(collision_count):
		var data := RadialEnergyInstance.new()
		_collision_data.append(data)
		_spawn_collision_instance(data)
		data.elapsed_time = _rng.randf_range(0.0, data.cycle_duration() * 0.9)

	for _instance_index in range(instance_count - collision_count):
		var data := RadialEnergyInstance.new()
		_miss_data.append(data)
		_spawn_miss_instance(data)
		data.elapsed_time = _rng.randf_range(0.0, data.cycle_duration() * 0.9)

	_synchronize_instances()


func _spawn_collision_instance(data: RadialEnergyInstance) -> void:
	data.direction = _random_direction()
	data.travel_radius_ratio = 1.0
	data.travel_radius = _collision_radius()
	data.brightness = _rng.randf_range(0.72, 1.0)
	data.elapsed_time = 0.0
	data.duration_random_factor = _rng.randf_range(-1.0, 1.0)
	data.travel_duration = _collision_approach_duration_for(data)
	data.response_duration = collision_profile.impact_response_duration
	data.post_travel_duration = maxf(
		collision_profile.impact_response_duration, collision_profile.fade_duration
	)
	data.length_random_factor = _rng.randf_range(-1.0, 1.0)
	data.thickness_random_factor = _rng.randf_range(-1.0, 1.0)


func _spawn_miss_instance(data: RadialEnergyInstance) -> void:
	var minimum_ratio := minf(miss_profile.radius_ratio_min, miss_profile.radius_ratio_max)
	var maximum_ratio := maxf(miss_profile.radius_ratio_min, miss_profile.radius_ratio_max)
	maximum_ratio = minf(maximum_ratio, MAX_MISS_RADIUS_RATIO)

	data.direction = _random_direction()
	data.travel_radius_ratio = _rng.randf_range(minimum_ratio, maximum_ratio)
	data.travel_radius = _miss_radius_for(data)
	data.brightness = _rng.randf_range(0.72, 1.0)
	data.elapsed_time = 0.0
	data.duration_random_factor = _rng.randf_range(-1.0, 1.0)
	data.travel_duration = _miss_travel_duration_for(data)
	data.response_duration = 0.0
	data.post_travel_duration = 0.0
	data.length_random_factor = _rng.randf_range(-1.0, 1.0)
	data.thickness_random_factor = _rng.randf_range(-1.0, 1.0)


func _update_instance_layout() -> void:
	for data in _collision_data:
		data.travel_radius = _collision_radius()
	for data in _miss_data:
		data.travel_radius = _miss_radius_for(data)

	_synchronize_instances()


func _synchronize_instances() -> void:
	var bounds_radius := _bounds_radius()
	_collision_instances.synchronize(
		_collision_data, bounds_radius, length, length_variation,
		thickness, thickness_variation
	)
	_impact_marks.synchronize(
		_collision_data, bounds_radius, _impact_mark_radius(),
		thickness, thickness_variation, collision_profile
	)
	_miss_instances.synchronize(
		_miss_data, bounds_radius, length, length_variation,
		thickness, thickness_variation
	)


func _update_instance_shape() -> void:
	_collision_instances.set_shape(peak_position_ratio, roundness_power)
	_miss_instances.set_shape(peak_position_ratio, roundness_power)


func _update_collision_profile() -> void:
	_collision_instances.set_collision_profile(collision_profile)
	_impact_marks.set_profile(collision_profile)
	_update_collision_timings()


func _update_miss_profile() -> void:
	_miss_instances.set_miss_profile(miss_profile)
	_update_miss_timings()


func _update_collision_timings() -> void:
	for data in _collision_data:
		var was_responding := data.elapsed_time >= data.travel_duration
		var travel_progress := data.travel_progress()
		var impact_elapsed := maxf(data.elapsed_time - data.travel_duration, 0.0)
		data.travel_duration = _collision_approach_duration_for(data)
		data.response_duration = collision_profile.impact_response_duration
		data.post_travel_duration = maxf(
			collision_profile.impact_response_duration, collision_profile.fade_duration
		)
		if was_responding:
			data.elapsed_time = data.travel_duration + minf(
				impact_elapsed, data.post_travel_duration
			)
		else:
			data.elapsed_time = travel_progress * data.travel_duration


func _update_miss_timings() -> void:
	for data in _miss_data:
		var travel_progress := data.travel_progress()
		data.travel_duration = _miss_travel_duration_for(data)
		data.response_duration = 0.0
		data.post_travel_duration = 0.0
		data.elapsed_time = travel_progress * data.travel_duration


func _collision_approach_duration_for(data: RadialEnergyInstance) -> float:
	return _duration_for(
		data, collision_profile.approach_duration,
		collision_profile.approach_duration_variation
	)


func _miss_travel_duration_for(data: RadialEnergyInstance) -> float:
	return _duration_for(
		data, miss_profile.travel_duration, miss_profile.travel_duration_variation
	)


func _duration_for(
	data: RadialEnergyInstance, base_duration: float, variation: float
) -> float:
	var minimum := maxf(base_duration - variation, MIN_DURATION)
	return lerpf(
		minimum, base_duration + variation,
		(data.duration_random_factor + 1.0) * 0.5
	)


func _base_radius() -> float:
	return maxf(radius * radius_ratio, MIN_TRAVEL_RADIUS)


func _collision_radius() -> float:
	return maxf(_base_radius() + radius * collision_offset_ratio, MIN_TRAVEL_RADIUS)


func _miss_radius_for(data: RadialEnergyInstance) -> float:
	return maxf(
		_base_radius() * data.travel_radius_ratio + radius * miss_offset_ratio,
		MIN_TRAVEL_RADIUS
	)


func _impact_mark_radius() -> float:
	return maxf(_base_radius() + radius * impact_mark_offset_ratio, MIN_TRAVEL_RADIUS)


func _bounds_radius() -> float:
	var bounds_radius := maxf(radius, maxf(_collision_radius(), _impact_mark_radius()))
	for data in _miss_data:
		bounds_radius = maxf(bounds_radius, data.travel_radius)
	return bounds_radius


func _advance_collision_instances(delta: float) -> void:
	for instance_index in range(_collision_data.size()):
		var data := _collision_data[instance_index]
		data.advance(delta)
		if data.is_expired():
			_spawn_collision_instance(data)
			_collision_instances.update_instance_layout(data, instance_index)
			_impact_marks.update_instance_layout(data, instance_index)


func _advance_miss_instances(delta: float) -> void:
	for instance_index in range(_miss_data.size()):
		var data := _miss_data[instance_index]
		data.advance(delta)
		if data.is_expired():
			_spawn_miss_instance(data)
			_miss_instances.update_instance_layout(data, instance_index)


func _random_direction() -> Vector3:
	var candidate := Vector3.RIGHT
	for attempt in range(MAX_DIRECTION_ATTEMPTS):
		var y := _rng.randf_range(-1.0, 1.0)
		var angle := _rng.randf_range(0.0, TAU)
		var horizontal_radius := sqrt(maxf(0.0, 1.0 - y * y))
		candidate = Vector3(horizontal_radius * cos(angle), y, horizontal_radius * sin(angle))
		if not _is_direction_crowded(candidate):
			break
	return candidate


func _is_direction_crowded(candidate: Vector3) -> bool:
	for data in _collision_data:
		if data.travel_radius > 0.0 and candidate.dot(data.direction) > MAX_DIRECTION_DOT:
			return true
	for data in _miss_data:
		if data.travel_radius > 0.0 and candidate.dot(data.direction) > MAX_DIRECTION_DOT:
			return true
	return false
