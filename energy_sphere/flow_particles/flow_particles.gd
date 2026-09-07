@tool
class_name FlowParticles
extends Node3D

@export_group("Particles")
@export_range(256, 6000, 1) var amount: int = 2400
@export_range(0.3, 4.0, 0.05, "suffix:s") var lifetime: float = 1.8
@export_range(0.002, 0.05, 0.001) var particle_size_min_ratio: float = 0.008
@export_range(0.002, 0.05, 0.001) var particle_size_max_ratio: float = 0.016

@export_group("Spawn")
@export_range(1.0, 1.2, 0.005) var spawn_radius_min_ratio: float = 1.00
@export_range(1.0, 1.3, 0.005) var spawn_radius_max_ratio: float = 1.04

@export_group("Motion")
@export_range(0.0, 1.0, 0.01) var outward_speed: float = 0.16

@export_group("Large Flow")
@export_range(0.0, 2.0, 0.01) var flow_strength: float = 0.55
@export_range(0.1, 4.0, 0.05) var flow_scale: float = 0.85
@export_range(0.0, 2.0, 0.01) var flow_speed: float = 0.22
@export_range(0.0, 1.0, 0.01) var flow_normal_amount: float = 0.20

@export_group("Turbulence")
@export_range(0.0, 1.5, 0.01) var turbulence_strength: float = 0.25
@export_range(0.5, 12.0, 0.05) var turbulence_scale: float = 4.0
@export_range(0.0, 4.0, 0.01) var turbulence_speed: float = 0.75

@export_group("Appearance")
@export var color: Color = Color(0.20, 0.75, 1.0, 1.0)
@export_range(0.0, 1.0, 0.01) var opacity: float = 0.32
@export_range(0.0, 5.0, 0.05) var emission_strength: float = 1.4

var radius: float = 0.5:
	set(value):
		radius = value
		if is_node_ready():
			_update_radius()

@onready var _particles: GPUParticles3D = $Particles
@onready var _process_material: ShaderMaterial = _particles.process_material as ShaderMaterial
@onready var _particle_mesh: QuadMesh = _particles.draw_pass_1 as QuadMesh
@onready var _render_material: ShaderMaterial = _particle_mesh.material as ShaderMaterial


func _ready() -> void:
	assert(_process_material != null, "FlowParticles requires a particle process ShaderMaterial.")
	assert(_render_material != null, "FlowParticles requires a particle render ShaderMaterial.")
	_particles.amount = amount
	_particles.lifetime = lifetime
	_particles.preprocess = lifetime
	_particles.one_shot = false
	_particles.emitting = true
	_particles.local_coords = true
	_particles.fixed_fps = 60
	_particles.interpolate = true
	_particles.fract_delta = true
	_particles.trail_enabled = false
	_particles.draw_order = GPUParticles3D.DRAW_ORDER_VIEW_DEPTH
	_particles.transform_align = GPUParticles3D.TRANSFORM_ALIGN_Z_BILLBOARD
	_particles.use_fixed_seed = true
	_particles.seed = 343
	_update_radius()


func _update_radius() -> void:
	_process_material.set_shader_parameter(&"sphere_radius", radius)
	_process_material.set_shader_parameter(&"particle_size_min_ratio", particle_size_min_ratio)
	_process_material.set_shader_parameter(&"particle_size_max_ratio", particle_size_max_ratio)
	_process_material.set_shader_parameter(&"spawn_radius_min_ratio", spawn_radius_min_ratio)
	_process_material.set_shader_parameter(&"spawn_radius_max_ratio", spawn_radius_max_ratio)
	_process_material.set_shader_parameter(&"outward_speed", outward_speed)
	_process_material.set_shader_parameter(&"flow_strength", flow_strength)
	_process_material.set_shader_parameter(&"flow_scale", flow_scale)
	_process_material.set_shader_parameter(&"flow_speed", flow_speed)
	_process_material.set_shader_parameter(&"flow_normal_amount", flow_normal_amount)
	_process_material.set_shader_parameter(&"turbulence_strength", turbulence_strength)
	_process_material.set_shader_parameter(&"turbulence_scale", turbulence_scale)
	_process_material.set_shader_parameter(&"turbulence_speed", turbulence_speed)
	_process_material.set_shader_parameter(&"particle_lifetime", lifetime)
	_process_material.set_shader_parameter(&"particle_color", color)

	_render_material.set_shader_parameter(&"particle_color", color)
	_render_material.set_shader_parameter(&"particle_lifetime", lifetime)
	_render_material.set_shader_parameter(&"opacity", opacity)
	_render_material.set_shader_parameter(&"emission_strength", emission_strength)
	var extent := radius * 2.5
	_particles.visibility_aabb = AABB(Vector3.ONE * -extent, Vector3.ONE * extent * 2.0)
