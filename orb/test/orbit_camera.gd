extends Node3D

@export var sensitivity := 0.005
@export_range(-89.0, 0.0, 0.1) var min_pitch := -89.0
@export_range(0.0, 89.0, 0.1) var max_pitch := 89.0

var dragging := false
var yaw := 0.0
var pitch := 0.0


func _ready() -> void:
	global_position = Vector3.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed

	if event is InputEventMouseMotion and dragging:
		yaw -= event.relative.x * sensitivity
		pitch -= event.relative.y * sensitivity

		pitch = clamp(
			pitch,
			deg_to_rad(min_pitch),
			deg_to_rad(max_pitch)
		)

		rotation = Vector3(pitch, yaw, 0.0)
