@tool
extends GPUParticles2D

const BASE_MATERIAL: ParticleProcessMaterial = preload(
	"res://energy_sphere/inflow_streaks/inflow_streaks_process_material.tres"
)

@export_group("Motion Override")

@export var motion_override_enabled: bool = false:
	set(value):
		motion_override_enabled = value
		_update_process_material()

@export var orbit_velocity_min: float = 0.0:
	set(value):
		orbit_velocity_min = value
		_update_process_material()

@export var orbit_velocity_max: float = 0.0:
	set(value):
		orbit_velocity_max = value
		_update_process_material()

@export var radial_velocity_min: float = 0.0:
	set(value):
		radial_velocity_min = value
		_update_process_material()

@export var radial_velocity_max: float = 0.0:
	set(value):
		radial_velocity_max = value
		_update_process_material()


func _ready() -> void:
	_connect_base_material()
	_update_process_material()


func _update_process_material() -> void:
	var local_material := BASE_MATERIAL.duplicate() as ParticleProcessMaterial
	if not motion_override_enabled:
		process_material = local_material
		return

	local_material.orbit_velocity_min = orbit_velocity_min
	local_material.orbit_velocity_max = orbit_velocity_max
	local_material.radial_velocity_min = radial_velocity_min
	local_material.radial_velocity_max = radial_velocity_max
	process_material = local_material


func _connect_base_material() -> void:
	if not BASE_MATERIAL.changed.is_connected(_on_base_material_changed):
		BASE_MATERIAL.changed.connect(_on_base_material_changed)


func _on_base_material_changed() -> void:
	_update_process_material()
