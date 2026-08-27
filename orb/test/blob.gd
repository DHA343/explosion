class_name Blob
extends Node3D

enum State {
	TRAVELING,
	DEFORMING,
	ATTACHED,
	FADING,
}

var sphere_center := Vector3.ZERO
var sphere_radius := 3.0
var blob_radius := 0.05
var move_speed := 2.0
var deform_duration := 0.4
var attached_duration := 2.0
var fade_duration := 0.8
var final_radial_scale := 0.25
var final_tangent_scale := 1.6
var contact_range := 0.6
var contact_softness := 0.25
var adhesion_range := 0.4
var adhesion_softness := 0.25
var noise_strength := 0.06
var noise_frequency := 1.5
var min_tangent_aspect := 0.85
var max_tangent_aspect := 1.15
var blob_color := Color.WHITE
var emission_intensity := 3.0
var direction := Vector3.FORWARD

@onready var mesh: MeshInstance3D = $Mesh

var distance := 0.0
var deform_time := 0.0
var attached_time := 0.0
var fade_time := 0.0
var state := State.TRAVELING


func _ready() -> void:
	direction = direction.normalized()
	mesh.scale = Vector3.ONE * blob_radius

	var material := mesh.material_override as ShaderMaterial
	mesh.material_override = material.duplicate() as ShaderMaterial
	material = mesh.material_override as ShaderMaterial
	material.set_shader_parameter("sphere_center_world", sphere_center)
	material.set_shader_parameter("sphere_radius", sphere_radius)
	material.set_shader_parameter("blob_radius", blob_radius)
	material.set_shader_parameter("final_radial_scale", final_radial_scale)
	material.set_shader_parameter("final_tangent_scale", final_tangent_scale)
	material.set_shader_parameter("contact_range", contact_range)
	material.set_shader_parameter("contact_softness", contact_softness)
	material.set_shader_parameter("adhesion_range", adhesion_range)
	material.set_shader_parameter("adhesion_softness", adhesion_softness)
	material.set_shader_parameter("blob_color", blob_color)
	material.set_shader_parameter("emission_intensity", emission_intensity)
	material.set_shader_parameter("fade", 1.0)
	_randomize_appearance(material)


func _process(delta: float) -> void:
	match state:
		State.TRAVELING:
			_travel(delta)
		State.DEFORMING:
			_deform(delta)
		State.ATTACHED:
			_hold(delta)
		State.FADING:
			_fade(delta)

	mesh.position = direction * distance


func _travel(delta: float) -> void:
	distance += move_speed * delta

	var contact_distance := sphere_radius - blob_radius

	if distance >= contact_distance:
		distance = contact_distance
		state = State.DEFORMING


func _deform(delta: float) -> void:
	deform_time += delta

	var deform := clampf(deform_time / deform_duration, 0.0, 1.0)
	var radial_scale := lerpf(1.0, final_radial_scale, deform)
	distance = sphere_radius - blob_radius * radial_scale

	var material := mesh.material_override as ShaderMaterial
	material.set_shader_parameter("deform", deform)

	if deform >= 1.0:
		state = State.ATTACHED


func _hold(delta: float) -> void:
	attached_time += delta

	if attached_time >= attached_duration:
		state = State.FADING


func _fade(delta: float) -> void:
	fade_time += delta

	var fade_progress := clampf(fade_time / fade_duration, 0.0, 1.0)
	var smooth_fade := fade_progress * fade_progress * (3.0 - 2.0 * fade_progress)
	var material := mesh.material_override as ShaderMaterial
	material.set_shader_parameter("fade", 1.0 - smooth_fade)

	if fade_progress >= 1.0:
		queue_free()


func _randomize_appearance(material: ShaderMaterial) -> void:
	material.set_shader_parameter("noise_strength", noise_strength)
	material.set_shader_parameter("noise_frequency", noise_frequency)
	material.set_shader_parameter(
		"noise_seed",
		Vector3(randf_range(0.0, 100.0), randf_range(0.0, 100.0), randf_range(0.0, 100.0))
	)
	material.set_shader_parameter(
		"tangent_aspect",
		randf_range(min_tangent_aspect, max_tangent_aspect)
	)
	material.set_shader_parameter("tangent_rotation", randf_range(0.0, TAU))
