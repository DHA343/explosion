class_name RisingParticles3D
extends GPUParticles3D

@export_range(20.0, 160.0, 0.5, "suffix:m") var final_height: float = 120.0
@export_range(0.0, 20.0, 0.5, "suffix:m") var spawn_depth: float = 5.0


func _ready() -> void:
	emitting = false
	set_spawn_progress(0.0)


func begin_spawn() -> void:
	set_spawn_progress(0.0)
	restart()
	emitting = true


func set_spawn_progress(progress: float) -> void:
	var material := process_material as ParticleProcessMaterial
	assert(material != null, "RisingParticles3D: ParticleProcessMaterialを設定してください。")

	var spawn_progress := clampf(progress, 0.0, 1.0)
	var ground_local_y := to_local(Vector3.ZERO).y
	var bottom_y := ground_local_y - spawn_depth
	var top_y := ground_local_y + final_height * spawn_progress
	var current_height := top_y - bottom_y

	var offset := material.emission_shape_offset
	amount_ratio = spawn_progress
	offset.y = (bottom_y + top_y) * 0.5
	material.emission_ring_height = current_height
	material.emission_shape_offset = offset


func end_spawn() -> void:
	set_spawn_progress(1.0)
	emitting = true


func reset_spawn() -> void:
	emitting = false
	set_spawn_progress(0.0)
	restart()
	emitting = false
