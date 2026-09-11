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

@export_group("Curve")

@export_range(0.02, 0.10, 0.005) var mesh_sample_interval: float = 0.04:
	set(value):
		mesh_sample_interval = clampf(value, 0.02, 0.10)
		_request_mesh_rebuild()

@export_group("Stream Wave")

@export_range(0.0, 0.60, 0.01, "suffix:m") var stream_wave_amplitude: float = 0.20:
	set(value):
		stream_wave_amplitude = clampf(value, 0.0, 0.60)
		_request_parameter_sync()

@export_range(0.5, 3.0, 0.05) var stream_wave_cycles: float = 1.5:
	set(value):
		stream_wave_cycles = clampf(value, 0.5, 3.0)
		_request_parameter_sync()

@export_range(0.0, 2.0, 0.05, "suffix:/s") var stream_wave_speed: float = 0.50:
	set(value):
		stream_wave_speed = clampf(value, 0.0, 2.0)
		_request_parameter_sync()

@export_range(0.0, 1.0, 0.05) var stream_wave_outer_scale: float = 0.60:
	set(value):
		stream_wave_outer_scale = clampf(value, 0.0, 1.0)
		_request_parameter_sync()

@export_range(0.20, 0.70, 0.01) var stream_wave_peak_position: float = 0.45:
	set(value):
		stream_wave_peak_position = clampf(value, 0.20, 0.70)
		_request_parameter_sync()

@export_range(0.0, 0.50, 0.05) var stream_wave_inner_scale: float = 0.10:
	set(value):
		stream_wave_inner_scale = clampf(value, 0.0, 0.50)
		_request_parameter_sync()

@export_group("Line Wave")

@export_range(1.0, 5.0, 0.10) var line_wave_cycles: float = 2.5:
	set(value):
		line_wave_cycles = clampf(value, 1.0, 5.0)
		_request_parameter_sync()

@export_range(0.0, 3.0, 0.05, "suffix:/s") var line_wave_speed: float = 0.80:
	set(value):
		line_wave_speed = clampf(value, 0.0, 3.0)
		_request_parameter_sync()

@export_range(0.0, 0.50, 0.05) var line_wave_noise_amount: float = 0.20:
	set(value):
		line_wave_noise_amount = clampf(value, 0.0, 0.50)
		_request_parameter_sync()

@export_group("Offset")

@export_range(0.25, 1.0, 0.05) var inner_offset_scale: float = 0.50:
	set(value):
		inner_offset_scale = clampf(value, 0.25, 1.0)
		_request_parameter_sync()

@export_group("Appearance")

@export var cyan_color: Color = Color(0.08, 0.72, 1.0, 1.0):
	set(value):
		cyan_color = value
		_request_parameter_sync()

@export_range(0.5, 4.0, 0.1) var cyan_intensity: float = 2.0:
	set(value):
		cyan_intensity = clampf(value, 0.5, 4.0)
		_request_parameter_sync()

@export var navy_color: Color = Color(0.015, 0.12, 0.36, 1.0):
	set(value):
		navy_color = value
		_request_parameter_sync()

@export_range(0.5, 3.0, 0.1) var navy_intensity: float = 1.2:
	set(value):
		navy_intensity = clampf(value, 0.5, 3.0)
		_request_parameter_sync()

@export var white_color: Color = Color(0.88, 0.98, 1.0, 1.0):
	set(value):
		white_color = value
		_request_parameter_sync()

@export_range(1.0, 5.0, 0.1) var white_intensity: float = 3.0:
	set(value):
		white_intensity = clampf(value, 1.0, 5.0)
		_request_parameter_sync()

@export_group("White Line")

@export_range(0.05, 0.25, 0.01) var white_segment_length: float = 0.12:
	set(value):
		white_segment_length = clampf(value, 0.05, 0.25)
		_request_parameter_sync()

@export_range(0.50, 3.0, 0.05, "suffix:/s") var white_speed: float = 1.50:
	set(value):
		white_speed = clampf(value, 0.50, 3.0)
		_request_parameter_sync()

@export_range(0.20, 2.0, 0.05, "suffix:s") var white_interval_min: float = 0.40:
	set(value):
		white_interval_min = clampf(value, 0.20, 2.0)
		white_interval_max = maxf(white_interval_max, white_interval_min)
		_request_parameter_sync()

@export_range(0.40, 3.0, 0.05, "suffix:s") var white_interval_max: float = 1.20:
	set(value):
		white_interval_max = clampf(value, 0.40, 3.0)
		white_interval_max = maxf(white_interval_max, white_interval_min)
		_request_parameter_sync()

