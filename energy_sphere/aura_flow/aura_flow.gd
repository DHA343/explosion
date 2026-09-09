@tool
class_name AuraFlow
extends Node3D

const SPHERE_RADIUS_PARAMETER: StringName = &"sphere_radius"
const VOLUME_RADIUS_PARAMETER: StringName = &"volume_radius"
const FLOW_SEED_PARAMETER: StringName = &"flow_seed"
const RADIAL_SPEED_PARAMETER: StringName = &"radial_speed"
const RADIAL_VARIATION_PARAMETER: StringName = &"radial_variation"
const TANGENTIAL_STRENGTH_PARAMETER: StringName = &"tangential_strength"
const FLOW_SCALE_PARAMETER: StringName = &"flow_scale"
const FLOW_SPEED_PARAMETER: StringName = &"flow_speed"
const SOURCE_SCALE_PARAMETER: StringName = &"source_scale"
const SOURCE_SPEED_PARAMETER: StringName = &"source_speed"
const SOURCE_MIN_STRENGTH_PARAMETER: StringName = &"source_min_strength"
const SOURCE_CONTRAST_PARAMETER: StringName = &"source_contrast"
const SOURCE_SEED_PARAMETER: StringName = &"source_seed"
const CYAN_SEED_PARAMETER: StringName = &"cyan_seed"
const PURPLE_SEED_PARAMETER: StringName = &"purple_seed"
const SHAPE_SEED_PARAMETER: StringName = &"shape_seed"
const SHAPE_SCALE_PARAMETER: StringName = &"shape_scale"
const SHAPE_SPEED_PARAMETER: StringName = &"shape_speed"
const SHAPE_CONTRAST_PARAMETER: StringName = &"shape_contrast"
const CYAN_COLOR_PARAMETER: StringName = &"cyan_color"
const PURPLE_COLOR_PARAMETER: StringName = &"purple_color"
const PARTICLE_COLOR_PARAMETER: StringName = &"particle_color"
const CYAN_HAZE_DENSITY_PARAMETER: StringName = &"cyan_haze_density"
const PURPLE_HAZE_DENSITY_PARAMETER: StringName = &"purple_haze_density"
const HAZE_OPACITY_PARAMETER: StringName = &"haze_opacity"
const HAZE_EMISSION_STRENGTH_PARAMETER: StringName = &"haze_emission_strength"
const HAZE_LIFETIME_MIN_PARAMETER: StringName = &"haze_lifetime_min"
const HAZE_LIFETIME_MAX_PARAMETER: StringName = &"haze_lifetime_max"
const HAZE_LIFETIME_FADE_START_PARAMETER: StringName = &"haze_lifetime_fade_start"
const HAZE_DILUTION_POWER_PARAMETER: StringName = &"haze_dilution_power"
const PARTICLE_SIZE_MIN_RATIO_PARAMETER: StringName = &"particle_size_min_ratio"
const PARTICLE_SIZE_MAX_RATIO_PARAMETER: StringName = &"particle_size_max_ratio"
const PARTICLE_LIFETIME_PARAMETER: StringName = &"particle_lifetime"
const PARTICLE_OPACITY_PARAMETER: StringName = &"particle_opacity"
const PARTICLE_EMISSION_STRENGTH_PARAMETER: StringName = &"particle_emission_strength"
const VIEW_FRONT_VISIBILITY_PARAMETER: StringName = &"view_front_visibility"
const VIEW_FALLOFF_POWER_PARAMETER: StringName = &"view_falloff_power"

const PARTICLE_LAYER: int = 1

@export_group("Appearance")

@export var cyan_color: Color = Color(0.18, 0.78, 1.0, 1.0):
	set(value):
		cyan_color = value
		if is_node_ready():
			_sync_effect()

@export var purple_color: Color = Color(0.58, 0.25, 1.0, 1.0):
	set(value):
		purple_color = value
		if is_node_ready():
			_sync_effect()

@export_range(0.0, 1.0, 0.01)
var cyan_haze_density: float = 0.92:
	set(value):
		cyan_haze_density = value
		if is_node_ready():
			_sync_effect()

@export_range(0.0, 1.0, 0.01)
var purple_haze_density: float = 0.72:
	set(value):
		purple_haze_density = value
		if is_node_ready():
			_sync_effect()

@export_range(0.0, 1.0, 0.01)
var haze_opacity: float = 0.42:
	set(value):
		haze_opacity = value
		if is_node_ready():
			_sync_effect()

@export_range(0.0, 8.0, 0.05)
var haze_emission_strength: float = 2.0:
	set(value):
		haze_emission_strength = value
		if is_node_ready():
			_sync_effect()

@export_group("Flow")

