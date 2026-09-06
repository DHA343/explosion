@tool
extends Node3D

const STREAKS_TEXTURE_PARAMETER: StringName = &"streaks_texture"
const DISTORTION_TEXTURE_PARAMETER: StringName = &"captured_texture"

@export var radius: float = 0.5:
	set(value):
		radius = value
		if is_node_ready():
			_update_radius()

@onready var _streaks_viewport: SubViewport = $InflowStreaksViewport
@onready var _inflow_streaks: InflowStreaks = $InflowStreaks
@onready var _energy_shell: EnergyShell = $EnergyShell
@onready var _distortion_viewport: SubViewport = $DistortionCapture/DistortionViewport
@onready var _distortion_shell: MeshInstance3D = $DistortionShell


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

	var distortion_material := _distortion_shell.material_override as ShaderMaterial
	assert(distortion_material != null, "DistortionShell requires a ShaderMaterial override.")
	distortion_material.set_shader_parameter(
		DISTORTION_TEXTURE_PARAMETER,
		_distortion_viewport.get_texture()
	)


func _update_radius() -> void:
	_energy_shell.radius = radius
	_inflow_streaks.radius = radius
