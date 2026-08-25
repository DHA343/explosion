extends Camera3D

## 1: Godotエディタ風、2: 一人称風の2種類を切り替えるカメラ。

enum CameraMode {
	EDITOR,
	FIRST_PERSON,
}

const FIRST_PERSON_CAMERA_HEIGHT := 1.6

@export_group("Mode")
@export_enum("Editor", "First Person") var start_mode: int = CameraMode.EDITOR

@export_group("Orbit")
@export_range(0.0001, 0.02, 0.0001) var orbit_sensitivity: float = 0.005
@export_range(0.0001, 0.02, 0.0001) var pan_sensitivity: float = 0.0015
@export_range(0.001, 0.05, 0.001) var drag_zoom_sensitivity: float = 0.01
@export_range(0.1, 0.99, 0.01) var wheel_zoom_factor: float = 0.85
@export_range(0.1, 10.0, 0.1, "suffix:m") var minimum_orbit_distance: float = 0.5
@export_range(10.0, 5000.0, 1.0, "suffix:m") var maximum_orbit_distance: float = 1000.0
@export_range(30.0, 89.0, 0.1, "suffix:°") var orbit_pitch_limit_deg: float = 85.0
@export var focus_point: Vector3 = Vector3.ZERO

@export_group("Movement")
@export_range(0.1, 100.0, 0.1, "suffix:m/s") var move_speed: float = 8.0
@export_range(1.0, 10.0, 0.1) var boost_multiplier: float = 3.0
@export_range(0.01, 1.0, 0.01) var precision_multiplier: float = 0.25
@export_range(0.0001, 0.02, 0.0001) var look_sensitivity: float = 0.002

var _camera_mode: CameraMode = CameraMode.EDITOR
var _orbit_focus: Vector3
var _orbit_distance: float
var _orbit_yaw: float
var _orbit_pitch: float
var _view_yaw: float
var _view_pitch: float
var _middle_dragging := false
var _right_dragging := false


func _ready() -> void:
	_initialize_orbit_from_view()
	_camera_mode = start_mode as CameraMode
	if DisplayServer.get_name() == "headless":
		set_process(false)
		set_process_unhandled_input(false)
		return
	_apply_camera_mode(false)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			_set_camera_mode(CameraMode.EDITOR)
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_2:
			_set_camera_mode(CameraMode.FIRST_PERSON)
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_ESCAPE:
			_cancel_mouse_navigation()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_F and _camera_mode == CameraMode.EDITOR and not _right_dragging:
			_focus_on_primary_point()
			get_viewport().set_input_as_handled()
			return

	if _camera_mode == CameraMode.FIRST_PERSON:
		_handle_first_person_input(event)
	else:
		_handle_editor_input(event)


func _handle_first_person_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_capture_first_person_mouse()
			get_viewport().set_input_as_handled()
			return
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			move_speed = minf(move_speed * 1.25, 100.0)
			get_viewport().set_input_as_handled()
			return
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			move_speed = maxf(move_speed / 1.25, 0.1)
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_free_look(event.relative)
		get_viewport().set_input_as_handled()


func _handle_editor_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			_middle_dragging = event.pressed
			get_viewport().set_input_as_handled()
			return

		if event.button_index == MOUSE_BUTTON_RIGHT:
			_set_editor_free_look_active(event.pressed)
			get_viewport().set_input_as_handled()
			return

		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if _right_dragging:
				move_speed = minf(move_speed * 1.25, 100.0)
			else:
				_zoom_orbit(wheel_zoom_factor)
			get_viewport().set_input_as_handled()
			return

		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if _right_dragging:
				move_speed = maxf(move_speed / 1.25, 0.1)
			else:
				_zoom_orbit(1.0 / wheel_zoom_factor)
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseMotion:
		if _right_dragging:
			_free_look(event.relative)
			get_viewport().set_input_as_handled()
			return

		if _middle_dragging:
			if event.ctrl_pressed:
				_zoom_orbit(exp(event.relative.y * drag_zoom_sensitivity))
			elif event.shift_pressed:
				_pan_orbit(event.relative)
			else:
				_rotate_orbit(event.relative)
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	var first_person_active := (
		_camera_mode == CameraMode.FIRST_PERSON
		and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	)
	if not first_person_active and not _right_dragging:
		return

	var input_2d := Vector2(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_W)) - float(Input.is_key_pressed(KEY_S))
	)
	var movement: Vector3
	if first_person_active:
		var forward := -global_basis.z
		forward.y = 0.0
		forward = forward.normalized()
		var right := global_basis.x
		right.y = 0.0
		right = right.normalized()
		movement = right * input_2d.x + forward * input_2d.y
	else:
		var vertical_input := float(Input.is_key_pressed(KEY_E)) - float(Input.is_key_pressed(KEY_Q))
		movement = global_basis.x * input_2d.x - global_basis.z * input_2d.y
		movement += Vector3.UP * vertical_input

	if movement.is_zero_approx():
		return

	var current_speed := move_speed
	if Input.is_key_pressed(KEY_SHIFT):
		current_speed *= boost_multiplier
	if Input.is_key_pressed(KEY_ALT):
		current_speed *= precision_multiplier
	global_position += movement.normalized() * current_speed * delta


