extends Node3D

const PALETTE_DIRECTORY := "res://cross_flare/palettes"
const CROSS_FLARE_SCENE: PackedScene = preload("res://cross_flare/cross_flare.tscn")

@export_range(0, 32, 1) var initial_spawn_count: int = 6
@export_range(1, 64, 1) var max_alive: int = 10
@export_range(0.01, 2.0, 0.01, "suffix:s") var spawn_interval_min: float = 0.07
@export_range(0.01, 2.0, 0.01, "suffix:s") var spawn_interval_max: float = 0.15
@export_range(0.0, 0.45, 0.01) var screen_margin_ratio: float = 0.10
@export_range(0.1, 50.0, 0.1, "suffix:m") var spawn_depth: float = 6.5
@export var randomize_seed_on_start: bool = true
@export var random_seed: int = 1

@onready var _camera: Camera3D = $Camera3D
@onready var _spawn_timer: Timer = $SpawnTimer

var _palettes: Array[CrossFlarePalette] = []
var _active_flares: Array[CrossFlare] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_initialize_rng()
	var palettes_available := _load_palettes()

	if not palettes_available:
		return

	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	var spawn_count := mini(maxi(initial_spawn_count, 0), maxi(max_alive, 0))
	for _i in range(spawn_count):
		_spawn_flare(true)
	_schedule_next_spawn()


func _initialize_rng() -> void:
	if randomize_seed_on_start:
		_rng.randomize()
	else:
		_rng.seed = random_seed


func _load_palettes() -> bool:
	var directory := DirAccess.open(PALETTE_DIRECTORY)
	if directory == null:
		push_error("Failed to open CrossFlare palette directory: %s" % PALETTE_DIRECTORY)
		return false

	var palette_paths: Array[String] = []
	directory.list_dir_begin()
	var file_name := directory.get_next()
	while not file_name.is_empty():
		if not directory.current_is_dir() and file_name.get_extension().to_lower() == "tres":
			palette_paths.append(PALETTE_DIRECTORY.path_join(file_name))
		file_name = directory.get_next()
	directory.list_dir_end()
	palette_paths.sort()

	for palette_path in palette_paths:
		var resource: Resource = load(palette_path)
		if resource is CrossFlarePalette:
			_palettes.append(resource as CrossFlarePalette)

	if _palettes.is_empty():
		push_error("No valid CrossFlarePalette resources found in: %s" % PALETTE_DIRECTORY)
		return false
	return true


func _pick_palette() -> CrossFlarePalette:
	var total_weight: float = 0.0

	for palette_resource in _palettes:
		total_weight += maxf(palette_resource.selection_weight, 0.0)

	if total_weight <= 0.0:
		return null

	var selection := _rng.randf_range(0.0, total_weight)
	for palette_resource in _palettes:
		selection -= maxf(palette_resource.selection_weight, 0.0)
		if selection <= 0.0:
			return palette_resource

	return _palettes.back()


func _spawn_flare(initial: bool = false) -> void:
	if _active_flares.size() >= max_alive:
		return

	var flare := CROSS_FLARE_SCENE.instantiate() as CrossFlare
	if flare == null:
		push_error("Failed to instantiate CrossFlare.")
		return

	var selected_palette := _pick_palette()
	if selected_palette == null:
		push_error("No selectable CrossFlare palette is available.")
		return

	flare.autoplay = false
	flare.palette = selected_palette
	flare.position = _random_spawn_position()

	flare.finished.connect(_on_flare_finished.bind(flare))
	add_child(flare)
	_active_flares.append(flare)

	flare.play()
	if initial:
		flare.seek(_rng.randf_range(0.0, flare.duration * 0.9))


func _random_spawn_position() -> Vector3:
	var viewport_size := get_viewport().get_visible_rect().size
	var margin_ratio := clampf(screen_margin_ratio, 0.0, 0.45)
	var margin_x := viewport_size.x * margin_ratio
	var margin_y := viewport_size.y * margin_ratio
	var screen_position := Vector2(
		_rng.randf_range(margin_x, viewport_size.x - margin_x),
		_rng.randf_range(margin_y, viewport_size.y - margin_y))
	return _camera.project_position(screen_position, spawn_depth)


func _on_spawn_timer_timeout() -> void:
	_spawn_flare()
	_schedule_next_spawn()


func _schedule_next_spawn() -> void:
	var minimum := maxf(minf(spawn_interval_min, spawn_interval_max), 0.01)
	var maximum := maxf(maxf(spawn_interval_min, spawn_interval_max), minimum)
	_spawn_timer.start(_rng.randf_range(minimum, maximum))


func _on_flare_finished(flare: CrossFlare) -> void:
	_active_flares.erase(flare)
	if is_instance_valid(flare):
		flare.queue_free()
