class_name RadialEnergyInstance
extends RefCounted

var direction: Vector3 = Vector3.RIGHT
var orientation: Basis = Basis.IDENTITY
var travel_radius_ratio: float = 1.0
var brightness: float = 1.0
var travel_duration: float = 1.0
var impact_duration: float = 0.0
var fade_duration: float = 0.0
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


func movement_progress() -> float:
	return pow(travel_progress(), movement_curve_power)


func travel_progress() -> float:
	return clampf(elapsed_time / travel_duration, 0.0, 1.0)


func impact_progress() -> float:
	if impact_duration <= 0.0:
		return 0.0
	return clampf((elapsed_time - travel_duration) / impact_duration, 0.0, 1.0)


func fade_progress() -> float:
	if fade_duration <= 0.0:
		return 1.0
	return clampf((elapsed_time - travel_duration) / fade_duration, 0.0, 1.0)


func impact_elapsed() -> float:
	return maxf(elapsed_time - travel_duration, 0.0)


func cycle_duration() -> float:
	return travel_duration + maxf(impact_duration, fade_duration)


func overflow_time() -> float:
	return maxf(elapsed_time - cycle_duration(), 0.0)


func is_expired() -> bool:
	return elapsed_time >= cycle_duration()
