@tool
extends Node3D

const STREAKS_TEXTURE_PARAMETER: StringName = &"streaks_texture"

@export var radius: float = 0.5:
	set(value):
		radius = value
		if is_node_ready():
			_update_radius()

@onready var _streaks_viewport: SubViewport = $InflowStreaksViewport
@onready var _inflow_streaks: InflowStreaks = $InflowStreaks
@onready var _radial_energy: RadialEnergy = $RadialEnergy
@onready var _energy_shell: EnergyShell = $EnergyShell


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


func _update_radius() -> void:
	_energy_shell.radius = radius
	_inflow_streaks.radius = radius
	_set_radial_energy_property(&"radius", radius)


func _set_radial_energy_property(property_name: StringName, value: float) -> void:
	for property_info in _radial_energy.get_property_list():
		if property_info.name == property_name:
			_radial_energy.set(property_name, value)
			return
