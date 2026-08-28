@tool
extends GPUParticles3D

@export_group("Appearance")

@export_range(0.005, 0.3, 0.005, "suffix:m")
var size := 0.06:
	set(value):
		size = value
		_update_shader_parameters()

@export_range(0.0, 1.0, 0.01)
var size_randomness := 0.25:
	set(value):
		size_randomness = value
		_update_shader_parameters()


func _ready() -> void:
	_update_shader_parameters()


func _update_shader_parameters() -> void:
	var shader_material := process_material as ShaderMaterial
	if shader_material == null:
		return

	shader_material.set_shader_parameter("size", size)
	shader_material.set_shader_parameter(
		"size_variation",
		size * size_randomness
	)
