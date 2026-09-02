@tool
class_name ShellContacts
extends Node3D

const EFFECT_TIME_PARAMETER: StringName = &"effect_time"
const DIRECTION_SLOT_COUNT := 24
const DIRECTION_ANCHOR_COUNT := 10
const DIRECTION_GAP_COUNT := 2
const MIN_GAP_WIDTH := 2
const MAX_GAP_WIDTH := 4
const MAX_CLUSTER_SIZE := 3
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
var _direction_rotation_offset: float = 0.0
var _direction_anchor_slots := PackedInt32Array()
var _event_anchor_assignments := PackedInt32Array()
var _anchor_cluster_sizes := PackedInt32Array()
var _gap_widths := PackedInt32Array()
var _event_pool: Array[ShellContactEvent] = []
var _rng := RandomNumberGenerator.new()

@onready var _filament_splat_batch: FilamentSplatBatch3D = $FilamentSplatBatch3D
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
	_event_pool.clear()
	_generate_direction_pattern()

	for index in range(event_pool_size):
		var event := ShellContactEvent.new()
		_event_pool.append(event)
		if index < active_event_count:
			_spawn_event(event, index)
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
			_spawn_event(event, index)


func _spawn_event(event: ShellContactEvent, event_index: int) -> void:
	if _spawn_serial > 0 and _spawn_serial % active_event_count == 0:
		_generate_direction_pattern()

	var anchor_index := _event_anchor_assignments[event_index]
	var slot_index := _direction_anchor_slots[anchor_index]
	var slot_width := TAU / float(DIRECTION_SLOT_COUNT)
	var angle := float(slot_index) * slot_width + _direction_rotation_offset
	var is_cluster := _anchor_cluster_sizes[anchor_index] > 1
	var jitter_degrees := _rng.randf_range(4.0, 10.0) if is_cluster \
		else _rng.randf_range(3.0, 7.0)
	angle += deg_to_rad(jitter_degrees) * (-1.0 if _rng.randf() < 0.5 else 1.0)
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
	var reach_roll := _rng.randf()
	if reach_roll < 0.55:
		event.reach_type = ShellContactEvent.ReachType.FULL_CONTACT
		event.end_position = event.contact_position
	elif reach_roll < 0.75:
		event.reach_type = ShellContactEvent.ReachType.NEAR_SURFACE
		event.end_position = direction * inner_radius * _rng.randf_range(0.82, 0.95)
	elif reach_roll < 0.9:
		event.reach_type = ShellContactEvent.ReachType.SHORT_BURST
		event.end_position = direction * radius * _rng.randf_range(0.45, 0.7)
	else:
		event.reach_type = ShellContactEvent.ReachType.CONTACT_FIRST
		event.end_position = event.contact_position
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
	if event.reach_type == ShellContactEvent.ReachType.FULL_CONTACT:
		event.contact_duration = _rng.randf_range(0.03, 0.055)
		event.detach_duration = _rng.randf_range(0.045, 0.075)
		event.residue_duration = _rng.randf_range(0.02, 0.045) \
			if _rng.randf() < 0.65 else 0.0
		event.contact_lead_time = _rng.randf_range(0.002, 0.01)
	elif event.reach_type == ShellContactEvent.ReachType.CONTACT_FIRST:
		event.contact_duration = _rng.randf_range(0.03, 0.055)
		event.detach_duration = _rng.randf_range(0.045, 0.075)
		event.residue_duration = _rng.randf_range(0.02, 0.045) \
			if _rng.randf() < 0.65 else 0.0
		event.contact_lead_time = _rng.randf_range(0.01, 0.03)
	elif event.reach_type == ShellContactEvent.ReachType.NEAR_SURFACE:
		event.contact_duration = 0.0
		event.detach_duration = _rng.randf_range(0.045, 0.075)
		event.residue_duration = 0.0
		event.contact_lead_time = 0.0
	else:
		event.contact_duration = 0.0
		event.detach_duration = _rng.randf_range(0.025, 0.055)
		event.residue_duration = 0.0
		event.contact_lead_time = 0.0
	event.lifetime = event.growth_duration + event.contact_duration \
		+ event.detach_duration + event.residue_duration
	event.random_seed = _rng.randf()
	event.is_active = true
	_spawn_serial += 1


