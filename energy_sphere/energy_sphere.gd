@tool
extends Node3D

const STREAKS_TEXTURE_PARAMETER: StringName = &"streaks_texture"

@export var radius: float = 0.5:
	set(value):
		radius = value
		_update_energy_shell_size()

@onready var _streaks_viewport: SubViewport = $InflowStreaksViewport
@onready var _streaks_surface: MeshInstance3D = $InflowStreaks


func _ready() -> void:
	_update_energy_shell_size()

	var material := _streaks_surface.material_override as ShaderMaterial
	assert(material != null, "InflowStreaksSurface requires a ShaderMaterial override.")

	# NOTE: シリアライズされたViewportTextureは3Dエディタのカスタムシェーダーで解決されない。
	# 両方の子がSceneTreeへ入った後にライブテクスチャを設定し、エディタと実行時の出力を揃える。
	material.set_shader_parameter(STREAKS_TEXTURE_PARAMETER, _streaks_viewport.get_texture())


func _update_energy_shell_size() -> void:
	var energy_shell := get_node_or_null(^"EnergyShell") as MeshInstance3D
	if energy_shell == null:
		return

	var sphere_mesh := energy_shell.mesh as SphereMesh
	if sphere_mesh == null:
		return

	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2.0
