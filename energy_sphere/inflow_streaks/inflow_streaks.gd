@tool
class_name InflowStreaks
extends MeshInstance3D

@export var radius: float = 0.5:
	set(value):
		radius = value
		_update_mesh_size()

@export_range(0.1, 2.0, 0.01)
var radius_ratio: float = 1.0:
	set(value):
		radius_ratio = value
		_update_mesh_size()


func _ready() -> void:
	_update_mesh_size()


func _update_mesh_size() -> void:
	var quad := mesh as QuadMesh
	if quad == null:
		return

	quad.size = Vector2.ONE * radius * 2.0 * radius_ratio
