@tool
extends Node

const REFRACTION_CAPTURE_PROCESS_PRIORITY: int = 100

@onready var _refraction_camera: Camera3D = $RefractionViewport/RefractionCamera


func _ready() -> void:
	process_priority = REFRACTION_CAPTURE_PROCESS_PRIORITY
	_sync_cameras()


func _process(_delta: float) -> void:
	_sync_cameras()


func _sync_cameras() -> void:
	var main_camera := get_viewport().get_camera_3d()
	if main_camera == null:
		return

	main_camera.set_cull_mask_value(2, false)

	_refraction_camera.global_transform = main_camera.global_transform
	_refraction_camera.projection = main_camera.projection
	_refraction_camera.fov = main_camera.fov
	_refraction_camera.size = main_camera.size
	_refraction_camera.near = main_camera.near
	_refraction_camera.far = main_camera.far
	_refraction_camera.keep_aspect = main_camera.keep_aspect
	_refraction_camera.frustum_offset = main_camera.frustum_offset
	_refraction_camera.h_offset = main_camera.h_offset
	_refraction_camera.v_offset = main_camera.v_offset