@export_range(0.0, 8.0, 0.1)
var radial_speed: float = 1.0:
	set(value):
		radial_speed = value
		if is_node_ready():
			_sync_effect()

@export_range(0.0, 1.0, 0.01)
var radial_variation: float = 0.35:
	set(value):
		radial_variation = value
		if is_node_ready():
			_sync_effect()

@export_range(0.0, 1.5, 0.01)
var tangential_strength: float = 0.46:
	set(value):
		tangential_strength = value
		if is_node_ready():
			_sync_effect()

@export_range(0.1, 4.0, 0.05)
var flow_scale: float = 0.78:
	set(value):
		flow_scale = value
		if is_node_ready():
			_sync_effect()

@export_range(0.0, 8.0, 0.1)
var flow_speed: float = 1.0:
	set(value):
		flow_speed = value
		if is_node_ready():
			_sync_effect()

@export var flow_seed: int = 2048:
	set(value):
		flow_seed = value
		if is_node_ready():
			_sync_effect()

@export_group("Source")

@export_range(0.1, 6.0, 0.05)
var source_scale: float = 1.45:
	set(value):
		source_scale = value
		if is_node_ready():
			_sync_effect()

@export_range(0.0, 2.0, 0.01)
var source_speed: float = 0.16:
	set(value):
		source_speed = value
		if is_node_ready():
			_sync_effect()

@export_range(0.0, 1.0, 0.01)
var source_min_strength: float = 0.32:
	set(value):
		source_min_strength = value
		if is_node_ready():
			_sync_effect()

@export_range(0.1, 16.0, 0.1)
var source_contrast: float = 4.0:
	set(value):
		source_contrast = value
		if is_node_ready():
			_sync_effect()

@export var cyan_seed: int = 343:
	set(value):
		cyan_seed = value
		if is_node_ready():
			_sync_effect()

@export var purple_seed: int = 1343:
	set(value):
		purple_seed = value
		if is_node_ready():
			_sync_effect()

@export_group("Shape")

@export_range(0.1, 4.0, 0.05)
var shape_scale: float = 0.78:
	set(value):
		shape_scale = value
		if is_node_ready():
			_sync_effect()

@export_range(0.0, 2.0, 0.01)
var shape_speed: float = 0.05:
	set(value):
		shape_speed = value
		if is_node_ready():
			_sync_effect()

@export var shape_seed: int = 7001:
	set(value):
		shape_seed = value
		if is_node_ready():
			_sync_effect()

@export_range(0.25, 4.0, 0.05)
var shape_contrast: float = 1.45:
	set(value):
		shape_contrast = value
		if is_node_ready():
			_sync_effect()

@export_group("Haze")

@export_range(0.05, 4.0, 0.05, "suffix:s")
var haze_lifetime_min: float = 0.35:
	set(value):
		haze_lifetime_min = value
		if is_node_ready():
			_sync_effect()

@export_range(0.1, 6.0, 0.05, "suffix:s")
var haze_lifetime_max: float = 2.6:
	set(value):
		haze_lifetime_max = value
		if is_node_ready():
			_sync_effect()

@export_range(0.1, 0.6, 0.01)
var volume_margin_ratio: float = 0.25:
	set(value):
		volume_margin_ratio = value
		if is_node_ready():
			_sync_effect()

@export_range(0.0, 1.0, 0.01)
var haze_lifetime_fade_start: float = 0.72:
	set(value):
		haze_lifetime_fade_start = value
		if is_node_ready():
			_sync_effect()

@export_range(0.0, 4.0, 0.05)
var haze_dilution_power: float = 0.7:
	set(value):
		haze_dilution_power = value
		if is_node_ready():
			_sync_effect()

@export_group("View")

@export_range(0.0, 1.0, 0.01)
var view_front_visibility: float = 0.1:
	set(value):
		view_front_visibility = value
		if is_node_ready():
			_sync_effect()

@export_range(0.5, 4.0, 0.05)
var view_falloff_power: float = 2.1:
	set(value):
		view_falloff_power = value
		if is_node_ready():
			_sync_effect()

@export_group("Particles")

@export_range(1, 6000, 1)
var cyan_amount: int = 2000:
	set(value):
		cyan_amount = value
		if is_node_ready():
			_sync_effect()

@export_range(1, 6000, 1)
var purple_amount: int = 2000:
	set(value):
		purple_amount = value
		if is_node_ready():
			_sync_effect()

@export_range(0.3, 4.0, 0.05, "suffix:s")
var particle_lifetime: float = 2.0:
	set(value):
		particle_lifetime = value
		if is_node_ready():
			_sync_effect()

