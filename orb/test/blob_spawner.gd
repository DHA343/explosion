class_name BlobSpawner
extends Node3D

@export var blob_scene: PackedScene
@export_range(0.02, 1.0, 0.01, "suffix:s") var spawn_interval := 0.08
@export_range(1, 100, 1) var max_active_blobs := 50
@export_range(0.1, 5.0, 0.1) var sphere_radius := 0.5
@export_range(0.01, 0.2, 0.005) var min_blob_radius := 0.025
@export_range(0.01, 0.2, 0.005) var max_blob_radius := 0.045
@export_range(0.05, 8.0, 0.05) var min_move_speed := 0.25
@export_range(0.05, 8.0, 0.05) var max_move_speed := 0.35
@export_range(0.1, 2.0, 0.05, "suffix:s") var min_deform_duration := 0.4
@export_range(0.1, 2.0, 0.05, "suffix:s") var max_deform_duration := 0.5
@export_range(0.1, 10.0, 0.1, "suffix:s") var attached_duration := 1.3
@export_range(0.1, 5.0, 0.1, "suffix:s") var fade_duration := 0.7
@export_range(0.1, 0.8, 0.05) var min_radial_scale := 0.25
@export_range(0.1, 0.8, 0.05) var max_radial_scale := 0.4
@export_range(1.0, 2.5, 0.1) var min_tangent_scale := 1.3
@export_range(1.0, 2.5, 0.1) var max_tangent_scale := 1.7
@export_range(0.0, 2.0, 0.01) var contact_range := 0.6
@export_range(0.01, 1.0, 0.01) var contact_softness := 0.25
@export_range(0.0, 2.0, 0.01) var adhesion_range := 0.4
@export_range(0.01, 1.0, 0.01) var adhesion_softness := 0.25
@export_range(0.0, 0.2, 0.01) var noise_strength := 0.05
@export_range(0.5, 3.0, 0.1) var noise_frequency := 1.3
@export_range(0.75, 1.0, 0.01) var min_tangent_aspect := 0.85
@export_range(1.0, 1.3, 0.01) var max_tangent_aspect := 1.15
@export_color_no_alpha var blob_color := Color.WHITE
@export_range(0.0, 8.0, 0.1) var emission_intensity := 1.8

var spawn_elapsed := 0.0


func _ready() -> void:
	_spawn_blob()


func _process(delta: float) -> void:
	spawn_elapsed += delta

	while spawn_elapsed >= spawn_interval:
		spawn_elapsed -= spawn_interval
		_spawn_blob()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_spawn_blob()


func _spawn_blob() -> void:
	if get_child_count() >= max_active_blobs:
		return

	var blob := blob_scene.instantiate() as Blob
	blob.sphere_center = global_position
	blob.sphere_radius = sphere_radius
	blob.blob_radius = randf_range(min_blob_radius, max_blob_radius)
	blob.move_speed = randf_range(min_move_speed, max_move_speed)
	blob.deform_duration = randf_range(min_deform_duration, max_deform_duration)
	blob.attached_duration = attached_duration
	blob.fade_duration = fade_duration
	blob.final_radial_scale = randf_range(min_radial_scale, max_radial_scale)
	blob.final_tangent_scale = randf_range(min_tangent_scale, max_tangent_scale)
	blob.contact_range = contact_range
	blob.contact_softness = contact_softness
	blob.adhesion_range = adhesion_range
	blob.adhesion_softness = adhesion_softness
	blob.noise_strength = noise_strength
	blob.noise_frequency = noise_frequency
	blob.min_tangent_aspect = min_tangent_aspect
	blob.max_tangent_aspect = max_tangent_aspect
	blob.blob_color = blob_color
	blob.emission_intensity = emission_intensity
	blob.direction = _random_direction()
	add_child(blob)


func _random_direction() -> Vector3:
	var vertical := randf_range(-1.0, 1.0)
	var angle := randf_range(0.0, TAU)
	var horizontal := sqrt(1.0 - vertical * vertical)
	return Vector3(cos(angle) * horizontal, vertical, sin(angle) * horizontal)
