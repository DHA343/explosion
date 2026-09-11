@tool
extends Node3D

const STREAKS_TEXTURE_PARAMETER: StringName = &"streaks_texture"
const DISTORTION_TEXTURE_PARAMETER: StringName = &"captured_texture"
const SPHERE_RADIUS_PARAMETER: StringName = &"sphere_radius"

@export_range(0.01, 1.0, 0.01) var radius: float = 0.5:
	set(value):
		radius = value
		if is_node_ready():
			_update_radius()

@onready var _streaks_viewport: SubViewport = $InflowStreaksViewport
@onready var _inflow_streaks: InflowStreaks = $InflowStreaks
@onready var _energy_shell: EnergyShell = $EnergyShell
@onready var _distortion_viewport: SubViewport = $DistortionCapture/DistortionViewport
@onready var _distortion_shell: DistortionShell = $DistortionShell
@onready var _aura_flow: AuraFlow = $AuraFlow
@onready var _stream_line: StreamLine = $StreamLine
@onready var _core_glow: MeshInstance3D = $CoreGlow
@onready var _core_color: MeshInstance3D = $CoreColor


func _ready() -> void:
	_update_radius()

	var material := _inflow_streaks.material_override as ShaderMaterial
	assert(material != null, "InflowStreaks requires a ShaderMaterial over22ride.")

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
	_distortion_shell.radius = radius
	_aura_flow.radius = radius
	_stream_line.radius = radius
	_update_core_radius()


func _update_core_radius() -> void:
	var core_glow_material := _core_glow.get_active_material(0) as ShaderMaterial
	assert(core_glow_material != null, "CoreGlow requires a ShaderMaterial.")
	core_glow_material.set_shader_parameter(SPHERE_RADIUS_PARAMETER, radius)

	var core_color_material := _core_color.get_active_material(0) as ShaderMaterial
	assert(core_color_material != null, "CoreColor requires a ShaderMaterial.")
	core_color_material.set_shader_parameter(SPHERE_RADIUS_PARAMETER, radius)

	var core_glow_mesh := _core_glow.mesh as BoxMesh
	assert(core_glow_mesh != null, "CoreGlow requires a BoxMesh.")
	core_glow_mesh.size = Vector3.ONE * radius * 2.0

	var core_color_mesh := _core_color.mesh as BoxMesh
	assert(core_color_mesh != null, "CoreColor requires a BoxMesh.")
	core_color_mesh.size = Vector3.ONE * radius * 2.0
