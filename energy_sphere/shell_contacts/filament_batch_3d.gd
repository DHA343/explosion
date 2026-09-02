@tool
class_name FilamentBatch3D
extends MeshInstance3D

@export_range(8, 12, 1) var segment_count: int = 10


func rebuild(events: Array[ShellContactEvent], camera_position: Vector3, radius: float) -> void:
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
		_append_filament(
			event,
			camera_position,
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


func _append_filament(
	event: ShellContactEvent,
	camera_position: Vector3,
	view_direction: Vector3,
	radius: float,
	vertices: PackedVector3Array,
	colors: PackedColorArray,
	uvs: PackedVector2Array,
	indices: PackedInt32Array
) -> void:
	var growth := event.growth_progress()
	if growth <= 0.01:
		return

	var visible_segments := maxi(1, ceili(float(segment_count) * growth))
	var base_vertex := vertices.size()
	var visibility := event.filament_visibility()
	var hemisphere_brightness := _hemisphere_brightness(event.direction, view_direction)
	var event_color := Color(
		event.brightness * hemisphere_brightness,
		event.hot_core_width / event.body_width,
		event.random_seed,
		visibility
	)

	for index in range(visible_segments + 1):
		var t := minf(float(index) / float(segment_count), growth)
		var previous_t := maxf(0.0, t - 0.01)
		var next_t := minf(growth, t + 0.01)
		var center := _center_position(event, t, radius)
		var tangent := _center_position(event, next_t, radius) \
			- _center_position(event, previous_t, radius)
		if tangent.is_zero_approx():
			tangent = event.direction
		tangent = tangent.normalized()

		var point_view_direction := (camera_position - center).normalized()
		var width_axis := tangent.cross(point_view_direction)
		if width_axis.length_squared() < 0.000001:
			width_axis = tangent.cross(Vector3.UP)
		if width_axis.length_squared() < 0.000001:
			width_axis = tangent.cross(Vector3.RIGHT)
		width_axis = width_axis.normalized()

		var width := event.body_width * _width_profile(t)
		width *= _instability_width(event, t)
		width *= _neck_width(event, t)
		var half_width := width * 0.5
		vertices.append(center - width_axis * half_width)
		vertices.append(center + width_axis * half_width)
		colors.append(event_color)
		colors.append(event_color)
		var visible_t := float(index) / float(visible_segments)
		uvs.append(Vector2(visible_t, 0.0))
		uvs.append(Vector2(visible_t, 1.0))

	for index in range(visible_segments):
		var first := base_vertex + index * 2
		indices.append(first)
		indices.append(first + 1)
		indices.append(first + 2)
		indices.append(first + 1)
		indices.append(first + 3)
		indices.append(first + 2)


func _center_position(event: ShellContactEvent, t: float, radius: float) -> Vector3:
	var center := event.start_position.lerp(event.contact_position, t)
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
