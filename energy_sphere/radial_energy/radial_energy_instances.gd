@tool
class_name RadialEnergyInstances
extends MultiMeshInstance3D

const PEAK_POSITION_RATIO_PARAMETER := &"peak_position_ratio"
const PEAK_END_POSITION_RATIO_PARAMETER := &"peak_end_position_ratio"
const ROUNDNESS_POWER_PARAMETER := &"roundness_power"
const LENGTH_END_SCALE_PARAMETER := &"length_end_scale"
const LENGTH_CHANGE_POWER_PARAMETER := &"length_change_power"
const THICKNESS_END_SCALE_PARAMETER := &"thickness_end_scale"
const THICKNESS_CHANGE_POWER_PARAMETER := &"thickness_change_power"
const FADE_POWER_PARAMETER := &"fade_power"


func synchronize(
	instance_data: Array[RadialEnergyInstance], bounds_radius: float, sphere_radius: float
) -> void:
	assert(multimesh != null, "RadialEnergyInstances requires a MultiMesh resource.")
	if multimesh.instance_count != instance_data.size():
		multimesh.instance_count = instance_data.size()

	multimesh.custom_aabb = AABB(
		Vector3(-bounds_radius, -bounds_radius, -bounds_radius),
		Vector3.ONE * bounds_radius * 2.0
	)
	for instance_index in range(instance_data.size()):
		update_instance_layout(instance_data[instance_index], instance_index, sphere_radius)
	update_dynamic_data(instance_data, sphere_radius)


func update_instance_layout(
	data: RadialEnergyInstance, instance_index: int, sphere_radius: float
) -> void:
	var instance_basis := data.orientation
	instance_basis.y *= data.travel_radius_ratio * sphere_radius
	multimesh.set_instance_transform(
		instance_index, Transform3D(instance_basis, Vector3.ZERO)
	)


func update_dynamic_data(
	instance_data: Array[RadialEnergyInstance], sphere_radius: float
) -> void:
	for instance_index in range(instance_data.size()):
		var data := instance_data[instance_index]
		multimesh.set_instance_custom_data(
			instance_index,
			Color(
				data.movement_progress(),
				data.impact_progress(),
				data.thickness_ratio * sphere_radius,
				data.length_ratio * sphere_radius
			)
		)
		multimesh.set_instance_color(
			instance_index,
			Color(data.brightness, 1.0, 1.0, data.fade_progress())
		)


func set_shape(peak_position_ratio: float, roundness_power: float) -> void:
	set_instance_shader_parameter(PEAK_POSITION_RATIO_PARAMETER, peak_position_ratio)
	set_instance_shader_parameter(ROUNDNESS_POWER_PARAMETER, roundness_power)


func set_impact_style(
	length_end_scale: float, length_change_power: float,
	thickness_end_scale: float, thickness_change_power: float,
	peak_end_position_ratio: float, fade_power: float
) -> void:
	set_instance_shader_parameter(PEAK_END_POSITION_RATIO_PARAMETER, peak_end_position_ratio)
	set_instance_shader_parameter(LENGTH_END_SCALE_PARAMETER, length_end_scale)
	set_instance_shader_parameter(LENGTH_CHANGE_POWER_PARAMETER, length_change_power)
	set_instance_shader_parameter(THICKNESS_END_SCALE_PARAMETER, thickness_end_scale)
	set_instance_shader_parameter(
		THICKNESS_CHANGE_POWER_PARAMETER, thickness_change_power
	)
	set_instance_shader_parameter(FADE_POWER_PARAMETER, fade_power)
