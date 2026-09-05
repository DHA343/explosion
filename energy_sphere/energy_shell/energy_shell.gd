@tool
class_name EnergyShell
extends Node3D

signal inner_radius_changed(value: float)

const PATCH_INNER_RADIUS_PARAMETER: StringName = &"inner_radius"

@export_range(0.0, 0.5, 0.01) var thickness_ratio: float = 0.06:
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

@onready var _outer_rim: MeshInstance3D = $OuterRim
@onready var _inner_rim: MeshInstance3D = $InnerRim
@onready var _patch_instances: MultiMeshInstance3D = $ShellPatches/PatchInstances


func _ready() -> void:
	_update_shell()


func _update_shell() -> void:
	var sphere_mesh := _outer_rim.mesh as SphereMesh
	assert(sphere_mesh != null, "OuterRim requires a SphereMesh.")

	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2.0
	_inner_rim.scale = Vector3.ONE * (1.0 - thickness_ratio)
	_patch_instances.set_instance_shader_parameter(PATCH_INNER_RADIUS_PARAMETER, inner_radius)
	inner_radius_changed.emit(inner_radius)