func _generate_direction_pattern() -> void:
	_direction_rotation_offset = _rng.randf_range(0.0, TAU)
	var blocked_slots := PackedByteArray()
	blocked_slots.resize(DIRECTION_SLOT_COUNT)
	_gap_widths.clear()
	var reserved_gap_count := 0
	var attempts := 0
	while reserved_gap_count < DIRECTION_GAP_COUNT and attempts < 100:
		attempts += 1
		var gap_start := _rng.randi_range(0, DIRECTION_SLOT_COUNT - 1)
		var gap_width := _rng.randi_range(MIN_GAP_WIDTH, MAX_GAP_WIDTH)
		if not _can_reserve_gap(blocked_slots, gap_start, gap_width):
			continue
		for offset in range(gap_width):
			blocked_slots[(gap_start + offset) % DIRECTION_SLOT_COUNT] = 1
		_gap_widths.append(gap_width)
		reserved_gap_count += 1
	assert(reserved_gap_count == DIRECTION_GAP_COUNT, "Direction Pattern requires all gaps.")

	var available_slots: Array[int] = []
	for slot_index in range(DIRECTION_SLOT_COUNT):
		if blocked_slots[slot_index] == 0:
			available_slots.append(slot_index)
	_shuffle_int_array(available_slots)
	assert(
		available_slots.size() >= DIRECTION_ANCHOR_COUNT,
		"Direction Pattern requires enough unblocked slots."
	)
	_direction_anchor_slots.clear()
	for index in range(DIRECTION_ANCHOR_COUNT):
		_direction_anchor_slots.append(available_slots[index])

	_event_anchor_assignments.clear()
	_anchor_cluster_sizes.clear()
	_anchor_cluster_sizes.resize(DIRECTION_ANCHOR_COUNT)
	for anchor_index in range(DIRECTION_ANCHOR_COUNT):
		_event_anchor_assignments.append(anchor_index)
		_anchor_cluster_sizes[anchor_index] = 1
	for event_index in range(DIRECTION_ANCHOR_COUNT, active_event_count):
		var cluster_candidates: Array[int] = []
		for anchor_index in range(DIRECTION_ANCHOR_COUNT):
			if _anchor_cluster_sizes[anchor_index] == 1:
				cluster_candidates.append(anchor_index)
		if cluster_candidates.is_empty():
			for anchor_index in range(DIRECTION_ANCHOR_COUNT):
				if _anchor_cluster_sizes[anchor_index] < MAX_CLUSTER_SIZE:
					cluster_candidates.append(anchor_index)
		var selected_index := _rng.randi_range(0, cluster_candidates.size() - 1)
		var selected_anchor := cluster_candidates[selected_index]
		_event_anchor_assignments.append(selected_anchor)
		_anchor_cluster_sizes[selected_anchor] += 1


func _can_reserve_gap(blocked_slots: PackedByteArray, start: int, width: int) -> bool:
	for offset in range(-1, width + 1):
		var slot_index := posmod(start + offset, DIRECTION_SLOT_COUNT)
		if blocked_slots[slot_index] != 0:
			return false
	return true


func _shuffle_int_array(values: Array[int]) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := _rng.randi_range(0, index)
		var temporary := values[index]
		values[index] = values[swap_index]
		values[swap_index] = temporary


func _update_geometry() -> void:
	if not is_node_ready() or _event_pool.is_empty():
		return

	var camera_frame := _get_camera_frame()
	var camera_position: Vector3 = camera_frame[3]
	_filament_splat_batch.rebuild(
		_event_pool,
		camera_position,
		camera_frame[0],
		camera_frame[1],
		radius
	)
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
