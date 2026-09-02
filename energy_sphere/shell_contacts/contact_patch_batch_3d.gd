@tool
class_name ContactPatchBatch3D
extends MeshInstance3D

const PATCH_SEGMENTS := 10


func rebuild(events: Array[ShellContactEvent], camera_position: Vector3, inner_radius: float) -> void:
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var view_direction := camera_position.normalized()
	if view_direction.is_zero_approx():
		view_direction = Vector3.BACK

	for event in events:
		if not event.is_active or event.contact_visibility() <= 0.001:
			continue
		_append_patch(event, view_direction, inner_radius, vertices, colors, uvs, indices)

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


func _append_patch(
	event: ShellContactEvent,
	view_direction: Vector3,
	inner_radius: float,
	vertices: PackedVector3Array,
	colors: PackedColorArray,
	uvs: PackedVector2Array,
	indices: PackedInt32Array
) -> void:
	var normal := event.direction.normalized()
	var tangent_x := event.bend_offset - normal * event.bend_offset.dot(normal)
	if tangent_x.is_zero_approx():
		tangent_x = normal.cross(view_direction)
	if tangent_x.is_zero_approx():
		tangent_x = normal.cross(Vector3.UP)
	if tangent_x.is_zero_approx():
		tangent_x = normal.cross(Vector3.RIGHT)
	tangent_x = tangent_x.normalized()
	var tangent_y := normal.cross(tangent_x).normalized()
	var tangent_extent := event.body_width * 0.72 * event.contact_scale
	var radial_extent := event.body_width * 0.22 * event.contact_scale
	var base_vertex := vertices.size()
	var hemisphere_brightness := _hemisphere_brightness(normal, view_direction)
	var patch_color := Color(
		event.brightness * hemisphere_brightness,
		0.16 + event.random_seed * 0.12,
		event.random_seed,
		event.contact_visibility()
	)

	vertices.append(normal * inner_radius)
	colors.append(patch_color)
	uvs.append(Vector2(0.5, 0.5))
	for index in range(PATCH_SEGMENTS):
		var angle := TAU * float(index) / float(PATCH_SEGMENTS)
		var offset := tangent_x * cos(angle) * tangent_extent
		offset += tangent_y * sin(angle) * radial_extent
		var curved_position := (normal * inner_radius + offset).normalized() * inner_radius
		vertices.append(curved_position)
		colors.append(patch_color)
		uvs.append(Vector2(cos(angle), sin(angle)) * 0.5 + Vector2.ONE * 0.5)

	for index in range(PATCH_SEGMENTS):
		indices.append(base_vertex)
		indices.append(base_vertex + 1 + index)
		indices.append(base_vertex + 1 + (index + 1) % PATCH_SEGMENTS)


func _hemisphere_brightness(direction: Vector3, view_direction: Vector3) -> float:
	var facing := direction.dot(view_direction)
	if facing >= 0.0:
		return lerpf(0.84, 1.0, facing)
	return lerpf(0.42, 0.84, facing + 1.0)