@export_range(1, 3, 1) var white_max_segments: int = 2:
	set(value):
		white_max_segments = clampi(value, 1, WHITE_SEGMENT_CAPACITY)
		_request_parameter_sync()

@export_group("Ends")

@export_range(0.02, 0.20, 0.01) var outer_fade_length: float = 0.08:
	set(value):
		outer_fade_length = clampf(value, 0.02, 0.20)
		_request_parameter_sync()

@export_range(0.05, 0.35, 0.01) var inner_taper_length: float = 0.18:
	set(value):
		inner_taper_length = clampf(value, 0.05, 0.35)
		_request_parameter_sync()

@export_range(1.0, 4.0, 0.1) var inner_taper_power: float = 1.8:
	set(value):
		inner_taper_power = clampf(value, 1.0, 4.0)
		_request_parameter_sync()

@export_range(0.03, 0.25, 0.01) var inner_fade_length: float = 0.12:
	set(value):
		inner_fade_length = clampf(value, 0.03, 0.25)
		_request_parameter_sync()

@export_range(0.0, 0.60, 0.05) var inner_erosion_strength: float = 0.25:
	set(value):
		inner_erosion_strength = clampf(value, 0.0, 0.60)
		_request_parameter_sync()

var radius: float = BASE_RADIUS:
	set(value):
		radius = maxf(value, 0.001)
		if is_node_ready():
			_sync_radius()

var _connected_curve: Curve3D
var _mesh_rebuild_pending: bool = false
var _elements: Array[MeshInstance3D] = []
var _white_segments: Array[Vector4] = []
var _white_spawn_cooldown: float = 0.0
var _random := RandomNumberGenerator.new()

@onready var _guide_path: Path3D = $GuidePath


func _ready() -> void:
	scale = Vector3.ONE * _radius_scale()
	_collect_elements()
	_reset_white_segments()
	_connect_curve()
	_rebuild_meshes()
	_sync_all_materials()

	if not Engine.is_editor_hint():
		_random.randomize()
		_white_spawn_cooldown = _random_interval()


func _exit_tree() -> void:
	_disconnect_curve()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	_update_white_segments(delta)


func refresh_element(element: MeshInstance3D) -> void:
	if not is_inside_tree():
		return
	if not _elements.has(element):
		_collect_elements()
	_sync_material(element)
	_update_custom_aabbs()


func _sync_radius() -> void:
	scale = Vector3.ONE * _radius_scale()
	_sync_all_materials()
	_update_custom_aabbs()
	_request_mesh_rebuild()


func _radius_scale() -> float:
	return radius / BASE_RADIUS


func _request_mesh_rebuild() -> void:
	if not is_inside_tree():
		return
	if _mesh_rebuild_pending:
		return

	_mesh_rebuild_pending = true
	call_deferred("_rebuild_meshes")


func _request_parameter_sync() -> void:
	if is_inside_tree():
		_sync_all_materials()
		_update_custom_aabbs()


func _collect_elements() -> void:
	_elements.clear()
	for child in get_children():
		var element := child as MeshInstance3D
		if element != null:
			_elements.append(element)


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


func _rebuild_meshes() -> void:
	_mesh_rebuild_pending = false
	if not is_inside_tree():
		return

	_connect_curve()
	var ribbon_mesh := _build_ribbon_mesh()
	for element in _elements:
		element.mesh = ribbon_mesh
		element.visible = ribbon_mesh != null
	_update_custom_aabbs()


func _update_custom_aabbs() -> void:
	for element in _elements:
		var ribbon_mesh := element.mesh as ArrayMesh
		if ribbon_mesh != null:
			element.custom_aabb = _make_custom_aabb(ribbon_mesh)


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
	var sample_count := maxi(2, ceili(scaled_curve_length / mesh_sample_interval) + 1)
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	for sample_index in sample_count:
		var progress := float(sample_index) / float(sample_count - 1)
		var distance := curve_length * progress
		var position := curve.sample_baked(distance, true)
		var tangent_step := maxf(curve_length / float(sample_count - 1) * 0.5, 0.001)
		var previous := curve.sample_baked(maxf(distance - tangent_step, 0.0), true)
		var next := curve.sample_baked(minf(distance + tangent_step, curve_length), true)
		var tangent := next - previous
		if tangent.length_squared() <= 0.000001:
			tangent = Vector3.FORWARD
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


func _make_custom_aabb(ribbon_mesh: ArrayMesh) -> AABB:
	var bounds := ribbon_mesh.get_aabb()
	var largest_line_amplitude := 0.0
	var largest_width := 0.0
	var largest_offset := 0.0
	for element in _elements:
		largest_line_amplitude = maxf(largest_line_amplitude, element.get("line_wave_amplitude"))
		largest_width = maxf(largest_width, element.get("width"))
		largest_offset = maxf(largest_offset, absf(element.get("offset")))

	var margin := stream_wave_amplitude + largest_offset + largest_line_amplitude + largest_width
	bounds.position -= Vector3.ONE * margin
	bounds.size += Vector3.ONE * margin * 2.0
	return bounds


