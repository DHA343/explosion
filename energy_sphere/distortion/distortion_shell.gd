@tool
class_name DistortionShell
extends MeshInstance3D

const PROJECTED_RADIUS_UV_PARAMETER: StringName = &"projected_radius_uv"
const MIN_VECTOR_LENGTH_SQUARED: float = 0.000001

var radius: float = 0.5:
	set(value):
		radius = value
		if is_node_ready():
			_update_projected_radius()

var _projected_radius_uv: float = 0.25


func _ready() -> void:
	_update_projected_radius()


func _process(_delta: float) -> void:
	_update_projected_radius()


func _update_projected_radius() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

	var viewport_height := get_viewport().get_visible_rect().size.y
	if viewport_height <= 0.0 or radius <= 0.0:
		return

	var center := global_position
	if camera.is_position_behind(center):
		return

	var projected_radius_pixels: float
	match camera.projection:
		Camera3D.PROJECTION_ORTHOGONAL:
			var edge_world := center + camera.global_basis.y * radius
			projected_radius_pixels = camera.unproject_position(center).distance_to(
				camera.unproject_position(edge_world)
			)
		Camera3D.PROJECTION_PERSPECTIVE, Camera3D.PROJECTION_FRUSTUM:
			projected_radius_pixels = _calculate_perspective_radius_pixels(camera, center)
		_:
			return

	if not is_finite(projected_radius_pixels) or projected_radius_pixels <= 0.0:
		return

	var projected_radius_uv := projected_radius_pixels / viewport_height
	if not is_finite(projected_radius_uv) or projected_radius_uv <= 0.0:
		return

	_projected_radius_uv = projected_radius_uv
	set_instance_shader_parameter(PROJECTED_RADIUS_UV_PARAMETER, _projected_radius_uv)


func _calculate_perspective_radius_pixels(camera: Camera3D, center: Vector3) -> float:
	var camera_position := camera.global_position
	var distance := camera_position.distance_to(center)
	if distance <= radius:
		return NAN

	var view_direction := (center - camera_position).normalized()
	var toward_camera := -view_direction
	var tangent_axis := camera.global_basis.y - view_direction * camera.global_basis.y.dot(view_direction)
	if tangent_axis.length_squared() <= MIN_VECTOR_LENGTH_SQUARED:
		return NAN

	tangent_axis = tangent_axis.normalized()
	var tangent_length := sqrt(max(distance * distance - radius * radius, 0.0))
	var toward_camera_offset := radius * radius / distance
	var tangent_axis_offset := radius * tangent_length / distance
	var tangent_point := center + toward_camera * toward_camera_offset + tangent_axis * tangent_axis_offset

	var center_screen := camera.unproject_position(center)
	var tangent_screen := camera.unproject_position(tangent_point)
	return center_screen.distance_to(tangent_screen)
