extends Camera3D

@export_group("Movement")
@export_range(0.1, 100.0, 0.1, "suffix:m/s") var move_speed: float = 8.0
@export_range(1.0, 10.0, 0.1) var boost_multiplier: float = 3.0
@export_range(0.01, 1.0, 0.01) var precision_multiplier: float = 0.25
@export_range(0.0001, 0.02, 0.0001) var look_sensitivity: float = 0.002
@export_range(30.0, 89.0, 0.1, "suffix:°") var pitch_limit_deg: float = 85.0

var _view_yaw: float
var _view_pitch: float


func _ready() -> void:
	_sync_view_angles_from_rotation()
	if DisplayServer.get_name() == "headless":
		set_process(false)
		set_process_unhandled_input(false)
		return

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
			_cancel_mouse_navigation()
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if (
			mouse_event.pressed
			and mouse_event.button_index == MOUSE_BUTTON_LEFT
			and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED
		):
			_capture_first_person_mouse()
			get_viewport().set_input_as_handled()
			return
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			move_speed = minf(move_speed * 1.25, 100.0)
			get_viewport().set_input_as_handled()
			return
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			move_speed = maxf(move_speed / 1.25, 0.1)
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion_event := event as InputEventMouseMotion
		_free_look(motion_event.relative)
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	var input_2d := Vector2(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_W)) - float(Input.is_key_pressed(KEY_S))
	)
	var forward := -global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := global_basis.x
	right.y = 0.0
	right = right.normalized()
	var movement := right * input_2d.x + forward * input_2d.y
	if movement.is_zero_approx():
		return

	var current_speed := move_speed
	if Input.is_key_pressed(KEY_SHIFT):
		current_speed *= boost_multiplier
	if Input.is_key_pressed(KEY_ALT):
		current_speed *= precision_multiplier
	global_position += movement.normalized() * current_speed * delta


func _capture_first_person_mouse() -> void:
	_sync_view_angles_from_rotation()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _sync_view_angles_from_rotation() -> void:
	_view_yaw = global_rotation.y
	_view_pitch = global_rotation.x


func _free_look(relative: Vector2) -> void:
	_view_yaw -= relative.x * look_sensitivity
	_view_pitch -= relative.y * look_sensitivity
	var pitch_limit := deg_to_rad(pitch_limit_deg)
	_view_pitch = clampf(_view_pitch, -pitch_limit, pitch_limit)
	global_rotation = Vector3(_view_pitch, _view_yaw, 0.0)


func _cancel_mouse_navigation() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
