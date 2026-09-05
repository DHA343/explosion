class_name RadialEnergyInstance
extends RefCounted

var direction: Vector3 = Vector3.RIGHT
var travel_radius: float = 0.0
var brightness: float = 1.0
var lifetime: float = 1.0
var elapsed_time: float = 0.0
var lifetime_random_factor: float = 0.0
var length_random_factor: float = 0.0
var thickness_random_factor: float = 0.0


func advance(delta: float) -> void:
	elapsed_time += delta


func lifecycle_progress() -> float:
	return clampf(elapsed_time / lifetime, 0.0, 1.0)


func is_expired() -> bool:
	return elapsed_time >= lifetime
