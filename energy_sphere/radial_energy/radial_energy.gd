@tool
class_name RadialEnergy
extends Node3D

const MAX_DIRECTION_ATTEMPTS := 8
const MAX_DIRECTION_DOT := 0.94

@export_range(0.05, 10.0, 0.01, "suffix:m") var radius: float = 0.5:
	set(value):
		radius = value
		if is_node_ready():
			_reset_rays()

@export_range(0.05, 10.0, 0.01, "suffix:m") var inner_radius: float = 0.47:
	set(value):
		inner_radius = value
		if is_node_ready():
			_reset_rays()

@export_range(1, 100, 1) var ray_count: int = 24:
	set(value):
		ray_count = value
		if is_node_ready():
			_reset_rays()

@export var random_seed: int = 72819

var _rays: Array[RadialEnergyRay] = []
var _rng := RandomNumberGenerator.new()

@onready var _ray_mesh: RadialEnergyMesh = $RayMesh


func _ready() -> void:
	_reset_rays()


func _process(delta: float) -> void:
	for ray_index in range(_rays.size()):
		var ray := _rays[ray_index]
		ray.advance(delta)
		if ray.is_expired():
			_spawn_ray(ray, ray_index)

	_ray_mesh.rebuild(_rays, radius)


func _reset_rays() -> void:
	_rng.seed = random_seed
	_rays.clear()
	for ray_index in range(ray_count):
		var ray := RadialEnergyRay.new()
		_rays.append(ray)
		_spawn_ray(ray, ray_index)
		ray.age = _rng.randf_range(0.0, ray.lifetime * 0.9)
		ray.current_length = ray.max_length * ray.growth_progress()

	if is_node_ready():
		_ray_mesh.rebuild(_rays, radius)


func _spawn_ray(ray: RadialEnergyRay, ray_index: int) -> void:
	var direction := _random_direction()
	var start_distance := radius * _rng.randf_range(0.12, 0.24)
	var outer_distance := minf(inner_radius, radius * 0.98) * _rng.randf_range(0.86, 0.98)

	ray.start_position = direction * start_distance
	ray.direction = direction
	ray.max_length = maxf(outer_distance - start_distance, radius * 0.2)
	ray.current_length = 0.0
	ray.thickness_class = (
		ray_index % RadialEnergyRay.ThicknessClass.size()
	) as RadialEnergyRay.ThicknessClass
	ray.brightness = _rng.randf_range(0.72, 1.0)
	ray.lifetime = _rng.randf_range(0.65, 0.95)
	ray.age = 0.0
	ray.seed = _rng.randf()


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
