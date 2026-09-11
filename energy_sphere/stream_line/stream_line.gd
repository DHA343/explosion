@tool
class_name StreamLine
extends Node3D

const STREAM_SHADER: Shader = preload("res://energy_sphere/stream_line/stream_line.gdshader")
const BASE_RADIUS: float = 0.5
const WHITE_SEGMENT_CAPACITY: int = 3
const MIN_CURVE_LENGTH: float = 0.001
const LINE_KIND_CYAN: int = 0
const LINE_KIND_NAVY: int = 1
const LINE_KIND_WHITE: int = 2
const LINE_KIND_UNASSIGNED: int = -1

@export_group("Curve")

@export_range(0.02, 0.10, 0.005) var mesh_sample_interval: float = 0.04:
	set(value):
		mesh_sample_interval = value
		_request_mesh_rebuild()

@export_group("Stream Wave")

@export_range(0.0, 0.60, 0.01, "suffix:m") var stream_wave_amplitude: float = 0.20:
	set(value):
		stream_wave_amplitude = value
		_request_parameter_sync()

@export_range(0.5, 3.0, 0.05) var stream_wave_cycles: float = 1.5:
	set(value):
		stream_wave_cycles = value
		_request_parameter_sync()

@export_range(0.0, 2.0, 0.05, "suffix:/s") var stream_wave_speed: float = 0.50:
	set(value):
		stream_wave_speed = value
		_request_parameter_sync()

@export_range(0.0, 1.0, 0.05) var stream_wave_outer_scale: float = 0.60:
	set(value):
		stream_wave_outer_scale = value
		_request_parameter_sync()

@export_range(0.20, 0.70, 0.01) var stream_wave_peak_position: float = 0.45:
	set(value):
		stream_wave_peak_position = value
		_request_parameter_sync()

@export_range(0.0, 0.50, 0.05) var stream_wave_inner_scale: float = 0.10:
	set(value):
		stream_wave_inner_scale = value
		_request_parameter_sync()

@export_group("Line Wave")

@export_range(1.0, 5.0, 0.10) var line_wave_cycles: float = 2.5:
	set(value):
		line_wave_cycles = value
		_request_parameter_sync()

@export_range(0.0, 3.0, 0.05, "suffix:/s") var line_wave_speed: float = 0.80:
	set(value):
		line_wave_speed = value
		_request_parameter_sync()

@export_range(0.0, 0.50, 0.05) var line_wave_noise_amount: float = 0.20:
	set(value):
		line_wave_noise_amount = value
		_request_parameter_sync()

@export_range(0.0, 0.03, 0.001) var line_wave_inner_amplitude: float = 0.005:
	set(value):
		line_wave_inner_amplitude = value
		_request_parameter_sync()

@export_group("Cyan Lines")

@export_range(0, 8, 1) var cyan_count: int = 3:
	set(value):
		cyan_count = value
		_request_line_rebuild()

@export_color_no_alpha var cyan_color: Color = Color(0.08, 0.72, 1.0, 1.0):
	set(value):
		cyan_color = value
		_request_variant_refresh()

@export_range(0.5, 4.0, 0.1) var cyan_intensity: float = 2.0:
	set(value):
		cyan_intensity = value
		_request_variant_refresh()

@export_range(0.01, 0.18, 0.005) var cyan_width: float = 0.06:
	set(value):
		cyan_width = value
		_request_variant_refresh()

@export_range(0.0, 0.10, 0.005) var cyan_line_wave_amplitude: float = 0.025:
	set(value):
		cyan_line_wave_amplitude = value
		_request_variant_refresh()

@export_group("Navy Lines")

@export_range(0, 8, 1) var navy_count: int = 3:
	set(value):
		navy_count = value
		_request_line_rebuild()

@export_color_no_alpha var navy_color: Color = Color(0.015, 0.12, 0.36, 1.0):
	set(value):
		navy_color = value
		_request_variant_refresh()

@export_range(0.5, 3.0, 0.1) var navy_intensity: float = 1.2:
	set(value):
		navy_intensity = value
		_request_variant_refresh()

@export_range(0.01, 0.18, 0.005) var navy_width: float = 0.04:
	set(value):
		navy_width = value
		_request_variant_refresh()

