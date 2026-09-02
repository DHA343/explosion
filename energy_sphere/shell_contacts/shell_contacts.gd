@tool
class_name ShellContacts
extends Node3D

const EFFECT_TIME_PARAMETER: StringName = &"effect_time"

@export_range(0.05, 10.0, 0.01, "suffix:m") var radius: float = 0.5:
	set(value):
		radius = value
		if is_node_ready():
			_update_size()

@export var preview_enabled: bool = false:
	set(value):
		preview_enabled = value
		if is_node_ready():
			_update_effect_time()

@export_range(0.0, 10.0, 0.01, "suffix:s") var preview_time: float = 0.0:
	set(value):
		preview_time = value
		if is_node_ready() and preview_enabled:
			_update_effect_time()

var _elapsed_time: float = 0.0

@onready var _contact_field: MeshInstance3D = $ContactField


func _ready() -> void:
	_update_size()
	_update_effect_time()


func _process(delta: float) -> void:
	if preview_enabled:
		return

	_elapsed_time += delta
	_update_effect_time()


func _update_size() -> void:
	var field_mesh := _contact_field.mesh as QuadMesh
	assert(field_mesh != null, "ContactField requires a QuadMesh.")
	field_mesh.size = Vector2.ONE * radius * 2.0


func _update_effect_time() -> void:
	var material := _contact_field.material_override as ShaderMaterial
	assert(material != null, "ContactField requires a ShaderMaterial override.")
	var current_time := preview_time if preview_enabled else _elapsed_time
	material.set_shader_parameter(EFFECT_TIME_PARAMETER, current_time)
