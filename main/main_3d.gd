extends Node3D

@onready var _camera: Camera3D = $Camera3D
@onready var _magic_circle: MagicCircle3D = $MagicCircle3D
@onready var _energy_sphere: EnergySphere = $EnergySphere


func _ready() -> void:
	_energy_sphere.setup(_camera)
	_magic_circle.reset_spawn()


func _input(event: InputEvent) -> void:
	if event is not InputEventKey:
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	match key_event.keycode:
		KEY_1:
			if not _magic_circle.is_spawn_playing():
				_magic_circle.play_spawn()
		KEY_2:
			if not _energy_sphere.is_spawn_playing():
				_energy_sphere.play_spawn()
		KEY_DELETE:
			_magic_circle.reset_spawn()
			_energy_sphere.reset_spawn()
			get_viewport().set_input_as_handled()
