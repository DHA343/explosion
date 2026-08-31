extends Node3D

@export_range(1, 32, 1) var patch_count: int = 12

@onready var _patch_instances: MultiMeshInstance3D = $PatchInstances


func _ready() -> void:
	_populate_patches()


func _populate_patches() -> void:
	var multimesh := _patch_instances.multimesh
	assert(multimesh != null, "PatchInstances requires a MultiMesh.")
	multimesh.instance_count = patch_count

	for index in range(patch_count):
		multimesh.set_instance_transform(index, _random_patch_transform())


func _random_patch_transform() -> Transform3D:
	var surface_direction := _random_sphere_direction()
	var alignment_rotation := Quaternion(Vector3.UP, surface_direction)
	var roll_rotation := Quaternion(Vector3.UP, randf_range(0.0, TAU))
	return Transform3D(Basis(alignment_rotation * roll_rotation), Vector3.ZERO)


func _random_sphere_direction() -> Vector3:
	var y := randf_range(-1.0, 1.0)
	var azimuth := randf_range(0.0, TAU)
	var horizontal_radius := sqrt(max(0.0, 1.0 - y * y))
	return Vector3(horizontal_radius * cos(azimuth), y, horizontal_radius * sin(azimuth))
