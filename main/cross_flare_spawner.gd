class_name CrossFlareSpawner
extends Node3D

const CROSS_FLARE_SCENE: PackedScene = preload("res://cross_flare/cross_flare.tscn")
const FLARE_HALF_EXTENT_SCALE: float = 1.5

@export_group("Spawn")
@export var enabled: bool = true
@export_range(0.0, 1000.0, 1.0, "suffix:/s") var spawn_rate: float = 10.0
@export_range(0.0, 1.0, 0.01) var spawn_interval_random_ratio: float = 0.2
@export_range(1, 500, 1) var max_active_count: int = 100

@export_group("Spawn Area")
@export_node_path("Node3D") var energy_sphere_path: NodePath = NodePath("../EnergySphere")
@export_range(0.0, 10.0, 0.1, "suffix:m") var inner_radius: float = 0.5
@export_range(0.0, 10.0, 0.1, "suffix:m") var outer_radius: float = 10.0
@export_range(0.0, 10.0, 0.1, "suffix:m") var top_height: float = 1.0
@export_range(-10.0, 0.0, 0.1, "suffix:m") var bottom_height: float = -1.0
@export var ground_y: float = 0.0
@export_range(0.0, 1.0, 0.01, "suffix:m") var ground_clearance: float = 0.1

var _active_flares: Array[CrossFlare] = []
var _spawn_time_remaining: float = 0.0
var _rng := RandomNumberGenerator.new()
var _reported_missing_energy_sphere: bool = false
var _reported_invalid_spawn_area: bool = false
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
	var spawn_position: Variant = _get_spawn_position(flare)
	if spawn_position == null:
		flare.queue_free()
		return

	flare.global_position = spawn_position
	flare.finished.connect(_on_flare_finished.bind(flare))
	_active_flares.append(flare)
	flare.play()


func _get_spawn_position(flare: CrossFlare) -> Variant:
	var minimum_radius := maxf(inner_radius, 0.0)
	var maximum_radius := maxf(outer_radius, 0.0)
	if minimum_radius > maximum_radius:
		var radius_swap := minimum_radius
		minimum_radius = maximum_radius
		maximum_radius = radius_swap

	var minimum_height := bottom_height
	var maximum_height := top_height
	if minimum_height > maximum_height:
		var height_swap := minimum_height
		minimum_height = maximum_height
		maximum_height = height_swap

	var center := _energy_sphere.global_position
	var minimum_ground_y := (
		ground_y
		+ _get_flare_half_extent(flare)
		+ maxf(ground_clearance, 0.0)
	)
	var effective_bottom_y := maxf(center.y + minimum_height, minimum_ground_y)
	var effective_top_y := center.y + maximum_height
	if effective_bottom_y > effective_top_y:
		_report_invalid_spawn_area_warning()
		return null

	var radius_squared := _rng.randf_range(
		minimum_radius * minimum_radius,
		maximum_radius * maximum_radius
	)
	var radius := sqrt(radius_squared)
	var angle := _rng.randf_range(0.0, TAU)
	return Vector3(
		center.x + cos(angle) * radius,
		_rng.randf_range(effective_bottom_y, effective_top_y),
		center.z + sin(angle) * radius)


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


func _report_invalid_spawn_area_warning() -> void:
	if _reported_invalid_spawn_area:
		return
	_reported_invalid_spawn_area = true
	push_warning("CrossFlareSpawner has no spawnable height above the ground.")
