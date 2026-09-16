class_name EnergySphereSpawnAnimator
extends Node

signal spawn_progress_changed(progress: float)
signal spawn_finished

@export_range(0.10, 5.00, 0.05, "suffix:s") var spawn_duration: float = 1.00
@export_range(0.25, 4.00, 0.05) var radius_growth_power: float = 2.00

var _elapsed: float = 0.0
var _playing: bool = false


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= spawn_duration:
		spawn_progress_changed.emit(1.0)
		_playing = false
		set_process(false)
		spawn_finished.emit()
		return

	spawn_progress_changed.emit(clampf(_elapsed / spawn_duration, 0.0, 1.0))


func play_spawn() -> void:
	_elapsed = 0.0
	_playing = true
	set_process(true)
	spawn_progress_changed.emit(0.0)


func reset_spawn() -> void:
	_elapsed = 0.0
	_playing = false
	set_process(false)
	spawn_progress_changed.emit(0.0)


func is_playing() -> bool:
	return _playing
