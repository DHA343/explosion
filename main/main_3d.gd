extends Node3D

@onready var _camera: Camera3D = $Camera3D
@onready var _magic_circle: MagicCircle3D = $MagicCircle3D
@onready var _energy_sphere: EnergySphere = $EnergySphere


func _ready() -> void:
	_energy_sphere.setup(_camera)
	_magic_circle.reset_spawn()


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_DELETE:
			_magic_circle.reset_spawn()
			_energy_sphere.reset_spawn()
			get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if not mouse_event.pressed:
			return
		if mouse_event.button_index == MOUSE_BUTTON_XBUTTON1 and not _magic_circle.is_spawn_playing():
			_magic_circle.play_spawn()
		elif mouse_event.button_index == MOUSE_BUTTON_XBUTTON2 and not _energy_sphere.is_spawn_playing():
			_energy_sphere.play_spawn()
