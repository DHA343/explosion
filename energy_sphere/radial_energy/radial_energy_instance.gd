class_name RadialEnergyInstance
extends RefCounted

var direction: Vector3 = Vector3.RIGHT
var travel_radius: float = 0.0
var travel_radius_ratio: float = 1.0
var brightness: float = 1.0
var travel_duration: float = 1.0
var response_duration: float = 0.0
var post_travel_duration: float = 0.0
var elapsed_time: float = 0.0
var duration_random_factor: float = 0.0
var length_random_factor: float = 0.0
var thickness_random_factor: float = 0.0


func advance(delta: float) -> void:
	elapsed_time += delta


func travel_progress() -> float:
	return clampf(elapsed_time / travel_duration, 0.0, 1.0)


func response_progress() -> float:
	if response_duration <= 0.0:
		return 0.0
	return clampf((elapsed_time - travel_duration) / response_duration, 0.0, 1.0)


func travel_ending_progress(duration: float) -> float:
	var clamped_duration := minf(duration, travel_duration)
	if clamped_duration <= 0.0:
		return 1.0
	return clampf(
		(elapsed_time - (travel_duration - clamped_duration)) / clamped_duration,
		0.0,
		1.0
	)


func impact_fade_progress(duration: float) -> float:
	if duration <= 0.0:
		return 1.0
	return clampf(
		(elapsed_time - travel_duration) / duration,
		0.0,
		1.0
	)


func cycle_duration() -> float:
	return travel_duration + post_travel_duration


func is_expired() -> bool:
	return elapsed_time >= cycle_duration()