func _set_camera_mode(mode: CameraMode) -> void:
	if _camera_mode == mode:
		if mode == CameraMode.FIRST_PERSON:
			global_position.y = FIRST_PERSON_CAMERA_HEIGHT
			_capture_first_person_mouse()
		return
	_camera_mode = mode
	if mode == CameraMode.FIRST_PERSON:
		global_position.y = FIRST_PERSON_CAMERA_HEIGHT
	_apply_camera_mode(true)


func _apply_camera_mode(rebuild_orbit: bool) -> void:
	_middle_dragging = false
	_right_dragging = false
	if _camera_mode == CameraMode.FIRST_PERSON:
		_sync_view_angles_from_rotation()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if rebuild_orbit:
			_initialize_orbit_from_view()


func _capture_first_person_mouse() -> void:
	_sync_view_angles_from_rotation()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _initialize_orbit_from_view() -> void:
	var forward := -global_basis.z.normalized()
	var ground_intersection_distance := -1.0
	if absf(forward.y) > 0.0001:
		ground_intersection_distance = -global_position.y / forward.y

	if ground_intersection_distance > minimum_orbit_distance:
		_orbit_focus = global_position + forward * ground_intersection_distance
	else:
		_orbit_focus = focus_point
		if global_position.is_equal_approx(_orbit_focus):
			_orbit_focus = global_position + forward * 10.0

	_sync_orbit_from_focus()


func _sync_orbit_from_focus() -> void:
	var offset := global_position - _orbit_focus
	_orbit_distance = clampf(offset.length(), minimum_orbit_distance, maximum_orbit_distance)
	if offset.is_zero_approx():
		offset = Vector3.BACK * _orbit_distance
	_orbit_yaw = atan2(offset.x, offset.z)
	_orbit_pitch = asin(clampf(offset.y / _orbit_distance, -1.0, 1.0))


func _apply_orbit() -> void:
	var horizontal_scale := cos(_orbit_pitch)
	var offset_direction := Vector3(
		sin(_orbit_yaw) * horizontal_scale,
		sin(_orbit_pitch),
		cos(_orbit_yaw) * horizontal_scale
	)
	global_position = _orbit_focus + offset_direction * _orbit_distance
	look_at(_orbit_focus, Vector3.UP)


func _rotate_orbit(relative: Vector2) -> void:
	_orbit_yaw -= relative.x * orbit_sensitivity
	_orbit_pitch += relative.y * orbit_sensitivity
	var pitch_limit := deg_to_rad(orbit_pitch_limit_deg)
	_orbit_pitch = clampf(_orbit_pitch, -pitch_limit, pitch_limit)
	_apply_orbit()


func _pan_orbit(relative: Vector2) -> void:
	var world_per_pixel := maxf(_orbit_distance, minimum_orbit_distance) * pan_sensitivity
	var translation := (-global_basis.x * relative.x + global_basis.y * relative.y) * world_per_pixel
	_orbit_focus += translation
	global_position += translation


func _zoom_orbit(factor: float) -> void:
	_orbit_distance = clampf(
		_orbit_distance * factor,
		minimum_orbit_distance,
		maximum_orbit_distance
	)
	_apply_orbit()


func _set_editor_free_look_active(active: bool) -> void:
	_right_dragging = active
	_middle_dragging = false
	if active:
		_sync_view_angles_from_rotation()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_initialize_orbit_from_view()


func _sync_view_angles_from_rotation() -> void:
	_view_yaw = global_rotation.y
	_view_pitch = global_rotation.x


func _free_look(relative: Vector2) -> void:
	_view_yaw -= relative.x * look_sensitivity
	_view_pitch -= relative.y * look_sensitivity
	var pitch_limit := deg_to_rad(orbit_pitch_limit_deg)
	_view_pitch = clampf(_view_pitch, -pitch_limit, pitch_limit)
	global_rotation = Vector3(_view_pitch, _view_yaw, 0.0)


func _focus_on_primary_point() -> void:
	_orbit_focus = focus_point
	_orbit_distance = clampf(
		global_position.distance_to(_orbit_focus),
		minimum_orbit_distance,
		maximum_orbit_distance
	)
	_sync_orbit_from_focus()
	_apply_orbit()


func _cancel_mouse_navigation() -> void:
	_middle_dragging = false
	if _camera_mode == CameraMode.FIRST_PERSON:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif _right_dragging:
		_set_editor_free_look_active(false)
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
