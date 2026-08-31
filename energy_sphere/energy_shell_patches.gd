extends Node3D

@export_range(1, 32, 1) var patch_count: int = 12
@export_range(0.05, 0.8, 0.01) var patch_size_min_ratio: float = 0.18
@export_range(0.05, 0.8, 0.01) var patch_size_max_ratio: float = 0.45
@export_range(0.2, 3.0, 0.05, "suffix:s") var patch_lifetime_min: float = 0.6
@export_range(0.2, 3.0, 0.05, "suffix:s") var patch_lifetime_max: float = 1.4

var _patch_lifetimes: PackedFloat32Array

@onready var _patch_instances: MultiMeshInstance3D = $PatchInstances


func _ready() -> void:
	_populate_patches()


func _process(delta: float) -> void:
	var multimesh := _patch_instances.multimesh

	for index in range(patch_count):
		var custom_data := multimesh.get_instance_custom_data(index)
		var patch_life := custom_data.g + delta / _patch_lifetimes[index]

		if patch_life >= 1.0:
			_reset_patch(index)
			continue

		custom_data.g = patch_life
		multimesh.set_instance_custom_data(index, custom_data)


func _populate_patches() -> void:
	var multimesh := _patch_instances.multimesh
	assert(multimesh != null, "PatchInstances requires a MultiMesh.")
	multimesh.instance_count = patch_count
	_patch_lifetimes.resize(patch_count)

	for index in range(patch_count):
		_reset_patch(index, randf())


func _reset_patch(index: int, patch_life: float = 0.0) -> void:
	var multimesh := _patch_instances.multimesh
	var patch_size_ratio := randf_range(patch_size_min_ratio, patch_size_max_ratio)
	var noise_offset := Vector2(randf(), randf())

	_patch_lifetimes[index] = randf_range(patch_lifetime_min, patch_lifetime_max)
	multimesh.set_instance_transform(index, _random_patch_transform())
	multimesh.set_instance_custom_data(
		index,
		Color(patch_size_ratio, patch_life, noise_offset.x, noise_offset.y)
	)


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
