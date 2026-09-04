class_name RadialEnergyRays
extends MultiMeshInstance3D

var _thickness_ratios: PackedFloat32Array = PackedFloat32Array()


func synchronize(
	rays: Array[RadialEnergyRay], sphere_radius: float, thickness_scale: float,
	thickness_ratios: PackedFloat32Array
) -> void:
	assert(multimesh != null, "Rays requires a MultiMesh resource.")
	_thickness_ratios = thickness_ratios
	if multimesh.instance_count != rays.size():
		multimesh.instance_count = rays.size()

	multimesh.custom_aabb = AABB(
		Vector3(-sphere_radius, -sphere_radius, -sphere_radius),
		Vector3(sphere_radius * 2.0, sphere_radius * 2.0, sphere_radius * 2.0)
	)
	for ray_index in range(rays.size()):
		update_ray(rays[ray_index], ray_index, thickness_scale)


func update_ray(ray: RadialEnergyRay, ray_index: int, thickness_scale: float) -> void:
	multimesh.set_instance_transform(ray_index, _transform_for(ray))
	multimesh.set_instance_color(ray_index, Color(ray.brightness, 0.0, 0.0, 1.0))
	multimesh.set_instance_custom_data(ray_index, _custom_data_for(ray, thickness_scale))


func update_dynamic_data(rays: Array[RadialEnergyRay], thickness_scale: float) -> void:
	for ray_index in range(rays.size()):
		multimesh.set_instance_custom_data(
			ray_index, _custom_data_for(rays[ray_index], thickness_scale)
		)


func update_thickness(
	rays: Array[RadialEnergyRay], thickness_scale: float, thickness_ratios: PackedFloat32Array
) -> void:
	_thickness_ratios = thickness_ratios
	update_dynamic_data(rays, thickness_scale)


func _transform_for(ray: RadialEnergyRay) -> Transform3D:
	var direction := ray.direction.normalized()
	var reference := Vector3.FORWARD
	if absf(direction.dot(reference)) > 0.95:
		reference = Vector3.RIGHT
	var axis_x := reference.cross(direction).normalized()
	var axis_z := axis_x.cross(direction).normalized()
	return Transform3D(Basis(axis_x, direction * ray.max_length, axis_z), ray.start_position)


func _custom_data_for(ray: RadialEnergyRay, thickness_scale: float) -> Color:
	return Color(
		ray.length_progress(),
		_thickness_for(ray.thickness_class) * thickness_scale * ray.retract_thickness_scale(),
		ray.visibility(), ray.seed
	)


func _thickness_for(thickness_class: RadialEnergyRay.ThicknessClass) -> float:
	return _thickness_ratios[thickness_class]
