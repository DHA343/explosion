@tool
class_name RadialEnergy
extends Node3D

const MAX_DIRECTION_ATTEMPTS := 8
const MAX_DIRECTION_DOT := 0.94
const MIN_RADIUS := 0.001
const MIN_TRAVEL_RADIUS_RATIO := 0.01
const MIN_LENGTH_RATIO := 0.001
const MIN_THICKNESS_RATIO := 0.001
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

@export_range(0.1, 1.5, 0.01) var radius_ratio: float = 0.88:
	set(value):
		radius_ratio = value
		if is_node_ready():
			_update_travel_layout()

@export_range(-0.5, 0.5, 0.001) var collision_offset_ratio: float = 0.0:
	set(value):
		collision_offset_ratio = value
		if is_node_ready():
			_update_travel_layout()

@export var random_seed: int = 72819:
	set(value):
		random_seed = value
		if is_node_ready():
			_reset_instances()

@export_group("Motion")
@export_range(0.1, 20.0, 0.1, "suffix:radius/s") var travel_speed: float = 3.6:
	set(value):
		travel_speed = value
		if is_node_ready():
			_update_timings()

@export_range(0.0, 0.9, 0.01) var travel_speed_variation_ratio: float = 0.24:
	set(value):
		travel_speed_variation_ratio = value
		if is_node_ready():
			_update_timings()

@export_range(0.25, 4.0, 0.05) var movement_curve_power: float = 1.5:
	set(value):
		movement_curve_power = value
		if is_node_ready():
			_update_timings()

@export_group("Shape")
@export_range(0.01, 1.0, 0.01, "suffix:radius") var length_ratio: float = 0.32:
	set(value):
		length_ratio = value
		if is_node_ready():
			_update_instance_sizes()

@export_range(0.0, 0.5, 0.01, "suffix:radius") var length_variation_ratio: float = 0.08:
	set(value):
		length_variation_ratio = value
		if is_node_ready():
			_update_instance_sizes()

@export_range(0.01, 0.5, 0.01, "suffix:radius") var thickness_ratio: float = 0.14:
	set(value):
		thickness_ratio = value
		if is_node_ready():
			_update_instance_sizes()

@export_range(0.0, 0.25, 0.01, "suffix:radius") var thickness_variation_ratio: float = 0.06:
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

@export_group("Impact")
@export_range(0.05, 2.0, 0.01, "suffix:s") var impact_response_duration: float = 0.13:
	set(value):
		impact_response_duration = value
		if is_node_ready():
			_update_timings()

@export_range(0.01, 2.0, 0.01, "suffix:s") var fade_duration: float = 0.16:
	set(value):
		fade_duration = value
		if is_node_ready():
			_update_timings()

@export_range(0.0, 2.0, 0.01) var length_end_scale: float = 0.1:
	set(value):
		length_end_scale = value
		if is_node_ready():
			_update_impact_style()

@export_range(0.1, 8.0, 0.1) var length_change_power: float = 1.0:
	set(value):
		length_change_power = value
		if is_node_ready():
			_update_impact_style()

@export_range(0.0, 2.0, 0.01) var thickness_end_scale: float = 1.7:
	set(value):
		thickness_end_scale = value
		if is_node_ready():
			_update_impact_style()

@export_range(0.1, 8.0, 0.1) var thickness_change_power: float = 1.0:
	set(value):
		thickness_change_power = value
		if is_node_ready():
			_update_impact_style()

@export_range(0.05, 0.95, 0.01) var peak_end_position_ratio: float = 0.8:
	set(value):
		peak_end_position_ratio = value
		if is_node_ready():
			_update_impact_style()

@export_range(0.1, 8.0, 0.1) var fade_power: float = 1.0:
	set(value):
		fade_power = value
		if is_node_ready():
			_update_impact_style()

@export_group("Impact Mark")
@export_range(-0.5, 0.5, 0.001) var impact_mark_offset_ratio: float = 0.0:
	set(value):
		impact_mark_offset_ratio = value
		if is_node_ready():
			_synchronize_instances()

@export_range(0.1, 4.0, 0.01) var impact_mark_size_multiplier: float = 2.91:
	set(value):
		impact_mark_size_multiplier = value
		if is_node_ready():
			_update_impact_mark_style()

@export_range(0.0, 1.0, 0.01) var impact_mark_opacity: float = 0.2:
	set(value):
		impact_mark_opacity = value
		if is_node_ready():
			_update_impact_mark_style()

@export_range(0.01, 1.0, 0.01) var impact_mark_softness: float = 1.0:
	set(value):
		impact_mark_softness = value
		if is_node_ready():
			_update_impact_mark_style()

var _instance_data: Array[RadialEnergyInstance] = []
var _rng := RandomNumberGenerator.new()

@onready var _instances: RadialEnergyInstances = $Instances
@onready var _impact_marks: RadialEnergyImpactMarks = $ImpactMarks


func _ready() -> void:
	_update_instance_shape()
	_update_impact_style()
	_update_impact_mark_style()
	_reset_instances()
	set_process(not Engine.is_editor_hint())


func _process(delta: float) -> void:
	_advance_instances(delta)
	_update_dynamic_data()


