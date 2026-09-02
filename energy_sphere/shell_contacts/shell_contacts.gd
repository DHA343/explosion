@tool
class_name ShellContacts
extends Node3D

const EFFECT_TIME_PARAMETER: StringName = &"effect_time"
const SECTOR_COUNT := 16
const DEFAULT_INNER_RADIUS_RATIO := 0.94

@export_range(0.05, 10.0, 0.01, "suffix:m") var radius: float = 0.5:
	set(value):
		var used_default_inner_radius := is_equal_approx(
			inner_radius,
			radius * DEFAULT_INNER_RADIUS_RATIO
		)
		radius = value
		if used_default_inner_radius:
			inner_radius = radius * DEFAULT_INNER_RADIUS_RATIO
		if is_node_ready():
			_restart_scheduler()

@export_range(0.05, 10.0, 0.01, "suffix:m") var inner_radius: float = 0.47:
	set(value):
		inner_radius = value
		if is_node_ready():
			_restart_scheduler()

@export_range(20, 24, 1) var event_pool_size: int = 24:
	set(value):
		event_pool_size = value
		if is_node_ready():
			_restart_scheduler()

@export_range(14, 18, 1) var active_event_count: int = 16:
	set(value):
		active_event_count = value
		if is_node_ready():
			_restart_scheduler()

@export_range(0, 9999, 1) var random_seed: int = 17:
	set(value):
		random_seed = value
		if is_node_ready():
			_restart_scheduler()

@export var preview_enabled: bool = false:
	set(value):
		preview_enabled = value
		if is_node_ready():
			_apply_preview_time()

@export_range(0.0, 10.0, 0.01, "suffix:s") var preview_time: float = 0.0:
	set(value):
		preview_time = value
		if is_node_ready() and preview_enabled:
			_apply_preview_time()

var _elapsed_time: float = 0.0
var _spawn_serial: int = 0
var _sector_rotation_offset: float = 0.0
var _event_pool: Array[ShellContactEvent] = []
var _rng := RandomNumberGenerator.new()

@onready var _filament_batch: FilamentBatch3D = $FilamentBatch3D
@onready var _contact_patch_batch: ContactPatchBatch3D = $ContactPatchBatch3D
@onready var _interaction_halo: MeshInstance3D = $InteractionHalo


func _ready() -> void:
	_restart_scheduler()
	if preview_enabled:
		_apply_preview_time()


func _process(delta: float) -> void:
	if not preview_enabled:
		_elapsed_time += delta
		_advance_scheduler(delta)
	_update_geometry()


func _restart_scheduler() -> void:
	_rng.seed = random_seed
	_elapsed_time = 0.0
	_spawn_serial = 0
	_sector_rotation_offset = _rng.randf_range(0.0, TAU)
	_event_pool.clear()

	for index in range(event_pool_size):
		var event := ShellContactEvent.new()
		_event_pool.append(event)
		if index < active_event_count:
			_spawn_event(event, index % SECTOR_COUNT)
			var stagger := float(index) / float(active_event_count)
			event.advance(event.lifetime * stagger)

	_update_halo_size()
	_update_geometry()


func _apply_preview_time() -> void:
	_restart_scheduler()
	var remaining_time := preview_time
	while remaining_time > 0.0:
		var step := minf(remaining_time, 1.0 / 120.0)
		_advance_scheduler(step)
		remaining_time -= step
	_elapsed_time = preview_time
	_update_geometry()


func _advance_scheduler(delta: float) -> void:
	for index in range(active_event_count):
		var event := _event_pool[index]
		event.advance(delta)
		if event.elapsed >= event.lifetime:
			_spawn_event(event, index % SECTOR_COUNT)


