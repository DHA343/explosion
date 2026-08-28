@tool
extends Node3D

const STREAKS_TEXTURE_PARAMETER: StringName = &"streaks_texture"

@onready var _streaks_viewport: SubViewport = $InflowStreaksViewport
@onready var _streaks_surface: MeshInstance3D = $InflowStreaksSurface


func _ready() -> void:
	var material := _streaks_surface.material_override as ShaderMaterial
	assert(material != null, "InflowStreaksSurface requires a ShaderMaterial override.")

	# NOTE: シリアライズされたViewportTextureは3Dエディタのカスタムシェーダーで解決されない。
	# 両方の子がSceneTreeへ入った後にライブテクスチャを設定し、エディタと実行時の出力を揃える。
	material.set_shader_parameter(STREAKS_TEXTURE_PARAMETER, _streaks_viewport.get_texture())
