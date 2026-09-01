@tool
extends Node3D

const STREAKS_TEXTURE_PARAMETER: StringName = &"streaks_texture"

@export var radius: float = 0.5:
	set(value):
		radius = value
		if is_node_ready():
			_update_radius()

@onready var _streaks_viewport: SubViewport = $InflowStreaksViewport
@onready var _streaks_surface: MeshInstance3D = $InflowStreaks
@onready var _energy_shell: EnergyShell = $EnergyShell

func _ready() -> void:
	_update_radius()

	var material := _streaks_surface.material_override as ShaderMaterial
	assert(material != null, "InflowStreaksSurface requires a ShaderMaterial override.")

	# NOTE: シリアライズされたViewportTextureは3Dエディタのカスタムシェーダーで解決されない。
	# 両方の子がSceneTreeへ入った後にライブテクスチャを設定し、エディタと実行時の出力を揃える。
	material.set_shader_parameter(STREAKS_TEXTURE_PARAMETER, _streaks_viewport.get_texture())


func _update_radius() -> void:
	_energy_shell.radius = radius