func _sync_all_materials() -> void:
	for element in _elements:
		_sync_material(element)


func _sync_material(element: MeshInstance3D) -> void:
	if element == null:
		return

	var material := element.material_override as ShaderMaterial
	if material == null or material.shader != STREAM_SHADER:
		material = ShaderMaterial.new()
		material.shader = STREAM_SHADER
		material.resource_local_to_scene = true
		element.material_override = material

	var line_kind: int = element.get("line_kind")
	var line_color := cyan_color
	var line_intensity := cyan_intensity
	if line_kind == LINE_KIND_NAVY:
		line_color = navy_color
		line_intensity = navy_intensity
	elif line_kind == LINE_KIND_WHITE:
		line_color = white_color
		line_intensity = white_intensity

	material.set_shader_parameter(&"line_color", line_color)
	material.set_shader_parameter(&"line_intensity", line_intensity)
	material.set_shader_parameter(&"line_kind", float(line_kind))
	material.set_shader_parameter(&"line_width", element.get("width"))
	material.set_shader_parameter(&"line_offset", element.get("offset"))
	material.set_shader_parameter(&"line_wave_amplitude", element.get("line_wave_amplitude"))
	material.set_shader_parameter(&"line_wave_phase", element.get("line_wave_phase"))
	material.set_shader_parameter(&"line_noise_offset", _noise_offset_for(element))
	material.set_shader_parameter(&"stream_wave_amplitude", stream_wave_amplitude)
	material.set_shader_parameter(&"stream_wave_cycles", stream_wave_cycles)
	material.set_shader_parameter(&"stream_wave_speed", stream_wave_speed)
	material.set_shader_parameter(&"stream_wave_outer_scale", stream_wave_outer_scale)
	material.set_shader_parameter(&"stream_wave_peak_position", stream_wave_peak_position)
	material.set_shader_parameter(&"stream_wave_inner_scale", stream_wave_inner_scale)
	material.set_shader_parameter(&"line_wave_cycles", line_wave_cycles)
	material.set_shader_parameter(&"line_wave_speed", line_wave_speed)
	material.set_shader_parameter(&"line_wave_noise_amount", line_wave_noise_amount)
	material.set_shader_parameter(&"inner_offset_scale", inner_offset_scale)
	material.set_shader_parameter(&"outer_fade_length", outer_fade_length)
	material.set_shader_parameter(&"inner_taper_length", inner_taper_length)
	material.set_shader_parameter(&"inner_taper_power", inner_taper_power)
	material.set_shader_parameter(&"inner_fade_length", inner_fade_length)
	material.set_shader_parameter(&"inner_erosion_strength", inner_erosion_strength)
	material.set_shader_parameter(&"radius_scale", _radius_scale())
	material.set_shader_parameter(&"white_segment_length", white_segment_length)
	material.set_shader_parameter(&"white_segments", _white_segment_values())


func _noise_offset_for(element: MeshInstance3D) -> Vector2:
	var element_index := _elements.find(element)
	var value := float(element_index + 1)
	return Vector2(value * 4.73, value * 8.19 + 1.7)


func _reset_white_segments() -> void:
	_white_segments.clear()
	for _index in WHITE_SEGMENT_CAPACITY:
		_white_segments.append(Vector4(-1.0, 0.0, 0.0, 0.0))


func _update_white_segments(delta: float) -> void:
	var active_count_before := _active_white_segment_count()
	for index in WHITE_SEGMENT_CAPACITY:
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

	_sync_white_materials()


func _active_white_segment_count() -> int:
	var count := 0
	for segment in _white_segments:
		if segment.y > 0.5:
			count += 1
	return count


func _spawn_white_segment() -> void:
	for index in WHITE_SEGMENT_CAPACITY:
		if _white_segments[index].y <= 0.5:
			_white_segments[index] = Vector4(0.0, 1.0, white_segment_length, 0.0)
			return


func _random_interval() -> float:
	return _random.randf_range(white_interval_min, maxf(white_interval_min, white_interval_max))


func _white_segment_values() -> PackedVector4Array:
	var values := PackedVector4Array()
	for index in WHITE_SEGMENT_CAPACITY:
		values.append(_white_segments[index])
	return values


func _sync_white_materials() -> void:
	for element in _elements:
		if element.get("line_kind") == LINE_KIND_WHITE:
			_sync_material(element)