@export_range(0.0, 0.10, 0.005) var navy_line_wave_amplitude: float = 0.02:
	set(value):
		navy_line_wave_amplitude = value
		_request_variant_refresh()

@export_group("Line Variation")

@export_range(0.05, 0.30, 0.01) var line_spread_radius: float = 0.18:
	set(value):
		line_spread_radius = value
		_request_variant_refresh()

@export_range(0.0, 0.35, 0.05) var line_variation: float = 0.15:
	set(value):
		line_variation = value
		_request_variant_refresh()

@export var line_seed: int = 17041:
	set(value):
		line_seed = value
		_request_variant_refresh()

@export_group("Appearance")

@export_range(0.0, 0.40, 0.01) var edge_softness: float = 0.12:
	set(value):
		edge_softness = value
		_request_parameter_sync()

@export_range(0.0, 1.0, 0.05) var edge_erosion_strength: float = 0.30:
	set(value):
		edge_erosion_strength = value
		_request_parameter_sync()

@export_range(0.0, 0.60, 0.05) var body_variation_strength: float = 0.15:
	set(value):
		body_variation_strength = value
		_request_parameter_sync()

@export_group("Offset")

@export_range(0.25, 1.0, 0.05) var inner_offset_scale: float = 0.50:
	set(value):
		inner_offset_scale = value
		_request_parameter_sync()

@export_group("White Line")

@export_color_no_alpha var white_color: Color = Color(0.88, 0.98, 1.0, 1.0):
	set(value):
		white_color = value
		_request_white_sync()

@export_range(1.0, 5.0, 0.1) var white_intensity: float = 3.0:
	set(value):
		white_intensity = value
		_request_white_sync()

@export_range(0.01, 0.08, 0.005) var white_width: float = 0.018:
	set(value):
		white_width = value
		_request_white_sync()

@export_range(-0.30, 0.30, 0.01) var white_offset: float = 0.075:
	set(value):
		white_offset = value
		_request_white_sync()

@export_range(0.0, 0.10, 0.005) var white_line_wave_amplitude: float = 0.012:
	set(value):
		white_line_wave_amplitude = value
		_request_white_sync()

@export_range(0.05, 0.25, 0.01) var white_segment_length: float = 0.12:
	set(value):
		white_segment_length = value
		_request_white_sync()

@export_range(0.50, 3.0, 0.05, "suffix:/s") var white_speed: float = 1.50:
	set(value):
		white_speed = value
		_request_parameter_sync()

@export_range(0.20, 2.0, 0.05, "suffix:s") var white_interval_min: float = 0.40:
	set(value):
		white_interval_min = value
		_request_parameter_sync()

@export_range(0.40, 3.0, 0.05, "suffix:s") var white_interval_max: float = 1.20:
	set(value):
		white_interval_max = value
		_request_parameter_sync()

@export_range(1, 3, 1) var white_max_segments: int = 2:
	set(value):
		white_max_segments = value
		_request_parameter_sync()

@export_range(0.0, 1.0, 0.01) var white_preview_position: float = 0.50:
	set(value):
		white_preview_position = value
		_request_white_sync()

@export_group("Ends")

@export_range(0.02, 0.20, 0.01) var outer_fade_length: float = 0.08:
	set(value):
		outer_fade_length = value
		_request_parameter_sync()

@export_range(0.05, 0.35, 0.01) var inner_taper_length: float = 0.18:
	set(value):
		inner_taper_length = value
		_request_parameter_sync()

@export_range(1.0, 4.0, 0.1) var inner_taper_power: float = 1.8:
	set(value):
		inner_taper_power = value
		_request_parameter_sync()

@export_range(0.03, 0.25, 0.01) var inner_fade_length: float = 0.12:
	set(value):
		inner_fade_length = value
		_request_parameter_sync()

@export_range(0.0, 0.60, 0.05) var inner_erosion_strength: float = 0.25:
	set(value):
		inner_erosion_strength = value
		_request_parameter_sync()

var radius: float = BASE_RADIUS:
	set(value):
		if value <= 0.0:
			push_error("StreamLine radius must be greater than zero.")
			return
		radius = value
		if is_node_ready():
			_sync_radius()

