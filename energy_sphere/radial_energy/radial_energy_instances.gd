class_name RadialEnergyInstances
extends MultiMeshInstance3D

const MIN_LENGTH := 0.001
const MIN_THICKNESS := 0.001
const PEAK_POSITION_RATIO_PARAMETER := &"peak_position_ratio"
const PEAK_END_POSITION_RATIO_PARAMETER := &"peak_end_position_ratio"
const ROUNDNESS_POWER_PARAMETER := &"roundness_power"
const COLLISION_DEFORMATION_PARAMETER := &"collision_deformation"
const LENGTH_END_SCALE_PARAMETER := &"length_end_scale"
const LENGTH_CHANGE_POWER_PARAMETER := &"length_change_power"
const THICKNESS_END_SCALE_PARAMETER := &"thickness_end_scale"
const THICKNESS_CHANGE_POWER_PARAMETER := &"thickness_change_power"
const FADE_POWER_PARAMETER := &"fade_power"

var _is_collision: bool = false
var _movement_power: float = 1.0
var _fade_duration: float = 0.0


func synchronize(
	instance_data: Array[RadialEnergyInstance], bounds_radius: float, length: float,
	length_variation: float, thickness: float, thickness_variation: float
) -> void:
	assert(multimesh != null, "Instances requires a MultiMesh resource.")
	if multimesh.instance_count != instance_data.size():
		multimesh.instance_count = instance_data.size()

	multimesh.custom_aabb = AABB(
		Vector3(-bounds_radius, -bounds_radius, -bounds_radius),
		Vector3(bounds_radius * 2.0, bounds_radius * 2.0, bounds_radius * 2.0)
	)
	for instance_index in range(instance_data.size()):
		update_instance_layout(instance_data[instance_index], instance_index)
	update_dynamic_data(
		instance_data, length, length_variation, thickness, thickness_variation
	)


func update_instance_layout(data: RadialEnergyInstance, instance_index: int) -> void:
	multimesh.set_instance_transform(instance_index, _transform_for(data))


func set_shape(peak_position_ratio: float, roundness_power: float) -> void:
	set_instance_shader_parameter(PEAK_POSITION_RATIO_PARAMETER, peak_position_ratio)
	set_instance_shader_parameter(ROUNDNESS_POWER_PARAMETER, roundness_power)


func set_collision_profile(profile: RadialEnergyCollisionProfile) -> void:
	_is_collision = true
	_movement_power = profile.movement_power
	_fade_duration = profile.fade_duration
	set_instance_shader_parameter(
		PEAK_END_POSITION_RATIO_PARAMETER, profile.peak_end_position_ratio
	)
	_set_deformation(
		true, profile.length_end_scale, profile.length_change_power,
		profile.thickness_end_scale, profile.thickness_change_power, profile.fade_power
	)


func set_miss_profile(profile: RadialEnergyMissProfile) -> void:
	_is_collision = false
	_movement_power = profile.movement_power
	_fade_duration = profile.fade_duration
	_set_deformation(
		false, profile.length_end_scale,
		profile.length_change_power, profile.thickness_end_scale,
		profile.thickness_change_power, profile.fade_power
	)


func update_dynamic_data(
	instance_data: Array[RadialEnergyInstance], length: float, length_variation: float,
	thickness: float, thickness_variation: float
) -> void:
	for instance_index in range(instance_data.size()):
		var data := instance_data[instance_index]
		multimesh.set_instance_custom_data(
			instance_index,
			_custom_data_for(
				data, length, length_variation,
				thickness, thickness_variation
			)
		)
		multimesh.set_instance_color(
			instance_index,
			Color(data.brightness, 1.0, 1.0, _fade_progress_for(data))
		)


func _transform_for(data: RadialEnergyInstance) -> Transform3D:
	var direction := data.direction.normalized()
	var reference := Vector3.FORWARD
	if absf(direction.dot(reference)) > 0.95:
		reference = Vector3.RIGHT
	var axis_x := reference.cross(direction).normalized()
	var axis_z := axis_x.cross(direction).normalized()
	return Transform3D(Basis(axis_x, direction * data.travel_radius, axis_z), Vector3.ZERO)


func _set_deformation(
	collision_deformation: bool, length_end_scale: float, length_change_power: float,
	thickness_end_scale: float, thickness_change_power: float, fade_power: float
) -> void:
	set_instance_shader_parameter(COLLISION_DEFORMATION_PARAMETER, collision_deformation)
	set_instance_shader_parameter(LENGTH_END_SCALE_PARAMETER, length_end_scale)
	set_instance_shader_parameter(LENGTH_CHANGE_POWER_PARAMETER, length_change_power)
	set_instance_shader_parameter(THICKNESS_END_SCALE_PARAMETER, thickness_end_scale)
	set_instance_shader_parameter(
		THICKNESS_CHANGE_POWER_PARAMETER, thickness_change_power
	)
	set_instance_shader_parameter(FADE_POWER_PARAMETER, fade_power)


func _custom_data_for(
	data: RadialEnergyInstance, length: float, length_variation: float,
	thickness: float, thickness_variation: float
) -> Color:
	var travel_progress := data.travel_progress()
	var movement_progress := 1.0 - pow(1.0 - travel_progress, _movement_power)
	var deformation_progress := data.response_progress()
	if not _is_collision:
		deformation_progress = data.travel_ending_progress(_fade_duration)
	return Color(
		movement_progress,
		deformation_progress,
		_thickness_for(data, thickness, thickness_variation),
		_length_for(data, length, length_variation)
	)


func _fade_progress_for(data: RadialEnergyInstance) -> float:
	if _is_collision:
		return data.impact_fade_progress(_fade_duration)
	return data.travel_ending_progress(_fade_duration)


func _length_for(
	data: RadialEnergyInstance, length: float, length_variation: float
) -> float:
	var minimum := maxf(length - length_variation, MIN_LENGTH)
	return lerpf(
		minimum,
		length + length_variation,
		(data.length_random_factor + 1.0) * 0.5
	)


func _thickness_for(
	data: RadialEnergyInstance, thickness: float, thickness_variation: float
) -> float:
	var minimum := maxf(thickness - thickness_variation, MIN_THICKNESS)
	return lerpf(
		minimum,
		thickness + thickness_variation,
		(data.thickness_random_factor + 1.0) * 0.5
	)
