@tool
extends Node3D

@onready var _core_effects: MeshInstance3D = $CoreEffects
@onready var _viewport: SubViewport = $SubViewport


func _ready() -> void:
	var material := _core_effects.material_override as StandardMaterial3D
	assert(material != null, "CoreEffectsにはStandardMaterial3Dを設定してください。")
	material.albedo_texture = _viewport.get_texture()
