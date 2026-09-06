@tool
class_name InwardEnergy
extends Node3D

const MIN_RADIUS := 0.001
const MIN_LENGTH_RATIO := 0.001
const MIN_THICKNESS_RATIO := 0.001
const MIN_TRAVEL_DISTANCE_RATIO := 0.01
const MIN_TRAVEL_DURATION := 0.01
const MIN_TRAVEL_SPEED := 0.01

var radius: float = 0.5:
	set(value):
		radius = maxf(value, MIN_RADIUS)
		if is_node_ready():
			_synchronize_instances()

@export_group("Layout")
@export_range(1, 100, 1) var instance_count: int = 40:
	set(value):
		instance_count = value
		if is_node_ready():
			_reset_instances()

@export_range(-0.5, 2.0, 0.01) var spawn_offset_min_ratio: float = 0.0:
	set(value):
		spawn_offset_min_ratio = value
		if is_node_ready():
			_update_spawn_offsets()

@export_range(-0.5, 2.0, 0.01) var spawn_offset_max_ratio: float = 0.2:
	set(value):
		spawn_offset_max_ratio = value
		if is_node_ready():
			_update_spawn_offsets()

@export_range(0.0, 1.0, 0.01) var despawn_radius_ratio: float = 0.18:
	set(value):
		despawn_radius_ratio = value
		if is_node_ready():
			_update_travel_layout()

@export var random_seed: int = 27183:
	set(value):
		random_seed = value
		if is_node_ready():
			_reset_instances()

@export_group("Motion")
@export_range(0.1, 20.0, 0.1, "suffix:radius/s") var travel_speed: float = 2.8:
	set(value):
		travel_speed = value
		if is_node_ready():
			_update_timings()

@export_range(0.0, 0.9, 0.01) var travel_speed_variation_ratio: float = 0.25:
	set(value):
		travel_speed_variation_ratio = value
		if is_node_ready():
			_update_timings()

@export_range(0.25, 4.0, 0.05) var movement_curve_power: float = 1.15:
	set(value):
		movement_curve_power = value
		if is_node_ready():
			_update_timings()

@export_group("Shape")
@export_range(0.01, 1.0, 0.01, "suffix:radius") var length_ratio: float = 0.3:
	set(value):
		length_ratio = value
		if is_node_ready():
			_update_instance_sizes()

@export_range(0.0, 0.5, 0.01, "suffix:radius") var length_variation_ratio: float = 0.07:
	set(value):
		length_variation_ratio = value
		if is_node_ready():
			_update_instance_sizes()

@export_range(0.01, 0.5, 0.01, "suffix:radius") var thickness_ratio: float = 0.11:
	set(value):
		thickness_ratio = value
		if is_node_ready():
			_update_instance_sizes()

@export_range(0.0, 0.25, 0.01, "suffix:radius") var thickness_variation_ratio: float = 0.05:
	set(value):
		thickness_variation_ratio = value
		if is_node_ready():
			_update_instance_sizes()

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

var _instance_data: Array[InwardEnergyInstance] = []
var _rng := RandomNumberGenerator.new()

@onready var _instances: InwardEnergyInstances = $Instances


func _ready() -> void:
	_update_instance_shape()
	_instances.set_layout(despawn_radius_ratio)
	_reset_instances()
	set_process(not Engine.is_editor_hint())


func _process(delta: float) -> void:
	_advance_instances(delta)
	_instances.update_dynamic_data(_instance_data, maxf(radius, MIN_RADIUS))


func _reset_instances() -> void:
	_rng.seed = random_seed
	_instance_data.clear()

	for _instance_index in range(instance_count):
		var data := InwardEnergyInstance.new()
		_spawn_instance(data)
		data.elapsed_time = _rng.randf_range(0.0, data.travel_duration)
		_instance_data.append(data)

	_synchronize_instances()


func _spawn_instance(data: InwardEnergyInstance) -> void:
	data.set_direction(_random_direction())
	data.spawn_offset_ratio = _rng.randf_range(
		minf(spawn_offset_min_ratio, spawn_offset_max_ratio),
		maxf(spawn_offset_min_ratio, spawn_offset_max_ratio)
	)
	data.elapsed_time = 0.0
	data.speed_random_factor = _rng.randf_range(-1.0, 1.0)
	data.length_random_factor = _rng.randf_range(-1.0, 1.0)
	data.thickness_random_factor = _rng.randf_range(-1.0, 1.0)
	data.travel_duration = _travel_duration_for(data)
	data.movement_curve_power = movement_curve_power
	_update_instance_size(data)


