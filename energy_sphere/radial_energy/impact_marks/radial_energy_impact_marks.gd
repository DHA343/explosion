class_name RadialEnergyImpactMarks
extends MultiMeshInstance3D

const MIN_THICKNESS := 0.001
const SURFACE_RADIUS_PARAMETER := &"surface_radius"
const OPACITY_PARAMETER := &"opacity"
const SOFTNESS_PARAMETER := &"softness"

var _fade_duration: float = 0.0


func synchronize(
	instance_data: Array[RadialEnergyInstance], bounds_radius: float,
	surface_radius: float, thickness: float, thickness_variation: float,
	profile: RadialEnergyCollisionProfile
) -> void:
	assert(multimesh != null, "ImpactMarks requires a MultiMesh resource.")
	if multimesh.instance_count != instance_data.size():
		multimesh.instance_count = instance_data.size()

	multimesh.custom_aabb = AABB(
		Vector3(-bounds_radius, -bounds_radius, -bounds_radius),
		Vector3(bounds_radius * 2.0, bounds_radius * 2.0, bounds_radius * 2.0)
	)
	set_surface_radius(surface_radius)
	set_profile(profile)
	for instance_index in range(instance_data.size()):
		update_instance_layout(instance_data[instance_index], instance_index)
	update_dynamic_data(
		instance_data, thickness, thickness_variation, profile.impact_mark_size_multiplier
	)


func update_instance_layout(data: RadialEnergyInstance, instance_index: int) -> void:
	multimesh.set_instance_transform(instance_index, _transform_for(data.direction))


func update_dynamic_data(
	instance_data: Array[RadialEnergyInstance], thickness: float,
	thickness_variation: float, size_multiplier: float
) -> void:
	for instance_index in range(instance_data.size()):
		var data := instance_data[instance_index]
		multimesh.set_instance_custom_data(
			instance_index,
			Color(
				_thickness_for(data, thickness, thickness_variation) * size_multiplier,
				data.response_progress(),
				data.impact_fade_progress(_fade_duration),
				0.0
			)
		)


func set_surface_radius(value: float) -> void:
	set_instance_shader_parameter(SURFACE_RADIUS_PARAMETER, value)


func set_profile(profile: RadialEnergyCollisionProfile) -> void:
	_fade_duration = profile.fade_duration
	set_instance_shader_parameter(OPACITY_PARAMETER, profile.impact_mark_opacity)
	set_instance_shader_parameter(SOFTNESS_PARAMETER, profile.impact_mark_softness)


func _transform_for(direction: Vector3) -> Transform3D:
	var normalized_direction := direction.normalized()
	var reference := Vector3.FORWARD
	if absf(normalized_direction.dot(reference)) > 0.95:
		reference = Vector3.RIGHT
	var axis_x := reference.cross(normalized_direction).normalized()
	var axis_z := axis_x.cross(normalized_direction).normalized()
	return Transform3D(Basis(axis_x, normalized_direction, axis_z), Vector3.ZERO)


func _thickness_for(
	data: RadialEnergyInstance, thickness: float, thickness_variation: float
) -> float:
	var minimum := maxf(thickness - thickness_variation, MIN_THICKNESS)
	return lerpf(
		minimum,
		thickness + thickness_variation,
		(data.thickness_random_factor + 1.0) * 0.5
	)