func _reset_instances() -> void:
	_rng.seed = random_seed
	_instance_data.clear()

	for _instance_index in range(instance_count):
		var data := RadialEnergyInstance.new()
		_spawn_instance(data)
		data.elapsed_time = _rng.randf_range(0.0, data.cycle_duration())
		_instance_data.append(data)

	_synchronize_instances()


func _spawn_instance(data: RadialEnergyInstance) -> void:
	data.set_direction(_random_direction(data))
	data.travel_radius_ratio = _travel_radius_ratio()
	data.brightness = _rng.randf_range(0.72, 1.0)
	data.elapsed_time = 0.0
	data.speed_random_factor = _rng.randf_range(-1.0, 1.0)
	data.length_random_factor = _rng.randf_range(-1.0, 1.0)
	data.thickness_random_factor = _rng.randf_range(-1.0, 1.0)
	data.travel_duration = _travel_duration_for(
		data.travel_radius_ratio, data.speed_random_factor
	)
	data.impact_duration = impact_response_duration
	data.fade_duration = fade_duration
	data.movement_curve_power = movement_curve_power
	_update_instance_size(data)


func _update_travel_layout() -> void:
	for data in _instance_data:
		data.travel_radius_ratio = _travel_radius_ratio()
		_retime_instance(data)
	_synchronize_instances()


func _synchronize_instances() -> void:
	var sphere_radius := maxf(radius, MIN_RADIUS)
	var bounds_radius := _bounds_radius()
	_instances.synchronize(_instance_data, bounds_radius, sphere_radius)
	_impact_marks.synchronize(
		_instance_data, bounds_radius, _impact_mark_radius(), sphere_radius
	)


func _update_dynamic_data() -> void:
	var sphere_radius := maxf(radius, MIN_RADIUS)
	_instances.update_dynamic_data(_instance_data, sphere_radius)
	_impact_marks.update_dynamic_data(_instance_data, sphere_radius)


func _update_instance_shape() -> void:
	_instances.set_shape(peak_position_ratio, roundness_power)


func _update_instance_sizes() -> void:
	for data in _instance_data:
		_update_instance_size(data)
	_update_dynamic_data()


func _update_instance_size(data: RadialEnergyInstance) -> void:
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
	_update_dynamic_data()


func _update_impact_style() -> void:
	_instances.set_impact_style(
		length_end_scale, length_change_power,
		thickness_end_scale, thickness_change_power,
		peak_end_position_ratio, fade_power
	)


func _update_impact_mark_style() -> void:
	_impact_marks.set_style(
		impact_mark_size_multiplier, impact_mark_opacity, impact_mark_softness
	)


func _retime_instance(data: RadialEnergyInstance) -> void:
	var was_responding := data.elapsed_time >= data.travel_duration
	var travel_progress := data.travel_progress()
	var impact_elapsed := data.impact_elapsed()
	data.travel_duration = _travel_duration_for(
		data.travel_radius_ratio, data.speed_random_factor
	)
	data.impact_duration = impact_response_duration
	data.fade_duration = fade_duration
	data.movement_curve_power = movement_curve_power
	if was_responding:
		data.elapsed_time = data.travel_duration + minf(
			impact_elapsed, maxf(data.impact_duration, data.fade_duration)
		)
	else:
		data.elapsed_time = travel_progress * data.travel_duration


func _travel_radius_ratio() -> float:
	return maxf(radius_ratio + collision_offset_ratio, MIN_TRAVEL_RADIUS_RATIO)


func _travel_duration_for(distance_ratio: float, random_factor: float) -> float:
	var speed_scale := 1.0 + random_factor * travel_speed_variation_ratio
	var varied_speed := maxf(travel_speed * speed_scale, MIN_TRAVEL_SPEED)
	return maxf(distance_ratio / varied_speed, MIN_TRAVEL_DURATION)


func _impact_mark_radius() -> float:
	return maxf(
		radius * (radius_ratio + impact_mark_offset_ratio),
		MIN_RADIUS
	)


func _bounds_radius() -> float:
	var bounds_ratio := maxf(
		1.0,
		maxf(_travel_radius_ratio(), radius_ratio + impact_mark_offset_ratio)
	)
	return maxf(radius, MIN_RADIUS) * bounds_ratio


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
			_impact_marks.update_instance_layout(data, instance_index)


func _random_direction(excluded_data: RadialEnergyInstance) -> Vector3:
	var candidate := Vector3.RIGHT
	for _attempt in range(MAX_DIRECTION_ATTEMPTS):
		var y := _rng.randf_range(-1.0, 1.0)
		var angle := _rng.randf_range(0.0, TAU)
		var horizontal_radius := sqrt(maxf(0.0, 1.0 - y * y))
		candidate = Vector3(horizontal_radius * cos(angle), y, horizontal_radius * sin(angle))
		if not _is_direction_crowded(candidate, excluded_data):
			break
	return candidate


func _is_direction_crowded(
	candidate: Vector3, excluded_data: RadialEnergyInstance
) -> bool:
	for data in _instance_data:
		if data != excluded_data and candidate.dot(data.direction) > MAX_DIRECTION_DOT:
			return true
	return false


func _varied_ratio(
	base_value: float, variation: float, random_factor: float, minimum_value: float
) -> float:
	var minimum := maxf(base_value - variation, minimum_value)
	return lerpf(minimum, base_value + variation, (random_factor + 1.0) * 0.5)