func _update_travel_layout() -> void:
	for data in _instance_data:
		_retime_instance(data)
	_instances.set_layout(despawn_radius_ratio)
	_synchronize_instances()


func _update_spawn_offsets() -> void:
	for data in _instance_data:
		data.spawn_offset_ratio = _rng.randf_range(
			minf(spawn_offset_min_ratio, spawn_offset_max_ratio),
			maxf(spawn_offset_min_ratio, spawn_offset_max_ratio)
		)
		_retime_instance(data)
	_synchronize_instances()


func _synchronize_instances() -> void:
	var sphere_radius := maxf(radius, MIN_RADIUS)
	_instances.synchronize(_instance_data, _bounds_radius(), sphere_radius)


func _update_instance_shape() -> void:
	_instances.set_shape(peak_position_ratio, roundness_power)


func _update_instance_sizes() -> void:
	for data in _instance_data:
		_update_instance_size(data)
	_instances.update_dynamic_data(_instance_data, maxf(radius, MIN_RADIUS))


func _update_instance_size(data: InwardEnergyInstance) -> void:
	data.length_ratio = _varied_ratio(
		length_ratio, length_variation_ratio,
		data.length_random_factor, MIN_LENGTH_RATIO
	)
	data.thickness_ratio = _varied_ratio(
		thickness_ratio, thickness_variation_ratio,
		data.thickness_random_factor, MIN_THICKNESS_RATIO
	)


func _update_timings() -> void:
	for data in _instance_data:
		_retime_instance(data)
	_instances.update_dynamic_data(_instance_data, maxf(radius, MIN_RADIUS))


func _retime_instance(data: InwardEnergyInstance) -> void:
	var travel_progress := data.travel_progress()
	data.travel_duration = _travel_duration_for(data)
	data.movement_curve_power = movement_curve_power
	data.elapsed_time = travel_progress * data.travel_duration


func _travel_duration_for(data: InwardEnergyInstance) -> float:
	var speed_scale := 1.0 + data.speed_random_factor * travel_speed_variation_ratio
	var varied_speed := maxf(travel_speed * speed_scale, MIN_TRAVEL_SPEED)
	var distance_ratio := maxf(
		data.spawn_radius_ratio() - despawn_radius_ratio,
		MIN_TRAVEL_DISTANCE_RATIO
	)
	return maxf(distance_ratio / varied_speed, MIN_TRAVEL_DURATION)


func _bounds_radius() -> float:
	var max_spawn_offset := maxf(spawn_offset_min_ratio, spawn_offset_max_ratio)
	var max_spawn_ratio := maxf(1.0 + max_spawn_offset, 0.0)
	var max_length_ratio := maxf(length_ratio + length_variation_ratio, MIN_LENGTH_RATIO)
	return maxf(radius, MIN_RADIUS) * maxf(1.0, max_spawn_ratio + max_length_ratio)


func _advance_instances(delta: float) -> void:
	for instance_index in range(_instance_data.size()):
		var data := _instance_data[instance_index]
		data.advance(delta)
		var was_respawned := false
		while data.is_expired():
			var overflow := data.overflow_time()
			_spawn_instance(data)
			data.elapsed_time = overflow
			was_respawned = true
		if was_respawned:
			_instances.update_instance_layout(data, instance_index, radius)


func _random_direction() -> Vector3:
	var y := _rng.randf_range(-1.0, 1.0)
	var angle := _rng.randf_range(0.0, TAU)
	var horizontal_radius := sqrt(maxf(0.0, 1.0 - y * y))
	return Vector3(horizontal_radius * cos(angle), y, horizontal_radius * sin(angle))


func _varied_ratio(
	base_value: float, variation: float, random_factor: float, minimum_value: float
) -> float:
	var minimum := maxf(base_value - variation, minimum_value)
	return lerpf(minimum, base_value + variation, (random_factor + 1.0) * 0.5)
