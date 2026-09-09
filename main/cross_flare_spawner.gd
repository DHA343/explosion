class_name CrossFlareSpawner
extends Node3D

const CROSS_FLARE_SCENE: PackedScene = preload("res://cross_flare/cross_flare.tscn")
const FLARE_HALF_EXTENT_SCALE: float = 1.5

@export_group("Spawn")
@export var enabled: bool = true
@export_range(0.0, 1000.0, 1.0, "suffix:/s") var spawn_rate: float = 10.0
@export_range(0.0, 1.0, 0.01) var spawn_interval_random_ratio: float = 0.2
@export_range(1, 100, 1) var max_active_count: int = 50

@export_group("Spawn Area")
@export_node_path("Node3D") var energy_sphere_path: NodePath = NodePath("../EnergySphere")
@export_range(0.0, 100.0, 0.1) var spawn_distance_min: float = 0.5
@export_range(0.0, 100.0, 0.1) var spawn_distance_max: float = 10.0
@export var ground_y: float = 0.0
@export_range(0.0, 1.0, 0.01) var ground_clearance: float = 0.1

var _active_flares: Array[CrossFlare] = []
var _spawn_time_remaining: float = 0.0
var _rng := RandomNumberGenerator.new()
var _reported_missing_energy_sphere: bool = false
@onready var _energy_sphere: Node3D = get_node_or_null(energy_sphere_path)


func _ready() -> void:
	_rng.randomize()

	if _energy_sphere == null:
		_report_missing_energy_sphere()


func _process(delta: float) -> void:
	_prune_invalid_flares()

	if not enabled or spawn_rate <= 0.0:
		return

	_spawn_time_remaining -= delta
	while _spawn_time_remaining <= 0.0:
		if _active_flares.size() >= maxi(max_active_count, 0):
			_spawn_time_remaining = _get_next_spawn_interval()
			break

		_spawn_one()
		_spawn_time_remaining += _get_next_spawn_interval()


func spawn(count: int = 1) -> void:
	if count <= 0:
		return

	_prune_invalid_flares()
	for _i in range(count):
		if _active_flares.size() >= maxi(max_active_count, 0):
			break
		_spawn_one()


func _spawn_one() -> void:
	if _energy_sphere == null:
		_report_missing_energy_sphere()
		return

	if _active_flares.size() >= maxi(max_active_count, 0):
		return

	var flare := CROSS_FLARE_SCENE.instantiate() as CrossFlare
	if flare == null:
		push_error("Failed to instantiate CrossFlare.")
		return

	flare.autoplay = false
	add_child(flare)
	flare.global_position = _get_spawn_position(flare)
	flare.finished.connect(_on_flare_finished.bind(flare))
	_active_flares.append(flare)
	flare.play()


func _get_spawn_position(flare: CrossFlare) -> Vector3:
	var minimum_distance := maxf(spawn_distance_min, 0.0)
	var maximum_distance := maxf(spawn_distance_max, 0.0)
	if minimum_distance > maximum_distance:
		var distance_swap := minimum_distance
		minimum_distance = maximum_distance
		maximum_distance = distance_swap

	var direction := Vector3.ZERO
	while direction.length_squared() < 0.0001:
		direction = Vector3(
			_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(-1.0, 1.0))
	direction = direction.normalized()

	var position := _energy_sphere.global_position + direction * _rng.randf_range(
		minimum_distance, maximum_distance)
	var minimum_center_y := ground_y + _get_flare_half_extent(flare) + maxf(ground_clearance, 0.0)
	position.y = maxf(position.y, minimum_center_y)
	return position


func _get_next_spawn_interval() -> float:
	if spawn_rate <= 0.0:
		return INF

	var base_interval := 1.0 / spawn_rate
	var random_ratio := clampf(spawn_interval_random_ratio, 0.0, 1.0)
	return base_interval * _rng.randf_range(1.0 - random_ratio, 1.0 + random_ratio)


func _get_flare_half_extent(flare: CrossFlare) -> float:
	var size_random_ratio := maxf(flare.size_random_ratio, 0.0)
	var maximum_size := maxf(flare.size, 0.0) * (1.0 + size_random_ratio)
	return maximum_size * FLARE_HALF_EXTENT_SCALE


func _on_flare_finished(flare: CrossFlare) -> void:
	_active_flares.erase(flare)
	if is_instance_valid(flare):
		flare.queue_free()


func _prune_invalid_flares() -> void:
	for index in range(_active_flares.size() - 1, -1, -1):
		if not is_instance_valid(_active_flares[index]):
			_active_flares.remove_at(index)


func _report_missing_energy_sphere() -> void:
	if _reported_missing_energy_sphere:
		return
	_reported_missing_energy_sphere = true
	push_error("CrossFlareSpawner requires an EnergySphere Node3D reference.")
