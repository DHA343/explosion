class_name EnergyMote
extends Node3D

enum State {
	TRAVELING,
	IMPACT,
	FADING,
}

const IMPACT_RADIAL_SCALE := 0.35

var sphere_center := Vector3.ZERO
var sphere_radius := 0.5
var size := 0.035
var initial_speed := 2.0
var deceleration_exponent := 1.5
var minimum_speed_ratio := 0.25
var impact_strength := 0.7
var impact_duration := 0.12
var fade_duration := 0.25
var color := Color.WHITE
var emission := 2.0
var direction := Vector3.FORWARD
var shape_seed := 0.0

@onready var mesh: MeshInstance3D = $Mesh

var distance := 0.0
var impact_time := 0.0
var fade_time := 0.0
var state := State.TRAVELING


func _ready() -> void:
	direction = direction.normalized()
	mesh.scale = Vector3.ONE * size
	mesh.position = direction * 0.0001

	var material := mesh.material_override as ShaderMaterial
	mesh.material_override = material.duplicate() as ShaderMaterial
	material = mesh.material_override as ShaderMaterial
	material.set_shader_parameter("impact_strength", impact_strength)
	material.set_shader_parameter("blob_color", color)
	material.set_shader_parameter("emission_intensity", emission)
	material.set_shader_parameter("shape_seed", shape_seed)
	material.set_shader_parameter("deform", 0.0)
	material.set_shader_parameter("fade", 1.0)
	_update_visual_orientation()


func _process(delta: float) -> void:
	match state:
		State.TRAVELING:
			_travel(delta)
		State.IMPACT:
			_impact(delta)
		State.FADING:
			_fade(delta)

	mesh.position = direction * distance
	_update_visual_orientation()


func _travel(delta: float) -> void:
	var contact_distance := sphere_radius - size
	var travel_progress := clampf(distance / contact_distance, 0.0, 1.0)
	var deceleration_progress := pow(travel_progress, deceleration_exponent)
	var speed_factor := lerpf(1.0, minimum_speed_ratio, deceleration_progress)
	var current_speed := initial_speed * speed_factor
	distance += current_speed * delta

	if distance >= contact_distance:
		distance = contact_distance
		state = State.IMPACT


func _impact(delta: float) -> void:
	impact_time += delta

	var impact_progress := clampf(impact_time / impact_duration, 0.0, 1.0)
	var ease_out_impact := 1.0 - pow(1.0 - impact_progress, 3.0)
	var radial_scale := lerpf(1.0, IMPACT_RADIAL_SCALE, impact_strength)
	distance = sphere_radius - size * lerpf(1.0, radial_scale, ease_out_impact)

	var material := mesh.material_override as ShaderMaterial
	material.set_shader_parameter("deform", ease_out_impact)
	_fade(delta)

	if impact_progress >= 1.0:
		state = State.FADING


func _fade(delta: float) -> void:
	fade_time += delta

	var fade_progress := clampf(fade_time / fade_duration, 0.0, 1.0)
	var smooth_fade := fade_progress * fade_progress * (3.0 - 2.0 * fade_progress)
	var material := mesh.material_override as ShaderMaterial
	material.set_shader_parameter("fade", 1.0 - smooth_fade)

	if fade_progress >= 1.0:
		queue_free()


func _update_visual_orientation() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

	mesh.look_at(camera.global_position)
	mesh.scale = Vector3.ONE * size

	var mesh_right := mesh.global_transform.basis.x.normalized()
	var mesh_up := mesh.global_transform.basis.y.normalized()
	var surface_normal := (mesh.global_position - sphere_center).normalized()
	var camera_direction := (camera.global_position - mesh.global_position).normalized()
	var projected_normal := surface_normal - camera_direction * surface_normal.dot(camera_direction)
	var impact_axis := Vector2.RIGHT
	var impact_visibility := clampf(projected_normal.length(), 0.0, 1.0)

	if projected_normal.length_squared() > 0.00000001:
		impact_axis = Vector2(projected_normal.dot(mesh_right), projected_normal.dot(mesh_up)).normalized()

	var material := mesh.material_override as ShaderMaterial
	material.set_shader_parameter("impact_axis", impact_axis)
	material.set_shader_parameter("impact_visibility", impact_visibility)
