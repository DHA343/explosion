@tool
extends Node3D

@export_range(0.0, 1.0, 0.001) var preview_progress: float = 0.5:
	set(value):
		preview_progress = clampf(value, 0.0, 1.0)
		_update_preview()

@export var auto_preview: bool = false
@export_range(0.1, 2.0, 0.05) var preview_speed: float = 1.0

@onready var _cross_flare: CrossFlare = $CrossFlare


func _ready() -> void:
	_update_preview()


func _process(delta: float) -> void:
	if auto_preview:
		var duration := maxf(_cross_flare.duration, CrossFlare.MIN_DURATION)
		preview_progress = fmod(preview_progress + delta * preview_speed / duration, 1.0)

	_update_preview()


func _update_preview() -> void:
	if not is_instance_valid(_cross_flare):
		return

	_cross_flare.seek(_cross_flare.duration * preview_progress)
