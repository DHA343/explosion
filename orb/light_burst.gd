@tool
extends GPUParticles2D

@export_range(1.0, 1024.0, 1.0) var particle_size: float = 128.0:
	set(value):
		particle_size = value
		if is_inside_tree():
			_apply_particle_size()

@export_range(1.0, 1000.0, 1.0) var sphere_radius: float = 450.0:
	set(value):
		sphere_radius = value
		if is_inside_tree():
			_apply_sphere_radius()


func _enter_tree() -> void:
	_apply_particle_size()
	_apply_sphere_radius()


func _apply_particle_size() -> void:
	set_instance_shader_parameter("particle_size", particle_size)


func _apply_sphere_radius() -> void:
	var shader_material := process_material as ShaderMaterial
	assert(shader_material != null, "LightBurstにはShaderMaterialを設定してください。")
	shader_material.set_shader_parameter("sphere_radius", sphere_radius)
