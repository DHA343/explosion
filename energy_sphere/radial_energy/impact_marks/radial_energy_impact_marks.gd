@tool
class_name RadialEnergyImpactMarks
extends MultiMeshInstance3D

const SURFACE_RADIUS_PARAMETER := &"surface_radius"
const OPACITY_PARAMETER := &"opacity"
const SOFTNESS_PARAMETER := &"softness"

var _size_multiplier: float = 1.0


func synchronize(
	instance_data: Array[RadialEnergyInstance], bounds_radius: float,
	surface_radius: float, sphere_radius: float
) -> void:
	assert(multimesh != null, "RadialEnergyImpactMarks requires a MultiMesh resource.")
	if multimesh.instance_count != instance_data.size():
		multimesh.instance_count = instance_data.size()

	multimesh.custom_aabb = AABB(
		Vector3(-bounds_radius, -bounds_radius, -bounds_radius),
		Vector3.ONE * bounds_radius * 2.0
	)
	set_surface_radius(surface_radius)
	for instance_index in range(instance_data.size()):
		update_instance_layout(instance_data[instance_index], instance_index)
	update_dynamic_data(instance_data, sphere_radius)


func update_instance_layout(data: RadialEnergyInstance, instance_index: int) -> void:
	multimesh.set_instance_transform(
		instance_index, Transform3D(data.orientation, Vector3.ZERO)
	)


func update_dynamic_data(
	instance_data: Array[RadialEnergyInstance], sphere_radius: float
) -> void:
	for instance_index in range(instance_data.size()):
		var data := instance_data[instance_index]
		multimesh.set_instance_custom_data(
			instance_index,
			Color(
				data.thickness_ratio * sphere_radius * _size_multiplier,
				data.impact_progress(),
				data.fade_progress(),
				0.0
			)
		)


func set_surface_radius(value: float) -> void:
	set_instance_shader_parameter(SURFACE_RADIUS_PARAMETER, value)


func set_style(size_multiplier: float, opacity: float, softness: float) -> void:
	_size_multiplier = size_multiplier
	set_instance_shader_parameter(OPACITY_PARAMETER, opacity)
	set_instance_shader_parameter(SOFTNESS_PARAMETER, softness)
