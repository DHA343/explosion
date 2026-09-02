@tool
class_name FilamentSplatBatch3D
extends MeshInstance3D

const TARGET_SPACING_RATIO := 0.3
const MIN_SPLAT_COUNT := 12
const MAX_SPLAT_COUNT := 64
const PATH_LENGTH_SAMPLES := 10
const GROWTH_FEATHER := 0.06


func rebuild(
	events: Array[ShellContactEvent],
	camera_position: Vector3,
	camera_right: Vector3,
	camera_up: Vector3,
	radius: float
) -> void:
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var view_direction := camera_position.normalized()
	if view_direction.is_zero_approx():
		view_direction = Vector3.BACK
		camera_position = view_direction * radius * 3.0

	for event in events:
		if not event.is_active or event.filament_visibility() <= 0.001:
			continue
		_append_splat_chain(
			event,
			camera_position,
			camera_right,
			camera_up,
			view_direction,
			radius,
			vertices,
			colors,
			uvs,
			indices
		)

	var array_mesh := ArrayMesh.new()
	if not vertices.is_empty():
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_COLOR] = colors
		arrays[Mesh.ARRAY_TEX_UV] = uvs
		arrays[Mesh.ARRAY_INDEX] = indices
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = array_mesh


func get_splat_count(event: ShellContactEvent, radius: float) -> int:
	var path_length := _estimate_path_length(event, radius)
	var target_spacing := event.body_width * TARGET_SPACING_RATIO
	return clampi(ceili(path_length / target_spacing) + 1, MIN_SPLAT_COUNT, MAX_SPLAT_COUNT)


func _append_splat_chain(
	event: ShellContactEvent,
	camera_position: Vector3,
	camera_right: Vector3,
	camera_up: Vector3,
	view_direction: Vector3,
	radius: float,
	vertices: PackedVector3Array,
	colors: PackedColorArray,
	uvs: PackedVector2Array,
	indices: PackedInt32Array
) -> void:
	var growth_front := event.growth_progress()
	var filament_visibility := event.filament_visibility()
	var hemisphere_brightness := _hemisphere_brightness(event.direction, view_direction)
	var splat_count := get_splat_count(event, radius)

	for index in range(splat_count):
		var t := float(index) / float(splat_count - 1)
		var growth_visibility := 1.0 - smoothstep(
			growth_front,
			growth_front + GROWTH_FEATHER,
			t
		)
		if growth_visibility <= 0.001:
			continue

		var center := _center_position(event, t, radius)
		var point_view_direction := (camera_position - center).normalized()
		var splat_right := camera_right \
			- point_view_direction * camera_right.dot(point_view_direction)
		if splat_right.length_squared() < 0.000001:
			splat_right = camera_up.cross(point_view_direction)
		splat_right = splat_right.normalized()
		var splat_up := point_view_direction.cross(splat_right).normalized()
		var diameter := event.body_width * _width_profile(t)
		diameter *= _instability_width(event, t)
		diameter *= _neck_width(event, t)
		diameter *= lerpf(0.35, 1.0, growth_visibility)
		var half_size := diameter * 0.5
		var base_vertex := vertices.size()
		var splat_color := Color(
			event.brightness * hemisphere_brightness,
			event.hot_core_width / event.body_width,
			fmod(event.random_seed + t * 0.37, 1.0),
			filament_visibility * growth_visibility
		)

		vertices.append(center - splat_right * half_size - splat_up * half_size)
		vertices.append(center + splat_right * half_size - splat_up * half_size)
		vertices.append(center + splat_right * half_size + splat_up * half_size)
		vertices.append(center - splat_right * half_size + splat_up * half_size)
		for vertex_index in range(4):
			colors.append(splat_color)
		uvs.append(Vector2(0.0, 0.0))
		uvs.append(Vector2(1.0, 0.0))
		uvs.append(Vector2(1.0, 1.0))
		uvs.append(Vector2(0.0, 1.0))
		indices.append(base_vertex)
		indices.append(base_vertex + 1)
		indices.append(base_vertex + 2)
		indices.append(base_vertex)
		indices.append(base_vertex + 2)
		indices.append(base_vertex + 3)


func _estimate_path_length(event: ShellContactEvent, radius: float) -> float:
	var path_length := 0.0
	var previous_position := _center_position(event, 0.0, radius)
	for index in range(1, PATH_LENGTH_SAMPLES + 1):
		var t := float(index) / float(PATH_LENGTH_SAMPLES)
		var position := _center_position(event, t, radius)
		path_length += previous_position.distance_to(position)
		previous_position = position
	return path_length


func _center_position(event: ShellContactEvent, t: float, radius: float) -> Vector3:
	var center := event.start_position.lerp(event.end_position, t)
	center += event.bend_offset * sin(t * PI)
	var flutter_axis := event.direction.cross(event.bend_offset.normalized())
	if not flutter_axis.is_zero_approx():
		var flutter := sin(t * PI * 2.0 + event.random_seed * TAU)
		flutter *= sin(t * PI) * radius * 0.008
		center += flutter_axis.normalized() * flutter
	return center


func _width_profile(t: float) -> float:
	var source_lobe := exp(-pow((t - 0.12) / 0.2, 2.0)) * 0.38
	var middle_neck := exp(-pow((t - 0.53) / 0.22, 2.0)) * 0.24
	var tip_lobe := smoothstep(0.72, 1.0, t) * 0.22
	return 1.0 + source_lobe - middle_neck + tip_lobe


func _instability_width(event: ShellContactEvent, t: float) -> float:
	var time := event.elapsed * 37.0
	var wave := sin(t * 31.0 + event.random_seed * 41.0 + time)
	var breakup := event.detach_progress() * sin(t * 67.0 + event.random_seed * 19.0)
	return maxf(0.72, 1.0 + wave * 0.07 + breakup * 0.08)


func _neck_width(event: ShellContactEvent, t: float) -> float:
	var neck_region := smoothstep(0.7, 0.98, t)
	var neck_target := lerpf(1.0, 0.2, event.detach_progress())
	return lerpf(1.0, neck_target, neck_region)


func _hemisphere_brightness(direction: Vector3, view_direction: Vector3) -> float:
	var facing := direction.dot(view_direction)
	if facing >= 0.0:
		return lerpf(0.84, 1.0, facing)
	return lerpf(0.48, 0.84, facing + 1.0)
