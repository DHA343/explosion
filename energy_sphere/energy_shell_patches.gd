extends Node3D

@onready var _patch_anchor: Node3D = $PatchAnchor


func _ready() -> void:
	_place_patch_randomly()


func _place_patch_randomly() -> void:
	var surface_direction := _random_sphere_direction()
	var roll := randf_range(0.0, TAU)
	var alignment_rotation := Quaternion(Vector3.UP, surface_direction)
	var roll_rotation := Quaternion(Vector3.UP, roll)
	_patch_anchor.quaternion = alignment_rotation * roll_rotation


func _random_sphere_direction() -> Vector3:
	var y := randf_range(-1.0, 1.0)
	var azimuth := randf_range(0.0, TAU)
	var horizontal_radius := sqrt(max(0.0, 1.0 - y * y))
	return Vector3(horizontal_radius * cos(azimuth), y, horizontal_radius * sin(azimuth))
