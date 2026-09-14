@tool
class_name DistortionCapture
extends Node

const DISTORTION_CAPTURE_PROCESS_PRIORITY: int = 100

var _source_camera: Camera3D
var _capture_environment: Environment

@onready var _distortion_camera: Camera3D = $DistortionViewport/DistortionCamera


func _ready() -> void:
	process_priority = DISTORTION_CAPTURE_PROCESS_PRIORITY
	set_process(false)


func _process(_delta: float) -> void:
	_sync_camera_properties()


func setup(source_camera: Camera3D) -> void:
	assert(source_camera != null, "DistortionCapture requires a source Camera3D.")
	_source_camera = source_camera
	_setup_capture_environment()
	_sync_camera_properties()
	set_process(true)


func _setup_capture_environment() -> void:
	var source_environment := _source_camera.environment
	var world := _source_camera.get_world_3d()

	if source_environment == null and world != null:
		source_environment = world.environment

	if source_environment == null and world != null:
		source_environment = world.fallback_environment

	if source_environment == null:
		_capture_environment = null
		_distortion_camera.environment = null
		return

	_capture_environment = source_environment.duplicate(true) as Environment
	_capture_environment.background_mode = Environment.BG_CLEAR_COLOR
	_capture_environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	_capture_environment.tonemap_exposure = 1.0
	_capture_environment.glow_enabled = false
	_capture_environment.fog_enabled = false
	_capture_environment.volumetric_fog_enabled = false
	_capture_environment.adjustment_enabled = false
	_distortion_camera.environment = _capture_environment


func _sync_camera_properties() -> void:
	if not is_instance_valid(_source_camera):
		set_process(false)
		return

	_distortion_camera.global_transform = _source_camera.global_transform
	_distortion_camera.projection = _source_camera.projection
	_distortion_camera.fov = _source_camera.fov
	_distortion_camera.size = _source_camera.size
	_distortion_camera.near = _source_camera.near
	_distortion_camera.far = _source_camera.far
	_distortion_camera.keep_aspect = _source_camera.keep_aspect
	_distortion_camera.frustum_offset = _source_camera.frustum_offset
	_distortion_camera.h_offset = _source_camera.h_offset
	_distortion_camera.v_offset = _source_camera.v_offset
