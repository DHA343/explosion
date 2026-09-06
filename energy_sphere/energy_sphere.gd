@tool
extends Node3D

const STREAKS_TEXTURE_PARAMETER: StringName = &"streaks_texture"
const REFRACTION_SOURCE_TEXTURE_PARAMETER: StringName = &"source_texture"

@export var radius: float = 0.5:
	set(value):
		radius = value
		if is_node_ready():
			_update_radius()

@onready var _streaks_viewport: SubViewport = $InflowStreaksViewport
@onready var _inflow_streaks: InflowStreaks = $InflowStreaks
@onready var _energy_shell: EnergyShell = $EnergyShell
@onready var _refraction_viewport: SubViewport = $RefractionCapture/RefractionViewport
@onready var _refraction_shell: MeshInstance3D = $RefractionShell


func _ready() -> void:
	_update_radius()

	var material := _inflow_streaks.material_override as ShaderMaterial
	assert(material != null, "InflowStreaks requires a ShaderMaterial override.")

	# NOTE: シリアライズされたViewportTextureは3Dエディタのカスタムシェーダーで解決されない。
	# 両方の子がSceneTreeへ入った後にライブテクスチャを設定し、
	# エディタと実行時の出力を揃える。
	material.set_shader_parameter(
		STREAKS_TEXTURE_PARAMETER,
		_streaks_viewport.get_texture()
	)

	var refraction_material := _refraction_shell.material_override as ShaderMaterial
	assert(refraction_material != null, "RefractionShell requires a ShaderMaterial override.")
	refraction_material.set_shader_parameter(
		REFRACTION_SOURCE_TEXTURE_PARAMETER,
		_refraction_viewport.get_texture()
	)


func _update_radius() -> void:
	_energy_shell.radius = radius
	_inflow_streaks.radius = radius