var _connected_curve: Curve3D
var _shared_mesh: ArrayMesh
var _shared_material: ShaderMaterial
var _generated_line_nodes: Array[MeshInstance3D] = []
var _generated_line_kinds: Array[int] = []
var _white_segments: Array[Vector4] = []
var _white_spawn_cooldown: float = 0.0
var _mesh_rebuild_pending: bool = false
var _line_rebuild_pending: bool = false
var _random := RandomNumberGenerator.new()

@onready var _guide_path: Path3D = $GuidePath
@onready var _generated_lines: Node3D = $GeneratedLines


func _ready() -> void:
	scale = Vector3.ONE * _radius_scale()
	_reset_white_segments()
	_connect_curve()
	_rebuild_ribbon_mesh()
	_rebuild_line_instances()
	_refresh_line_variants()

	if Engine.is_editor_hint():
		_apply_white_preview()
	else:
		_random.randomize()
		_white_spawn_cooldown = _random_interval()

	_sync_shared_material()


func _exit_tree() -> void:
	_disconnect_curve()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	_update_white_segments(delta)


func _sync_radius() -> void:
	scale = Vector3.ONE * _radius_scale()
	_sync_shared_material()
	_update_custom_aabbs()
	_request_mesh_rebuild()


func _radius_scale() -> float:
	return radius / BASE_RADIUS


func _request_mesh_rebuild() -> void:
	if not is_inside_tree() or _mesh_rebuild_pending:
		return

	_mesh_rebuild_pending = true
	call_deferred("_deferred_rebuild_ribbon_mesh")


func _deferred_rebuild_ribbon_mesh() -> void:
	_mesh_rebuild_pending = false
	_rebuild_ribbon_mesh()


func _request_line_rebuild() -> void:
	if not is_inside_tree() or _line_rebuild_pending:
		return

	_line_rebuild_pending = true
	call_deferred("_deferred_rebuild_line_instances")


func _deferred_rebuild_line_instances() -> void:
	_line_rebuild_pending = false
	_rebuild_line_instances()
	_refresh_line_variants()
	_sync_shared_material()


func _request_variant_refresh() -> void:
	if not is_inside_tree():
		return
	_refresh_line_variants()
	_update_custom_aabbs()


func _request_white_sync() -> void:
	if not is_inside_tree():
		return
	if Engine.is_editor_hint():
		_apply_white_preview()
	_sync_shared_material()
	_update_custom_aabbs()


func _request_parameter_sync() -> void:
	if not is_inside_tree():
		return
	_sync_shared_material()
	_update_custom_aabbs()


func _connect_curve() -> void:
	if _guide_path == null or _guide_path.curve == null:
		return
	if _connected_curve == _guide_path.curve:
		return

	_disconnect_curve()
	_connected_curve = _guide_path.curve
	if not _connected_curve.changed.is_connected(_on_curve_changed):
		_connected_curve.changed.connect(_on_curve_changed)


func _disconnect_curve() -> void:
	if _connected_curve == null:
		return
	if _connected_curve.changed.is_connected(_on_curve_changed):
		_connected_curve.changed.disconnect(_on_curve_changed)
	_connected_curve = null


func _on_curve_changed() -> void:
	_connect_curve()
	_request_mesh_rebuild()


func _rebuild_ribbon_mesh() -> void:
	if not is_inside_tree():
		return

	_connect_curve()
	_shared_mesh = _build_ribbon_mesh()
	for line in _generated_line_nodes:
		line.mesh = _shared_mesh
		line.visible = _shared_mesh != null
	_update_custom_aabbs()