@export_range(0.002, 0.05, 0.001)
var particle_size_min_ratio: float = 0.008:
	set(value):
		particle_size_min_ratio = value
		if is_node_ready():
			_sync_effect()

@export_range(0.002, 0.05, 0.001)
var particle_size_max_ratio: float = 0.016:
	set(value):
		particle_size_max_ratio = value
		if is_node_ready():
			_sync_effect()

@export_range(0.0, 1.0, 0.01)
var particle_opacity: float = 0.34:
	set(value):
		particle_opacity = value
		if is_node_ready():
			_sync_effect()

@export_range(0.0, 5.0, 0.05)
var particle_emission_strength: float = 1.55:
	set(value):
		particle_emission_strength = value
		if is_node_ready():
			_sync_effect()

var radius: float = 0.5:
	set(value):
		radius = value
		if is_node_ready():
			_sync_effect()

@onready var _haze_volume: MeshInstance3D = $HazeVolume
@onready var _cyan_particles: GPUParticles3D = $Particles/CyanParticles
@onready var _purple_particles: GPUParticles3D = $Particles/PurpleParticles


func _ready() -> void:
	_prepare_particle_resources(_cyan_particles)
	_prepare_particle_resources(_purple_particles)
	_sync_effect()


func _sync_effect() -> void:
	_sync_haze_volume()
	_sync_particle_system(_cyan_particles, cyan_amount, cyan_seed, cyan_color)
	_sync_particle_system(_purple_particles, purple_amount, purple_seed, purple_color)


func _sync_haze_volume() -> void:
	var maximum_haze_travel_ratio: float = radial_speed * (1.0 + radial_variation) * haze_lifetime_max
	var volume_radius: float = radius * (
		1.0 + maximum_haze_travel_ratio + volume_margin_ratio
	)
	var volume_mesh := _haze_volume.mesh as SphereMesh
	assert(volume_mesh != null, "AuraFlow requires a SphereMesh for HazeVolume.")
	volume_mesh.radius = volume_radius
	volume_mesh.height = volume_radius * 2.0
	_haze_volume.custom_aabb = AABB(
		Vector3.ONE * -volume_radius,
		Vector3.ONE * volume_radius * 2.0
	)

	var material := _haze_volume.material_override as ShaderMaterial
	assert(material != null, "AuraFlow requires a ShaderMaterial for HazeVolume.")
	material.set_shader_parameter(SPHERE_RADIUS_PARAMETER, radius)
	material.set_shader_parameter(VOLUME_RADIUS_PARAMETER, volume_radius)
	material.set_shader_parameter(CYAN_COLOR_PARAMETER, cyan_color)
	material.set_shader_parameter(PURPLE_COLOR_PARAMETER, purple_color)
	material.set_shader_parameter(CYAN_HAZE_DENSITY_PARAMETER, cyan_haze_density)
	material.set_shader_parameter(PURPLE_HAZE_DENSITY_PARAMETER, purple_haze_density)
	material.set_shader_parameter(HAZE_OPACITY_PARAMETER, haze_opacity)
	material.set_shader_parameter(HAZE_EMISSION_STRENGTH_PARAMETER, haze_emission_strength)
	material.set_shader_parameter(FLOW_SEED_PARAMETER, flow_seed)
	material.set_shader_parameter(RADIAL_SPEED_PARAMETER, radial_speed)
	material.set_shader_parameter(RADIAL_VARIATION_PARAMETER, radial_variation)
	material.set_shader_parameter(TANGENTIAL_STRENGTH_PARAMETER, tangential_strength)
	material.set_shader_parameter(FLOW_SCALE_PARAMETER, flow_scale)
	material.set_shader_parameter(FLOW_SPEED_PARAMETER, flow_speed)
	material.set_shader_parameter(SOURCE_SCALE_PARAMETER, source_scale)
	material.set_shader_parameter(SOURCE_SPEED_PARAMETER, source_speed)
	material.set_shader_parameter(SOURCE_MIN_STRENGTH_PARAMETER, source_min_strength)
	material.set_shader_parameter(SOURCE_CONTRAST_PARAMETER, source_contrast)
	material.set_shader_parameter(CYAN_SEED_PARAMETER, cyan_seed)
	material.set_shader_parameter(PURPLE_SEED_PARAMETER, purple_seed)
	material.set_shader_parameter(SHAPE_SEED_PARAMETER, shape_seed)
	material.set_shader_parameter(SHAPE_SCALE_PARAMETER, shape_scale)
	material.set_shader_parameter(SHAPE_SPEED_PARAMETER, shape_speed)
	material.set_shader_parameter(SHAPE_CONTRAST_PARAMETER, shape_contrast)
	material.set_shader_parameter(HAZE_LIFETIME_MIN_PARAMETER, haze_lifetime_min)
	material.set_shader_parameter(HAZE_LIFETIME_MAX_PARAMETER, haze_lifetime_max)
	material.set_shader_parameter(
		HAZE_LIFETIME_FADE_START_PARAMETER,
		haze_lifetime_fade_start
	)
	material.set_shader_parameter(HAZE_DILUTION_POWER_PARAMETER, haze_dilution_power)
	material.set_shader_parameter(VIEW_FRONT_VISIBILITY_PARAMETER, view_front_visibility)
	material.set_shader_parameter(VIEW_FALLOFF_POWER_PARAMETER, view_falloff_power)


