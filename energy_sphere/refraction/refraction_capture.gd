@tool
extends Node

const REFRACTION_CAPTURE_PROCESS_PRIORITY: int = 100

var _source_camera: Camera3D
var _capture_environment: Environment

@onready var _refraction_camera: Camera3D = $RefractionViewport/RefractionCamera


func _ready() -> void:
	process_priority = REFRACTION_CAPTURE_PROCESS_PRIORITY
	_sync_capture()


func _process(_delta: float) -> void:
	_sync_capture()


func _sync_capture() -> void:
	var main_camera := get_viewport().get_camera_3d()
	if main_camera == null:
		return

	if main_camera != _source_camera:
		_source_camera = main_camera
		_setup_capture_environment(main_camera)

	main_camera.set_cull_mask_value(2, false)

	_sync_camera_properties(main_camera)


func _setup_capture_environment(main_camera: Camera3D) -> void:
	var source_environment := main_camera.environment
	var world := main_camera.get_world_3d()

	if source_environment == null and world != null:
		source_environment = world.environment

	if source_environment == null and world != null:
		source_environment = world.fallback_environment

	if source_environment == null:
		_capture_environment = null
		_refraction_camera.environment = null
		return

	_capture_environment = source_environment.duplicate(true) as Environment
	_capture_environment.background_mode = Environment.BG_CLEAR_COLOR
	_capture_environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	_capture_environment.tonemap_exposure = 1.0
	_capture_environment.glow_enabled = false
	_capture_environment.fog_enabled = false
	_capture_environment.volumetric_fog_enabled = false
	_capture_environment.adjustment_enabled = false
	_refraction_camera.environment = _capture_environment


func _sync_camera_properties(main_camera: Camera3D) -> void:
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