func _spawn_event(event: ShellContactEvent, sector_index: int) -> void:
	if _spawn_serial > 0 and _spawn_serial % active_event_count == 0:
		_sector_rotation_offset = _rng.randf_range(0.0, TAU)

	var sector_width := TAU / float(SECTOR_COUNT)
	var angle := float(sector_index) * sector_width + _sector_rotation_offset
	angle += _rng.randf_range(-sector_width * 0.4, sector_width * 0.4)
	var camera_frame := _get_camera_frame()
	var camera_right: Vector3 = camera_frame[0]
	var camera_up: Vector3 = camera_frame[1]
	var view_direction: Vector3 = camera_frame[2]
	var screen_direction := camera_right * cos(angle) + camera_up * sin(angle)
	var screen_tangent := -camera_right * sin(angle) + camera_up * cos(angle)
	var uses_depth_accent := _rng.randf() < 0.25
	var depth_tilt_degrees := _rng.randf_range(30.0, 50.0) if uses_depth_accent \
		else _rng.randf_range(10.0, 30.0)
	if _rng.randf() < 0.5:
		depth_tilt_degrees *= -1.0
	var depth_tilt := deg_to_rad(depth_tilt_degrees)
	var direction := (
		screen_direction * cos(depth_tilt) + view_direction * sin(depth_tilt)
	).normalized()

	var width_roll := _rng.randf()
	var body_width_ratio: float
	if width_roll < 0.25:
		event.width_class = 0
		body_width_ratio = _rng.randf_range(0.05, 0.08)
	elif width_roll < 0.7:
		event.width_class = 1
		body_width_ratio = _rng.randf_range(0.10, 0.14)
	else:
		event.width_class = 2
		body_width_ratio = _rng.randf_range(0.16, 0.21)

	event.elapsed = 0.0
	event.phase = ShellContactEvent.Phase.GROWTH
	event.direction = direction
	event.start_position = direction * radius * _rng.randf_range(0.18, 0.3)
	event.contact_position = direction * inner_radius
	event.body_width = radius * body_width_ratio
	event.hot_core_width = event.body_width * _rng.randf_range(0.55, 0.7)
	var brightness_roll := _rng.randf()
	if brightness_roll < 0.25:
		event.brightness = _rng.randf_range(0.42, 0.62)
	elif brightness_roll < 0.75:
		event.brightness = _rng.randf_range(0.7, 0.92)
	else:
		event.brightness = _rng.randf_range(0.94, 1.12)
	event.depth_tilt = depth_tilt
	event.bend_offset = screen_tangent * radius * _rng.randf_range(-0.05, 0.05)
	event.contact_scale = _rng.randf_range(0.9, 1.1)
	event.growth_duration = _rng.randf_range(0.055, 0.09)
	event.contact_duration = _rng.randf_range(0.03, 0.055)
	event.detach_duration = _rng.randf_range(0.045, 0.075)
	event.residue_duration = _rng.randf_range(0.02, 0.045) if _rng.randf() < 0.65 else 0.0
	event.lifetime = event.growth_duration + event.contact_duration \
		+ event.detach_duration + event.residue_duration
	event.random_seed = _rng.randf()
	event.is_active = true
	_spawn_serial += 1


func _update_geometry() -> void:
	if not is_node_ready() or _event_pool.is_empty():
		return

	var camera_position: Vector3 = _get_camera_frame()[3]
	_filament_batch.rebuild(_event_pool, camera_position, radius)
	_contact_patch_batch.rebuild(_event_pool, camera_position, inner_radius)

	var halo_material := _interaction_halo.material_override as ShaderMaterial
	assert(halo_material != null, "InteractionHalo requires a ShaderMaterial override.")
	halo_material.set_shader_parameter(EFFECT_TIME_PARAMETER, _elapsed_time)


func _update_halo_size() -> void:
	if not is_node_ready():
		return
	var halo_mesh := _interaction_halo.mesh as QuadMesh
	assert(halo_mesh != null, "InteractionHalo requires a QuadMesh.")
	halo_mesh.size = Vector2.ONE * radius * 2.15


func _get_camera_frame() -> Array[Vector3]:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return [Vector3.RIGHT, Vector3.UP, Vector3.BACK, Vector3.BACK * radius * 3.0]

	var inverse_basis := global_transform.basis.inverse()
	var camera_right := (inverse_basis * camera.global_transform.basis.x).normalized()
	var camera_up := (inverse_basis * camera.global_transform.basis.y).normalized()
	var camera_position := to_local(camera.global_position)
	var view_direction := camera_position.normalized()
	return [camera_right, camera_up, view_direction, camera_position]