func _build_ribbon_mesh() -> ArrayMesh:
	if _guide_path == null or _guide_path.curve == null:
		return null

	var curve := _guide_path.curve
	if curve.point_count < 2:
		return null

	var curve_length := curve.get_baked_length()
	if curve_length <= MIN_CURVE_LENGTH:
		return null

	var scaled_curve_length := curve_length * _radius_scale()
	var sample_interval := maxf(mesh_sample_interval, 0.001)
	var sample_count := maxi(2, ceili(scaled_curve_length / sample_interval) + 1)
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	for sample_index in range(sample_count):
		var progress := float(sample_index) / float(sample_count - 1)
		var distance := curve_length * progress
		var position := curve.sample_baked(distance, true)
		var tangent_step := maxf(curve_length / float(sample_count - 1) * 0.5, 0.001)
		var previous := curve.sample_baked(maxf(distance - tangent_step, 0.0), true)
		var next := curve.sample_baked(minf(distance + tangent_step, curve_length), true)
		var tangent := next - previous
		if tangent.length_squared() <= 0.000001:
			tangent = Vector3.RIGHT
		tangent = tangent.normalized()

		vertices.append(position)
		vertices.append(position)
		normals.append(tangent)
		normals.append(tangent)
		uvs.append(Vector2(progress, 0.0))
		uvs.append(Vector2(progress, 1.0))

		if sample_index < sample_count - 1:
			var base_index := sample_index * 2
			indices.append(base_index)
			indices.append(base_index + 1)
			indices.append(base_index + 2)
			indices.append(base_index + 1)
			indices.append(base_index + 3)
			indices.append(base_index + 2)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	var ribbon_mesh := ArrayMesh.new()
	ribbon_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return ribbon_mesh


func _rebuild_line_instances() -> void:
	if not is_inside_tree() or _generated_lines == null:
		return

	_clear_generated_line_instances()
	_ensure_shared_material()

	var colored_count := cyan_count + navy_count
	for index in range(colored_count):
		_add_generated_line("ColoredLine%02d" % (index + 1), LINE_KIND_UNASSIGNED)

	_add_generated_line("WhiteLine", LINE_KIND_WHITE)


func _clear_generated_line_instances() -> void:
	for child in _generated_lines.get_children():
		_generated_lines.remove_child(child)
		child.free()
	_generated_line_nodes.clear()
	_generated_line_kinds.clear()


func _add_generated_line(line_name: String, kind: int) -> void:
	var line := MeshInstance3D.new()
	line.name = line_name
	line.mesh = _shared_mesh
	line.material_override = _shared_material
	line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	line.visible = _shared_mesh != null
	_generated_lines.add_child(line)
	line.owner = null
	_generated_line_nodes.append(line)
	_generated_line_kinds.append(kind)


func _ensure_shared_material() -> void:
	if _shared_material != null and _shared_material.shader == STREAM_SHADER:
		return

	_shared_material = ShaderMaterial.new()
	_shared_material.shader = STREAM_SHADER
	_shared_material.resource_local_to_scene = true


