extends Node3D

@onready var _magic_circle: MagicCircle3D = $MagicCircle3D


func _input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or not mouse_event.pressed:
		return
	if mouse_event.button_index == MOUSE_BUTTON_LEFT and not _magic_circle.is_spawn_playing():
		_magic_circle.play_spawn()
