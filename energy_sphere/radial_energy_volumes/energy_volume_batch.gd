@tool
class_name EnergyVolumeBatch
extends MeshInstance3D

const RADIAL_SEGMENTS := 16
const CAP_RINGS := 5
const THIN_DIAMETER_RATIO := 0.06
const MEDIUM_DIAMETER_RATIO := 0.11
const THICK_DIAMETER_RATIO := 0.17


func rebuild(events: Array[EnergyVolumeEvent], sphere_radius: float) -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	for event in events:
		if event.current_length <= 0.0001 or event.visibility() <= 0.001:
			continue
		_append_volume(event, sphere_radius, vertices, normals, colors, uvs, indices)

	var array_mesh := ArrayMesh.new()
	if not vertices.is_empty():
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_COLOR] = colors
		arrays[Mesh.ARRAY_TEX_UV] = uvs
		arrays[Mesh.ARRAY_INDEX] = indices
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = array_mesh


func _append_volume(
	event: EnergyVolumeEvent,
	sphere_radius: float,
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	colors: PackedColorArray,
	uvs: PackedVector2Array,
	indices: PackedInt32Array
) -> void:
	var direction := event.direction.normalized()
	var length := event.current_length
	var diameter := sphere_radius * _diameter_ratio(event.diameter_class)
	var capsule_radius := minf(diameter * 0.5, length * 0.5)
	var body_half_length := maxf(0.0, length * 0.5 - capsule_radius)
	var center := event.start_position + direction * length * 0.5
	var frame := _basis_for_direction(direction)
	var ring_radii := PackedFloat32Array()
	var ring_heights := PackedFloat32Array()
	var ring_normal_radii := PackedFloat32Array()
	var ring_normal_heights := PackedFloat32Array()

	for ring_index in range(CAP_RINGS + 1):
		var angle := lerpf(-PI * 0.5, 0.0, float(ring_index) / float(CAP_RINGS))
		ring_radii.append(cos(angle) * capsule_radius)
		ring_heights.append(-body_half_length + sin(angle) * capsule_radius)
		ring_normal_radii.append(cos(angle))
		ring_normal_heights.append(sin(angle))
	if body_half_length > 0.0001:
		ring_radii.append(capsule_radius)
		ring_heights.append(body_half_length)
		ring_normal_radii.append(1.0)
		ring_normal_heights.append(0.0)
	for ring_index in range(1, CAP_RINGS + 1):
		var angle := lerpf(0.0, PI * 0.5, float(ring_index) / float(CAP_RINGS))
		ring_radii.append(cos(angle) * capsule_radius)
		ring_heights.append(body_half_length + sin(angle) * capsule_radius)
		ring_normal_radii.append(cos(angle))
		ring_normal_heights.append(sin(angle))

	var base_vertex := vertices.size()
	var event_color := Color(event.brightness, event.visibility(), event.seed, 1.0)
	for ring_index in range(ring_radii.size()):
		var height: float = ring_heights[ring_index]
		var uv_y := clampf((height + length * 0.5) / length, 0.0, 1.0)
		for segment_index in range(RADIAL_SEGMENTS + 1):
			var angle := TAU * float(segment_index) / float(RADIAL_SEGMENTS)
			var radial_direction := Vector3(cos(angle), 0.0, sin(angle))
			var local_position := radial_direction * ring_radii[ring_index]
			local_position.y = height
			var local_normal := radial_direction * ring_normal_radii[ring_index]
			local_normal.y = ring_normal_heights[ring_index]

			vertices.append(center + frame * local_position)
			normals.append((frame * local_normal).normalized())
			colors.append(event_color)
			uvs.append(Vector2(float(segment_index) / float(RADIAL_SEGMENTS), uv_y))

	var ring_stride := RADIAL_SEGMENTS + 1
	for ring_index in range(ring_radii.size() - 1):
		for segment_index in range(RADIAL_SEGMENTS):
			var lower_left := base_vertex + ring_index * ring_stride + segment_index
			var lower_right := lower_left + 1
			var upper_left := lower_left + ring_stride
			var upper_right := upper_left + 1
			indices.append(lower_left)
			indices.append(upper_left)
			indices.append(lower_right)
			indices.append(lower_right)
			indices.append(upper_left)
			indices.append(upper_right)


func _diameter_ratio(diameter_class: EnergyVolumeEvent.DiameterClass) -> float:
	match diameter_class:
		EnergyVolumeEvent.DiameterClass.THIN:
			return THIN_DIAMETER_RATIO
		EnergyVolumeEvent.DiameterClass.THICK:
			return THICK_DIAMETER_RATIO
		_:
			return MEDIUM_DIAMETER_RATIO


func _basis_for_direction(direction: Vector3) -> Basis:
	var reference := Vector3.FORWARD
	if absf(direction.dot(reference)) > 0.95:
		reference = Vector3.RIGHT
	var axis_x := reference.cross(direction).normalized()
	var axis_z := axis_x.cross(direction).normalized()
	return Basis(axis_x, direction, axis_z)
