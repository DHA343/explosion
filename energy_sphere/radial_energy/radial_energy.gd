class_name RadialEnergy
extends Node3D

const MAX_DIRECTION_ATTEMPTS := 8
const MAX_DIRECTION_DOT := 0.94

@export_range(0.05, 10.0, 0.01, "suffix:m") var radius: float = 0.5:
	set(value):
		radius = value
		if is_node_ready():
			_update_ray_layout()

@export_range(0.05, 10.0, 0.01, "suffix:m") var inner_radius: float = 0.47:
	set(value):
		inner_radius = value
		if is_node_ready():
			_update_ray_layout()

@export_range(1, 100, 1) var ray_count: int = 24:
	set(value):
		ray_count = value
		if is_node_ready():
			_reset_rays()

@export_range(0.1, 5.0, 0.05) var animation_speed: float = 1.0

@export var random_seed: int = 72819

@export_group("Thickness")
@export_range(0.1, 2.0, 0.01) var thickness_scale: float = 1.0:
	set(value):
		thickness_scale = value
		if is_node_ready():
			_update_instance_thickness()

@export_range(0.01, 2.0, 0.01) var thin_thickness_ratio: float = 0.30:
	set(value):
		thin_thickness_ratio = value
		if is_node_ready():
			_update_instance_thickness()

@export_range(0.01, 2.0, 0.01) var medium_thickness_ratio: float = 0.60:
	set(value):
		medium_thickness_ratio = value
		if is_node_ready():
			_update_instance_thickness()

@export_range(0.01, 2.0, 0.01) var thick_thickness_ratio: float = 1.00:
	set(value):
		thick_thickness_ratio = value
		if is_node_ready():
			_update_instance_thickness()

@export_range(0.01, 1.0, 0.01) var inner_thickness_ratio: float = 0.45:
	set(value):
		inner_thickness_ratio = value
		if is_node_ready():
			_update_shader_thickness_parameters()

@export_range(0.1, 4.0, 0.05) var taper_power: float = 1.35:
	set(value):
		taper_power = value
		if is_node_ready():
			_update_shader_thickness_parameters()

var _rays: Array[RadialEnergyRay] = []
var _rng := RandomNumberGenerator.new()

@onready var _rays_view: RadialEnergyRays = $Rays
@onready var _ray_material: ShaderMaterial = _rays_view.material_override as ShaderMaterial


func _ready() -> void:
	assert(_ray_material != null, "Rays requires a ShaderMaterial override.")
	_reset_rays()
	_update_shader_thickness_parameters()


func _process(delta: float) -> void:
	for ray_index in range(_rays.size()):
		var ray := _rays[ray_index]
		ray.advance(delta * animation_speed)
		if ray.is_expired():
			_spawn_ray(ray, ray_index)
			_rays_view.update_ray(ray, ray_index, thickness_scale)

	_rays_view.update_dynamic_data(_rays, thickness_scale)


func _reset_rays() -> void:
	_rng.seed = random_seed
	_rays.clear()
	for ray_index in range(ray_count):
		var ray := RadialEnergyRay.new()
		_rays.append(ray)
		_spawn_ray(ray, ray_index)
		ray.age = _rng.randf_range(0.0, ray.lifetime * 0.9)

	_rays_view.synchronize(_rays, radius, thickness_scale, _thickness_ratios())


func _spawn_ray(ray: RadialEnergyRay, ray_index: int) -> void:
	var direction := _random_direction()
	var start_distance := radius * _rng.randf_range(0.12, 0.24)
	var outer_distance := minf(inner_radius, radius * 0.98) * _rng.randf_range(0.86, 0.98)

	ray.start_position = direction * start_distance
	ray.direction = direction
	ray.max_length = maxf(outer_distance - start_distance, radius * 0.2)
	ray.thickness_class = (
		ray_index % RadialEnergyRay.ThicknessClass.size()
	) as RadialEnergyRay.ThicknessClass
	ray.brightness = _rng.randf_range(0.72, 1.0)
	ray.lifetime = _rng.randf_range(0.65, 0.95)
	ray.age = 0.0
	ray.seed = _rng.randf()


func _update_ray_layout() -> void:
	for ray_index in range(_rays.size()):
		_spawn_ray(_rays[ray_index], ray_index)

	_rays_view.synchronize(_rays, radius, thickness_scale, _thickness_ratios())


func _update_instance_thickness() -> void:
	_rays_view.update_thickness(_rays, thickness_scale, _thickness_ratios())


func _update_shader_thickness_parameters() -> void:
	_ray_material.set_shader_parameter(&"inner_thickness_ratio", inner_thickness_ratio)
	_ray_material.set_shader_parameter(&"taper_power", taper_power)


func _thickness_ratios() -> PackedFloat32Array:
	return PackedFloat32Array([
		thin_thickness_ratio, medium_thickness_ratio, thick_thickness_ratio
	])


func _random_direction() -> Vector3:
	var candidate := Vector3.RIGHT
	for attempt in range(MAX_DIRECTION_ATTEMPTS):
		var y := _rng.randf_range(-1.0, 1.0)
		var angle := _rng.randf_range(0.0, TAU)
		var horizontal_radius := sqrt(maxf(0.0, 1.0 - y * y))
		candidate = Vector3(horizontal_radius * cos(angle), y, horizontal_radius * sin(angle))
		if not _is_direction_crowded(candidate):
			break
	return candidate


func _is_direction_crowded(candidate: Vector3) -> bool:
	for ray in _rays:
		if ray.max_length > 0.0 and candidate.dot(ray.direction) > MAX_DIRECTION_DOT:
			return true
	return false
