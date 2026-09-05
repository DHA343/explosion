class_name RadialEnergy
extends Node3D

const MAX_DIRECTION_ATTEMPTS := 8
const MAX_DIRECTION_DOT := 0.94
const MIN_LIFETIME := 0.01
const MIN_TRAVEL_RADIUS := 0.01

var radius: float = 0.5:
	set(value):
		radius = value
		if is_node_ready():
			_update_instance_layout()

@export_range(1, 100, 1) var instance_count: int = 40:
	set(value):
		instance_count = value
		if is_node_ready():
			_reset_instances()

@export_range(-0.1, 0.1, 0.001, "suffix:m") var radius_offset: float = 0.0:
	set(value):
		radius_offset = value
		if is_node_ready():
			_update_instance_layout()

@export var random_seed: int = 72819

@export_group("Lifetime")
@export_range(0.1, 2.0, 0.01, "suffix:s") var lifetime: float = 0.8:
	set(value):
		lifetime = value
		if is_node_ready():
			_update_instance_lifetimes()

@export_range(0.0, 1.0, 0.01, "suffix:s") var lifetime_variation: float = 0.2:
	set(value):
		lifetime_variation = value
		if is_node_ready():
			_update_instance_lifetimes()

@export_range(0.1, 8.0, 0.1) var deceleration_power: float = 2.0:
	set(value):
		deceleration_power = value
		if is_node_ready():
			_update_instance_lifecycle()

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

@export_group("Disappearance")
@export_range(0.0, 0.99, 0.01) var length_shrink_start_ratio: float = 0.72:
	set(value):
		length_shrink_start_ratio = value
		if is_node_ready():
			_update_instance_lifecycle()

@export_range(1.0, 8.0, 0.1) var length_shrink_power: float = 1.0:
	set(value):
		length_shrink_power = value
		if is_node_ready():
			_update_instance_lifecycle()

@export_range(0.0, 0.99, 0.01) var thickness_shrink_start_ratio: float = 0.60:
	set(value):
		thickness_shrink_start_ratio = value
		if is_node_ready():
			_update_instance_lifecycle()

@export_range(1.0, 8.0, 0.1) var thickness_shrink_power: float = 2.0:
	set(value):
		thickness_shrink_power = value
		if is_node_ready():
			_update_instance_lifecycle()

@export_range(0.0, 0.99, 0.01) var fade_start_ratio: float = 0.78:
	set(value):
		fade_start_ratio = value
		if is_node_ready():
			_update_instance_lifecycle()

@export_range(0.1, 8.0, 0.1) var fade_power: float = 2.0:
	set(value):
		fade_power = value
		if is_node_ready():
			_update_instance_lifecycle()

var _instance_data: Array[RadialEnergyInstance] = []
var _rng := RandomNumberGenerator.new()

@onready var _instances: RadialEnergyInstances = $Instances


func _ready() -> void:
	_reset_instances()
	_update_instance_shape()
	_update_instance_lifecycle()


func _process(delta: float) -> void:
	for instance_index in range(_instance_data.size()):
		var data := _instance_data[instance_index]
		data.advance(delta)
		if data.is_expired():
			_spawn_instance(data)
			_instances.update_instance_layout(data, instance_index)

	_instances.update_dynamic_data(
		_instance_data, length, length_variation, thickness, thickness_variation
	)


func _reset_instances() -> void:
	_rng.seed = random_seed
	_instance_data.clear()
	for _instance_index in range(instance_count):
		var data := RadialEnergyInstance.new()
		_instance_data.append(data)
		_spawn_instance(data)
		data.elapsed_time = _rng.randf_range(0.0, data.lifetime * 0.9)

	_instances.synchronize(
		_instance_data, maxf(radius, _travel_radius()), length, length_variation,
		thickness, thickness_variation
	)


func _spawn_instance(data: RadialEnergyInstance) -> void:
	var direction := _random_direction()

	data.direction = direction
	data.travel_radius = _travel_radius()
	data.brightness = _rng.randf_range(0.72, 1.0)
	data.elapsed_time = 0.0
	data.lifetime_random_factor = _rng.randf_range(-1.0, 1.0)
	data.lifetime = _lifetime_for(data)
	data.length_random_factor = _rng.randf_range(-1.0, 1.0)
	data.thickness_random_factor = _rng.randf_range(-1.0, 1.0)


func _update_instance_layout() -> void:
	for data in _instance_data:
		data.travel_radius = _travel_radius()

	_instances.synchronize(
		_instance_data, maxf(radius, _travel_radius()), length, length_variation,
		thickness, thickness_variation
	)


func _update_instance_shape() -> void:
	_instances.set_shape(peak_position_ratio, roundness_power)


func _update_instance_lifecycle() -> void:
	_instances.set_lifecycle(
		deceleration_power, length_shrink_start_ratio, length_shrink_power,
		thickness_shrink_start_ratio, thickness_shrink_power, fade_start_ratio,
		fade_power
	)


func _update_instance_lifetimes() -> void:
	for data in _instance_data:
		var progress := data.lifecycle_progress()
		data.lifetime = _lifetime_for(data)
		data.elapsed_time = progress * data.lifetime


func _lifetime_for(data: RadialEnergyInstance) -> float:
	var minimum := maxf(lifetime - lifetime_variation, MIN_LIFETIME)
	return lerpf(
		minimum, lifetime + lifetime_variation,
		(data.lifetime_random_factor + 1.0) * 0.5
	)


func _travel_radius() -> float:
	return maxf(radius + radius_offset, MIN_TRAVEL_RADIUS)


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
	for data in _instance_data:
		if data.travel_radius > 0.0 and candidate.dot(data.direction) > MAX_DIRECTION_DOT:
			return true
	return false
