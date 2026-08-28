class_name EnergyEmitter
extends Node3D

const ENERGY_MOTE_SCENE := preload("res://orb/energy_emission/energy_mote.tscn")

@export_group("Emission")
@export_range(1.0, 200.0, 1.0, "suffix:particles/s") var spawn_rate := 100.0
@export_range(0.0, 1.0, 0.01) var spawn_randomness := 0.2

@export_group("Collision")
@export_range(0.15, 3.0, 0.01, "suffix:m") var collision_radius := 0.5

@export_group("Motion")
@export_range(0.1, 30.0, 0.1) var speed := 10.0
@export_range(0.0, 10.0, 0.1) var speed_variation := 2.0
@export_range(0.1, 10.0, 0.1) var deceleration_exponent := 2.0
@export_range(0.05, 1.0, 0.05) var minimum_speed_ratio := 0.25

@export_group("Appearance")
@export_range(0.01, 0.3, 0.005) var size := 0.08
@export_range(0.0, 0.1, 0.005) var size_variation := 0.01

@export_group("Impact")
@export_range(0.0, 1.0, 0.05) var impact_strength := 0.7
@export_range(0.05, 0.3, 0.01, "suffix:s") var impact_duration := 0.12

@export_group("Lifetime")
@export_range(0.01, 0.5, 0.01, "suffix:s") var fade_duration := 0.1

@export_group("Rendering")
@export_color_no_alpha var color := Color.WHITE
@export_range(0.0, 8.0, 0.1) var emission := 2.0

var spawn_time_remaining := 0.0


func _ready() -> void:
	_spawn_energy_mote()
	spawn_time_remaining = _next_spawn_interval()


func _process(delta: float) -> void:
	spawn_time_remaining -= delta

	while spawn_time_remaining <= 0.0:
		_spawn_energy_mote()
		spawn_time_remaining += _next_spawn_interval()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_spawn_energy_mote()


func _spawn_energy_mote() -> void:
	var energy_mote := ENERGY_MOTE_SCENE.instantiate() as EnergyMote
	energy_mote.sphere_center = global_position
	energy_mote.sphere_radius = collision_radius
	energy_mote.size = maxf(size + randf_range(-size_variation, size_variation), 0.005)
	energy_mote.initial_speed = maxf(speed + randf_range(-speed_variation, speed_variation), 0.05)
	energy_mote.deceleration_exponent = deceleration_exponent
	energy_mote.minimum_speed_ratio = minimum_speed_ratio
	energy_mote.impact_strength = impact_strength
	energy_mote.impact_duration = impact_duration
	energy_mote.fade_duration = fade_duration
	energy_mote.color = color
	energy_mote.emission = emission
	energy_mote.direction = _random_direction()
	energy_mote.shape_seed = randf()
	add_child(energy_mote)


func _next_spawn_interval() -> float:
	var interval := 1.0 / spawn_rate
	var offset := randf_range(-spawn_randomness, spawn_randomness)
	return maxf(interval * (1.0 + offset), 0.001)


func _random_direction() -> Vector3:
	var vertical := randf_range(-1.0, 1.0)
	var angle := randf_range(0.0, TAU)
	var horizontal := sqrt(1.0 - vertical * vertical)
	return Vector3(cos(angle) * horizontal, vertical, sin(angle) * horizontal)
