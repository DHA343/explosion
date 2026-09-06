@tool
class_name InwardEnergyInstances
extends MultiMeshInstance3D

const PEAK_POSITION_RATIO_PARAMETER: StringName = &"peak_position_ratio"
const ROUNDNESS_POWER_PARAMETER: StringName = &"roundness_power"
const DESPAWN_RADIUS_RATIO_PARAMETER: StringName = &"despawn_radius_ratio"


func synchronize(
	instance_data: Array[InwardEnergyInstance], bounds_radius: float, sphere_radius: float
) -> void:
	assert(multimesh != null, "InwardEnergyInstances requires a MultiMesh resource.")
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
	data: InwardEnergyInstance, instance_index: int, sphere_radius: float
) -> void:
	var instance_basis := data.orientation
	instance_basis.y *= sphere_radius
	var spawn_position := data.direction * data.spawn_radius_ratio() * sphere_radius
	multimesh.set_instance_transform(
		instance_index, Transform3D(instance_basis, spawn_position)
	)


func update_dynamic_data(
	instance_data: Array[InwardEnergyInstance], sphere_radius: float
) -> void:
	for instance_index in range(instance_data.size()):
		var data := instance_data[instance_index]
		multimesh.set_instance_custom_data(
			instance_index,
			Color(
				data.movement_progress(),
				data.thickness_ratio * sphere_radius,
				data.length_ratio * sphere_radius,
				0.0
			)
		)
		multimesh.set_instance_color(instance_index, Color(1.0, 1.0, 1.0, 1.0))


func set_shape(peak_position_ratio: float, roundness_power: float) -> void:
	set_instance_shader_parameter(PEAK_POSITION_RATIO_PARAMETER, peak_position_ratio)
	set_instance_shader_parameter(ROUNDNESS_POWER_PARAMETER, roundness_power)


func set_layout(despawn_radius_ratio: float) -> void:
	set_instance_shader_parameter(DESPAWN_RADIUS_RATIO_PARAMETER, despawn_radius_ratio)
