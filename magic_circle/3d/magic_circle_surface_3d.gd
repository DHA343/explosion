class_name MagicCircleSurface3D
extends MeshInstance3D

## SubViewportの描画結果を3D空間へ表示する魔法陣用Surface。

const BLEND_BALANCE_PARAMETER := &"blend_balance"
const INTENSITY_PARAMETER := &"intensity"
const OPACITY_PARAMETER := &"opacity"
const SURFACE_SHADER: Shader = preload("res://magic_circle/3d/magic_circle_surface_3d.gdshader")
const VIEWPORT_TEXTURE_PARAMETER := &"viewport_texture"

## 0.0でAdd寄り、1.0でMix寄りの合成になる。
@export_range(0.0, 1.0, 0.01) var blend_balance: float = 0.5:
	set(value):
		blend_balance = clampf(value, 0.0, 1.0)
		_update_runtime_blend_balance()

@export_range(0.0, 8.0, 0.05) var intensity: float = 1.0:
	set(value):
		intensity = clampf(value, 0.0, 8.0)
		_update_runtime_intensity()

var _viewport: SubViewport
var _runtime_material: ShaderMaterial
var _is_bind_scheduled: bool = false
var _opacity: float = 1.0


func _ready() -> void:
	visible = false
	if DisplayServer.get_name() == "headless":
		return
	_schedule_viewport_binding()


func bind_viewport(viewport: SubViewport) -> void:
	_viewport = viewport
	_schedule_viewport_binding()


func set_opacity(opacity: float) -> void:
	_opacity = clampf(opacity, 0.0, 1.0)
	_update_runtime_opacity()


func _schedule_viewport_binding() -> void:
	if not is_node_ready() or _viewport == null or _is_bind_scheduled:
		return
	_viewport.use_hdr_2d = true
	_is_bind_scheduled = true
	call_deferred(&"_bind_viewport_texture")


func _bind_viewport_texture() -> void:
	_is_bind_scheduled = false
	if not is_instance_valid(_viewport):
		return

	var viewport_texture := _viewport.get_texture()
	_runtime_material = _create_runtime_material(viewport_texture)
	material_override = _runtime_material
	visible = true


func _update_runtime_blend_balance() -> void:
	if is_instance_valid(_runtime_material):
		_runtime_material.set_shader_parameter(BLEND_BALANCE_PARAMETER, blend_balance)


func _update_runtime_intensity() -> void:
	if is_instance_valid(_runtime_material):
		_runtime_material.set_shader_parameter(INTENSITY_PARAMETER, intensity)


func _update_runtime_opacity() -> void:
	if is_instance_valid(_runtime_material):
		_runtime_material.set_shader_parameter(OPACITY_PARAMETER, _opacity)


func _create_runtime_material(viewport_texture: Texture2D) -> ShaderMaterial:
	var runtime_material := ShaderMaterial.new()
	runtime_material.resource_local_to_scene = true
	runtime_material.shader = SURFACE_SHADER
	runtime_material.set_shader_parameter(VIEWPORT_TEXTURE_PARAMETER, viewport_texture)
	runtime_material.set_shader_parameter(BLEND_BALANCE_PARAMETER, blend_balance)
	runtime_material.set_shader_parameter(INTENSITY_PARAMETER, intensity)
	runtime_material.set_shader_parameter(OPACITY_PARAMETER, _opacity)
	return runtime_material
