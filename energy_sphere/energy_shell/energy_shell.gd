@tool
class_name EnergyShell
extends Node3D

const BANDS_INNER_BAND_POSITION_PARAMETER: StringName = &"inner_band_position"
const PATCH_INNER_RADIUS_PARAMETER: StringName = &"inner_radius"

@export_range(0.0, 0.5, 0.01) var thickness_ratio: float = 0.05:
	set(value):
		thickness_ratio = value
		if is_node_ready():
			_update_shell()

var radius: float = 0.5:
	set(value):
		radius = value
		if is_node_ready():
			_update_shell()

var inner_radius: float:
	get:
		return radius * (1.0 - thickness_ratio)

var inner_band_position: float:
	get:
		var inner_radius_ratio := 1.0 - thickness_ratio
		return 1.0 - sqrt(max(0.0, 1.0 - inner_radius_ratio * inner_radius_ratio))

@onready var _shell_body: MeshInstance3D = $ShellBody
@onready var _shell_bands: MeshInstance3D = $ShellBands
@onready var _patch_instances: MultiMeshInstance3D = $ShellPatches/PatchInstances


func _ready() -> void:
	_update_shell()


func _update_shell() -> void:
	var sphere_mesh := _shell_body.mesh as SphereMesh
	assert(sphere_mesh != null, "ShellBody requires a SphereMesh.")

	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2.0
	_patch_instances.set_instance_shader_parameter(PATCH_INNER_RADIUS_PARAMETER, inner_radius)
	_shell_bands.set_instance_shader_parameter(BANDS_INNER_BAND_POSITION_PARAMETER, inner_band_position)
