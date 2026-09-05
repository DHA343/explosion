class_name RadialEnergyInstances
extends MultiMeshInstance3D

const MIN_LENGTH := 0.001
const MIN_THICKNESS := 0.001
const PEAK_POSITION_RATIO_PARAMETER := &"peak_position_ratio"
const ROUNDNESS_POWER_PARAMETER := &"roundness_power"
const DECELERATION_POWER_PARAMETER := &"deceleration_power"
const LENGTH_SHRINK_START_RATIO_PARAMETER := &"length_shrink_start_ratio"
const LENGTH_SHRINK_POWER_PARAMETER := &"length_shrink_power"
const THICKNESS_SHRINK_START_RATIO_PARAMETER := &"thickness_shrink_start_ratio"
const THICKNESS_SHRINK_POWER_PARAMETER := &"thickness_shrink_power"
const FADE_START_RATIO_PARAMETER := &"fade_start_ratio"
const FADE_POWER_PARAMETER := &"fade_power"


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


func set_lifecycle(
	deceleration_power: float, length_shrink_start_ratio: float,
	length_shrink_power: float, thickness_shrink_start_ratio: float,
	thickness_shrink_power: float, fade_start_ratio: float, fade_power: float
) -> void:
	set_instance_shader_parameter(DECELERATION_POWER_PARAMETER, deceleration_power)
	set_instance_shader_parameter(
		LENGTH_SHRINK_START_RATIO_PARAMETER, length_shrink_start_ratio
	)
	set_instance_shader_parameter(LENGTH_SHRINK_POWER_PARAMETER, length_shrink_power)
	set_instance_shader_parameter(
		THICKNESS_SHRINK_START_RATIO_PARAMETER, thickness_shrink_start_ratio
	)
	set_instance_shader_parameter(THICKNESS_SHRINK_POWER_PARAMETER, thickness_shrink_power)
	set_instance_shader_parameter(FADE_START_RATIO_PARAMETER, fade_start_ratio)
	set_instance_shader_parameter(FADE_POWER_PARAMETER, fade_power)


func update_dynamic_data(
	instance_data: Array[RadialEnergyInstance], length: float, length_variation: float,
	thickness: float, thickness_variation: float
) -> void:
	for instance_index in range(instance_data.size()):
		multimesh.set_instance_custom_data(
			instance_index,
			_custom_data_for(
				instance_data[instance_index], length, length_variation,
				thickness, thickness_variation
			)
		)


func _transform_for(data: RadialEnergyInstance) -> Transform3D:
	var direction := data.direction.normalized()
	var reference := Vector3.FORWARD
	if absf(direction.dot(reference)) > 0.95:
		reference = Vector3.RIGHT
	var axis_x := reference.cross(direction).normalized()
	var axis_z := axis_x.cross(direction).normalized()
	return Transform3D(Basis(axis_x, direction * data.travel_radius, axis_z), Vector3.ZERO)


func _custom_data_for(
	data: RadialEnergyInstance, length: float, length_variation: float,
	thickness: float, thickness_variation: float
) -> Color:
	return Color(
		data.lifecycle_progress(),
		_thickness_for(data, thickness, thickness_variation),
		data.brightness,
		_length_for(data, length, length_variation)
	)


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
