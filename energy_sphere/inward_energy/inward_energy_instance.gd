class_name InwardEnergyInstance
extends RefCounted

var direction: Vector3 = Vector3.RIGHT
var orientation: Basis = Basis.IDENTITY
var spawn_offset_ratio: float = 0.0
var travel_duration: float = 1.0
var elapsed_time: float = 0.0
var movement_curve_power: float = 1.0
var speed_random_factor: float = 0.0
var length_random_factor: float = 0.0
var thickness_random_factor: float = 0.0
var length_ratio: float = 0.0
var thickness_ratio: float = 0.0


func advance(delta: float) -> void:
	elapsed_time += delta


func set_direction(value: Vector3) -> void:
	direction = value.normalized()

	var alignment_reference := Vector3.FORWARD
	if absf(direction.dot(alignment_reference)) > 0.95:
		alignment_reference = Vector3.RIGHT
	var axis_x := alignment_reference.cross(direction).normalized()
	var axis_z := axis_x.cross(direction).normalized()
	orientation = Basis(axis_x, direction, axis_z)


func spawn_radius_ratio() -> float:
	return 1.0 + spawn_offset_ratio


func movement_progress() -> float:
	return pow(travel_progress(), movement_curve_power)


func travel_progress() -> float:
	return clampf(elapsed_time / travel_duration, 0.0, 1.0)


func overflow_time() -> float:
	return maxf(elapsed_time - travel_duration, 0.0)


func is_expired() -> bool:
	return elapsed_time >= travel_duration
