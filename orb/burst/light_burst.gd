@tool
extends GPUParticles2D

@export_range(1.0, 2000.0, 1.0, "suffix:px") var sphere_size: float = 400.0:
	set(value):
		sphere_size = value
		if process_material != null:
			_apply_process_parameters()


@export_range(1.0, 200.0, 1.0, "suffix:px") var particle_width: float = 140.0:
	set(value):
		particle_width = value
		if process_material != null:
			_apply_process_parameters()


func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		use_fixed_seed = true
		seed = randi()
	_apply_process_parameters()


func _apply_process_parameters() -> void:
	var shader_material := process_material as ShaderMaterial
	assert(shader_material != null, "LightBurstにはShaderMaterialを設定してください。")
	shader_material.set_shader_parameter("radius", sphere_size)
	shader_material.set_shader_parameter("particle_width", particle_width)