func _shuffled_color_kinds() -> Array[int]:
	var kinds: Array[int] = []
	for _index in range(cyan_count):
		kinds.append(LINE_KIND_CYAN)
	for _index in range(navy_count):
		kinds.append(LINE_KIND_NAVY)

	var rng := RandomNumberGenerator.new()
	rng.seed = line_seed
	for index in range(kinds.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var temporary := kinds[index]
		kinds[index] = kinds[swap_index]
		kinds[swap_index] = temporary
	return kinds


func _generate_cross_offsets(colored_count: int) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	if colored_count <= 0:
		return positions

	var rng := RandomNumberGenerator.new()
	rng.seed = line_seed
	var spread := maxf(line_spread_radius, 0.0)
	var minimum_distance := spread * 0.55 / sqrt(float(maxi(colored_count, 1)))
	const MAX_POSITION_ATTEMPTS: int = 24

	for _index in range(colored_count):
		var candidate := Vector2.ZERO
		for _attempt in range(MAX_POSITION_ATTEMPTS):
			var angle := rng.randf_range(0.0, TAU)
			var distance := sqrt(rng.randf()) * spread
			candidate = Vector2(cos(angle), sin(angle)) * distance
			if _is_cross_position_valid(candidate, positions, minimum_distance):
				break
		# The last candidate is still deterministic and remains inside the disk.
		positions.append(candidate)

	return positions


func _is_cross_position_valid(
	candidate: Vector2,
	positions: Array[Vector2],
	minimum_distance: float
) -> bool:
	for existing in positions:
		if candidate.distance_to(existing) < minimum_distance:
			return false
	return true


func _refresh_line_variants() -> void:
	if _generated_line_nodes.is_empty():
		return

	var colored_count := _generated_line_nodes.size() - 1
	var cross_offsets := _generate_cross_offsets(colored_count)
	var kinds := _shuffled_color_kinds()
	var rng := RandomNumberGenerator.new()
	rng.seed = line_seed
	var cyan_index := 0
	var navy_index := 0

	for index in range(colored_count):
		var kind := kinds[index]
		_generated_line_kinds[index] = kind
		var line := _generated_line_nodes[index]
		if kind == LINE_KIND_CYAN:
			cyan_index += 1
			line.name = "CyanLine%02d" % cyan_index
		else:
			navy_index += 1
			line.name = "NavyLine%02d" % navy_index
		var variation_factor := 1.0 + rng.randf_range(-line_variation, line_variation)
		var phase := rng.randf()
		var wave_angle := rng.randf_range(0.0, TAU)
		var wave_direction := Vector2(cos(wave_angle), sin(wave_angle))
		var noise_offset := Vector2(
			rng.randf_range(-40.0, 40.0),
			rng.randf_range(-40.0, 40.0)
		)

		var color := cyan_color if kind == LINE_KIND_CYAN else navy_color
		var intensity := cyan_intensity if kind == LINE_KIND_CYAN else navy_intensity
		var base_width := cyan_width if kind == LINE_KIND_CYAN else navy_width
		var base_amplitude := cyan_line_wave_amplitude if kind == LINE_KIND_CYAN else navy_line_wave_amplitude
		line.set_instance_shader_parameter(&"line_color", color)
		line.set_instance_shader_parameter(&"line_intensity", intensity)
		line.set_instance_shader_parameter(&"line_kind", float(kind))
		line.set_instance_shader_parameter(&"line_width", base_width * variation_factor)
		line.set_instance_shader_parameter(&"line_cross_offset", cross_offsets[index])
		line.set_instance_shader_parameter(&"line_wave_amplitude", base_amplitude * variation_factor)
		line.set_instance_shader_parameter(&"line_wave_phase", phase)
		line.set_instance_shader_parameter(&"line_wave_direction", wave_direction)
		line.set_instance_shader_parameter(&"line_noise_offset", noise_offset)

	var white_line: MeshInstance3D = _generated_line_nodes.back()
	var white_rng_phase := rng.randf()
	var white_wave_angle := rng.randf_range(0.0, TAU)
	var white_wave_direction := Vector2(cos(white_wave_angle), sin(white_wave_angle))
	var white_noise_offset := Vector2(
		rng.randf_range(-40.0, 40.0),
		rng.randf_range(-40.0, 40.0)
	)
	white_line.set_instance_shader_parameter(&"line_color", white_color)
	white_line.set_instance_shader_parameter(&"line_intensity", white_intensity)
	white_line.set_instance_shader_parameter(&"line_kind", float(LINE_KIND_WHITE))
	white_line.set_instance_shader_parameter(&"line_width", white_width)
	white_line.set_instance_shader_parameter(&"line_cross_offset", Vector2(white_offset, 0.0))
	white_line.set_instance_shader_parameter(&"line_wave_amplitude", white_line_wave_amplitude)
	white_line.set_instance_shader_parameter(&"line_wave_phase", white_rng_phase)
	white_line.set_instance_shader_parameter(&"line_wave_direction", white_wave_direction)
	white_line.set_instance_shader_parameter(&"line_noise_offset", white_noise_offset)


func _update_custom_aabbs() -> void:
	if _shared_mesh == null:
		return

	var bounds := _make_custom_aabb(_shared_mesh)
	for line in _generated_line_nodes:
		line.custom_aabb = bounds


func _make_custom_aabb(ribbon_mesh: ArrayMesh) -> AABB:
	var bounds := ribbon_mesh.get_aabb()
	var largest_amplitude := maxf(
		maxf(cyan_line_wave_amplitude, navy_line_wave_amplitude),
		white_line_wave_amplitude
	)
	var largest_width := maxf(maxf(cyan_width, navy_width), white_width)
	var largest_offset := maxf(line_spread_radius, absf(white_offset))
	var margin := absf(stream_wave_amplitude) + largest_offset + largest_amplitude + largest_width
	bounds.position -= Vector3.ONE * margin
	bounds.size += Vector3.ONE * margin * 2.0
	return bounds


func _sync_shared_material() -> void:
	if not is_inside_tree():
		return

	_ensure_shared_material()
	_shared_material.set_shader_parameter(&"stream_wave_amplitude", stream_wave_amplitude)
	_shared_material.set_shader_parameter(&"stream_wave_cycles", stream_wave_cycles)
	_shared_material.set_shader_parameter(&"stream_wave_speed", stream_wave_speed)
	_shared_material.set_shader_parameter(&"stream_wave_outer_scale", stream_wave_outer_scale)
	_shared_material.set_shader_parameter(&"stream_wave_peak_position", stream_wave_peak_position)
	_shared_material.set_shader_parameter(&"stream_wave_inner_scale", stream_wave_inner_scale)
	_shared_material.set_shader_parameter(&"line_wave_cycles", line_wave_cycles)
	_shared_material.set_shader_parameter(&"line_wave_speed", line_wave_speed)
	_shared_material.set_shader_parameter(&"line_wave_noise_amount", line_wave_noise_amount)
	_shared_material.set_shader_parameter(&"line_wave_inner_amplitude", line_wave_inner_amplitude)
	_shared_material.set_shader_parameter(&"edge_softness", edge_softness)
	_shared_material.set_shader_parameter(&"edge_erosion_strength", edge_erosion_strength)
	_shared_material.set_shader_parameter(&"body_variation_strength", body_variation_strength)
	_shared_material.set_shader_parameter(&"inner_offset_scale", inner_offset_scale)
	_shared_material.set_shader_parameter(&"outer_fade_length", outer_fade_length)
	_shared_material.set_shader_parameter(&"inner_taper_length", inner_taper_length)
	_shared_material.set_shader_parameter(&"inner_taper_power", inner_taper_power)
	_shared_material.set_shader_parameter(&"inner_fade_length", inner_fade_length)
	_shared_material.set_shader_parameter(&"inner_erosion_strength", inner_erosion_strength)
	_shared_material.set_shader_parameter(&"radius_scale", _radius_scale())
	_shared_material.set_shader_parameter(&"white_segment_length", white_segment_length)
	_shared_material.set_shader_parameter(&"white_segments", _white_segment_values())

	for line in _generated_line_nodes:
		line.material_override = _shared_material


func _reset_white_segments() -> void:
	_white_segments.clear()
	for _index in range(WHITE_SEGMENT_CAPACITY):
		_white_segments.append(Vector4(-1.0, 0.0, 0.0, 0.0))


func _apply_white_preview() -> void:
	_reset_white_segments()
	var preview_start := clampf(
		white_preview_position - white_segment_length * 0.5,
		0.0,
		1.0 - white_segment_length
	)
	_white_segments[0] = Vector4(preview_start, 1.0, 0.0, 0.0)


func _update_white_segments(delta: float) -> void:
	var active_count_before := _active_white_segment_count()
	for index in range(WHITE_SEGMENT_CAPACITY):
		var segment := _white_segments[index]
		if segment.y <= 0.5:
			continue

		segment.x += white_speed * delta
		if segment.x > 1.0:
			segment = Vector4(-1.0, 0.0, 0.0, 0.0)
		_white_segments[index] = segment

	var active_count_after := _active_white_segment_count()
	if active_count_before >= white_max_segments and active_count_after < white_max_segments:
		_white_spawn_cooldown = _random_interval()
	elif active_count_after >= white_max_segments:
		_white_spawn_cooldown = maxf(_white_spawn_cooldown, 0.0)
	else:
		_white_spawn_cooldown -= delta
		if _white_spawn_cooldown <= 0.0:
			_spawn_white_segment()
			_white_spawn_cooldown = _random_interval()

	_sync_white_segments()


func _active_white_segment_count() -> int:
	var count := 0
	for segment in _white_segments:
		if segment.y > 0.5:
			count += 1
	return count


func _spawn_white_segment() -> void:
	for index in range(WHITE_SEGMENT_CAPACITY):
		if _white_segments[index].y <= 0.5:
			_white_segments[index] = Vector4(0.0, 1.0, 0.0, 0.0)
			return


func _random_interval() -> float:
	var interval_low := minf(white_interval_min, white_interval_max)
	var interval_high := maxf(white_interval_min, white_interval_max)
	return _random.randf_range(interval_low, interval_high)


func _white_segment_values() -> PackedVector4Array:
	var values := PackedVector4Array()
	for index in range(WHITE_SEGMENT_CAPACITY):
		values.append(_white_segments[index])
	return values


func _sync_white_segments() -> void:
	if _shared_material == null:
		return
	_shared_material.set_shader_parameter(&"white_segments", _white_segment_values())
