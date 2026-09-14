extends Node3D

@onready var _camera: Camera3D = $OrbitCamera/Camera3D
@onready var _energy_sphere: EnergySphere = $EnergySphere


func _ready() -> void:
	_energy_sphere.setup(_camera)