func _prepare_particle_resources(particles: GPUParticles3D) -> void:
	var process_material := particles.process_material as ShaderMaterial
	assert(process_material != null, "AuraFlow requires a ShaderMaterial particle process material.")
	particles.process_material = process_material.duplicate()

	var source_mesh := particles.draw_pass_1 as QuadMesh
	assert(source_mesh != null, "AuraFlow requires a QuadMesh particle draw pass.")
	var particle_mesh := source_mesh.duplicate() as QuadMesh
	var render_material := particle_mesh.material as ShaderMaterial
	assert(render_material != null, "AuraFlow requires a ShaderMaterial particle render material.")
	particle_mesh.material = render_material.duplicate()
	particles.draw_pass_1 = particle_mesh


func _sync_particle_system(
	particles: GPUParticles3D,
	amount_value: int,
	seed_value: int,
	color_value: Color
) -> void:
	var process_material := particles.process_material as ShaderMaterial
	assert(process_material != null, "AuraFlow requires a ShaderMaterial particle process material.")
	var particle_mesh := particles.draw_pass_1 as QuadMesh
	assert(particle_mesh != null, "AuraFlow requires a QuadMesh particle draw pass.")
	var render_material := particle_mesh.material as ShaderMaterial
	assert(render_material != null, "AuraFlow requires a ShaderMaterial particle render material.")

	particles.layers = PARTICLE_LAYER
	particles.draw_passes = 1
	particles.amount = amount_value
	particles.lifetime = particle_lifetime
	particles.preprocess = particle_lifetime
	particles.seed = seed_value
	particles.visibility_aabb = _get_visibility_aabb()

	process_material.set_shader_parameter(SPHERE_RADIUS_PARAMETER, radius)
	process_material.set_shader_parameter(PARTICLE_SIZE_MIN_RATIO_PARAMETER, particle_size_min_ratio)
	process_material.set_shader_parameter(PARTICLE_SIZE_MAX_RATIO_PARAMETER, particle_size_max_ratio)
	process_material.set_shader_parameter(FLOW_SEED_PARAMETER, flow_seed)
	process_material.set_shader_parameter(RADIAL_SPEED_PARAMETER, radial_speed)
	process_material.set_shader_parameter(RADIAL_VARIATION_PARAMETER, radial_variation)
	process_material.set_shader_parameter(TANGENTIAL_STRENGTH_PARAMETER, tangential_strength)
	process_material.set_shader_parameter(FLOW_SCALE_PARAMETER, flow_scale)
	process_material.set_shader_parameter(FLOW_SPEED_PARAMETER, flow_speed)
	process_material.set_shader_parameter(SOURCE_SEED_PARAMETER, seed_value)
	process_material.set_shader_parameter(SOURCE_SCALE_PARAMETER, source_scale)
	process_material.set_shader_parameter(SOURCE_SPEED_PARAMETER, source_speed)
	process_material.set_shader_parameter(SOURCE_MIN_STRENGTH_PARAMETER, source_min_strength)
	process_material.set_shader_parameter(SOURCE_CONTRAST_PARAMETER, source_contrast)

	render_material.set_shader_parameter(PARTICLE_LIFETIME_PARAMETER, particle_lifetime)
	render_material.set_shader_parameter(PARTICLE_COLOR_PARAMETER, color_value)
	render_material.set_shader_parameter(PARTICLE_OPACITY_PARAMETER, particle_opacity)
	render_material.set_shader_parameter(PARTICLE_EMISSION_STRENGTH_PARAMETER, particle_emission_strength)
	render_material.set_shader_parameter(VIEW_FRONT_VISIBILITY_PARAMETER, view_front_visibility)
	render_material.set_shader_parameter(VIEW_FALLOFF_POWER_PARAMETER, view_falloff_power)


func _get_visibility_aabb() -> AABB:
	var maximum_travel_ratio := (radial_speed + tangential_strength) * (1.0 + radial_variation) * particle_lifetime
	var extent := radius * (1.35 + maximum_travel_ratio)
	return AABB(Vector3.ONE * -extent, Vector3.ONE * extent * 2.0)
