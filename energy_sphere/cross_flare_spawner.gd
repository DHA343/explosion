class_name CrossFlareSpawner
extends Node3D

const CROSS_FLARE_SCENE: PackedScene = preload("res://cross_flare/cross_flare.tscn")
const FLARE_HALF_EXTENT_SCALE: float = 1.5

@export_group("Spawn")
@export var enabled: bool = true
@export_range(0.0, 100.0, 0.5, "suffix:/s") var max_spawn_rate: float = 17.0
@export_range(0.1, 10.0, 0.1, "suffix:s") var spawn_rate_ramp_duration: float = 3.0
@export_range(0.0, 1.0, 0.01) var spawn_interval_random_ratio: float = 0.2
@export_range(1, 500, 1) var max_active_count: int = 100

@export_group("Spawn Area")
@export_range(0.0, 10.0, 0.1, "suffix:m") var inner_radius: float = 0.5
@export_range(0.0, 10.0, 0.1, "suffix:m") var outer_radius: float = 10.0
@export_range(0.0, 10.0, 0.1, "suffix:m") var top_height: float = 1.0
@export_range(-10.0, 0.0, 0.1, "suffix:m") var bottom_height: float = -1.0
@export var ground_y: float = 0.0
@export_range(0.0, 1.0, 0.01, "suffix:m") var ground_clearance: float = 0.1

var _active_flares: Array[CrossFlare] = []
var _spawn_elapsed: float = 0.0
var _spawn_accumulator: float = 0.0
var _next_spawn_threshold: float = 1.0
var _spawning: bool = false
var _rng := RandomNumberGenerator.new()
var _reported_invalid_spawn_area: bool = false


func _ready() -> void:
	_rng.randomize()
	set_process(false)


func _process(delta: float) -> void:
	_prune_invalid_flares()
	if not _spawning:
		return

	_spawn_elapsed += delta
	if not enabled:
		return

	var current_spawn_rate := _get_current_spawn_rate()
	if current_spawn_rate <= 0.0:
		return

	_spawn_accumulator += current_spawn_rate * delta
	var active_limit := maxi(max_active_count, 0)
	while _spawn_accumulator >= _next_spawn_threshold:
		if _active_flares.size() >= active_limit:
			_spawn_accumulator = 0.0
			_next_spawn_threshold = _get_next_spawn_threshold()
			break

		_spawn_one()
		_spawn_accumulator -= _next_spawn_threshold
		_next_spawn_threshold = _get_next_spawn_threshold()


func begin_spawn() -> void:
	_spawn_elapsed = 0.0
	_spawn_accumulator = 0.0
	_next_spawn_threshold = _get_next_spawn_threshold()
	_spawning = true
	set_process(true)


func reset_spawn() -> void:
	_spawning = false
	set_process(false)
	_spawn_elapsed = 0.0
	_spawn_accumulator = 0.0
	_next_spawn_threshold = 1.0
	for flare in _active_flares:
		if is_instance_valid(flare):
			flare.hide()
			flare.queue_free()
	_active_flares.clear()


func spawn(count: int = 1) -> void:
	if count <= 0:
		return

	_prune_invalid_flares()
	for _i in range(count):
		if _active_flares.size() >= maxi(max_active_count, 0):
			break
		_spawn_one()


func _spawn_one() -> void:
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

	var center := global_position
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


func _get_current_spawn_rate() -> float:
	var ramp_progress := clampf(_spawn_elapsed / spawn_rate_ramp_duration, 0.0, 1.0)
	return max_spawn_rate * ramp_progress


func _get_next_spawn_threshold() -> float:
	var random_ratio := clampf(spawn_interval_random_ratio, 0.0, 1.0)
	return maxf(
		_rng.randf_range(1.0 - random_ratio, 1.0 + random_ratio),
		0.001
	)


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


func _report_invalid_spawn_area_warning() -> void:
	if _reported_invalid_spawn_area:
		return
	_reported_invalid_spawn_area = true
	push_warning("CrossFlareSpawner has no spawnable height above the ground.")
