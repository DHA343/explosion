class_name MagicCircleSurface3D
extends MeshInstance3D

## SubViewportの描画結果を3D空間へ表示する魔法陣用Surface。

const BLEND_BALANCE_PARAMETER := &"blend_balance"
const INTENSITY_PARAMETER := &"intensity"
const OPACITY_PARAMETER := &"opacity"
const ADD_SHADER: Shader = preload("res://magic_circle/3d/magic_circle_surface_add_3d.gdshader")
const MIX_SHADER: Shader = preload("res://magic_circle/3d/magic_circle_surface_3d.gdshader")
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
var _runtime_add_material: ShaderMaterial
var _runtime_mix_material: ShaderMaterial
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
	_runtime_mix_material = _create_runtime_material(MIX_SHADER, viewport_texture)
	_runtime_add_material = _create_runtime_material(ADD_SHADER, viewport_texture)
	_runtime_mix_material.next_pass = _runtime_add_material
	material_override = _runtime_mix_material
	visible = true


func _update_runtime_blend_balance() -> void:
	if is_instance_valid(_runtime_mix_material):
		_runtime_mix_material.set_shader_parameter(BLEND_BALANCE_PARAMETER, blend_balance)
	if is_instance_valid(_runtime_add_material):
		_runtime_add_material.set_shader_parameter(BLEND_BALANCE_PARAMETER, blend_balance)


func _update_runtime_intensity() -> void:
	if is_instance_valid(_runtime_mix_material):
		_runtime_mix_material.set_shader_parameter(INTENSITY_PARAMETER, intensity)
	if is_instance_valid(_runtime_add_material):
		_runtime_add_material.set_shader_parameter(INTENSITY_PARAMETER, intensity)


func _update_runtime_opacity() -> void:
	if is_instance_valid(_runtime_mix_material):
		_runtime_mix_material.set_shader_parameter(OPACITY_PARAMETER, _opacity)
	if is_instance_valid(_runtime_add_material):
		_runtime_add_material.set_shader_parameter(OPACITY_PARAMETER, _opacity)


func _create_runtime_material(shader: Shader, viewport_texture: Texture2D) -> ShaderMaterial:
	var runtime_material := ShaderMaterial.new()
	runtime_material.resource_local_to_scene = true
	runtime_material.shader = shader
	runtime_material.set_shader_parameter(VIEWPORT_TEXTURE_PARAMETER, viewport_texture)
	runtime_material.set_shader_parameter(BLEND_BALANCE_PARAMETER, blend_balance)
	runtime_material.set_shader_parameter(INTENSITY_PARAMETER, intensity)
	runtime_material.set_shader_parameter(OPACITY_PARAMETER, _opacity)
	return runtime_material
