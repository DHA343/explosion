@tool
class_name RadialEnergyVolumes
extends Node3D

const MAX_DIRECTION_ATTEMPTS := 8
const MAX_DIRECTION_DOT := 0.94

@export_range(0.05, 10.0, 0.01, "suffix:m") var radius: float = 0.5:
	set(value):
		radius = value
		if is_node_ready():
			_reset_events()

@export_range(0.05, 10.0, 0.01, "suffix:m") var inner_radius: float = 0.47:
	set(value):
		inner_radius = value
		if is_node_ready():
			_reset_events()

@export_range(6, 10, 1) var active_event_count: int = 8:
	set(value):
		active_event_count = value
		if is_node_ready():
			_reset_events()

@export var random_seed: int = 72819

var _events: Array[EnergyVolumeEvent] = []
var _rng := RandomNumberGenerator.new()

@onready var _energy_volume_batch: EnergyVolumeBatch = $EnergyVolumeBatch


func _ready() -> void:
	_reset_events()


func _process(delta: float) -> void:
	for event_index in range(_events.size()):
		var event := _events[event_index]
		event.advance(delta)
		if event.is_expired():
			_spawn_event(event, event_index)

	_energy_volume_batch.rebuild(_events, radius)


func _reset_events() -> void:
	_rng.seed = random_seed
	_events.clear()
	for event_index in range(active_event_count):
		var event := EnergyVolumeEvent.new()
		_events.append(event)
		_spawn_event(event, event_index)
		event.age = _rng.randf_range(0.0, event.lifetime * 0.9)
		event.current_length = event.max_length * event.growth_progress()

	if is_node_ready():
		_energy_volume_batch.rebuild(_events, radius)


func _spawn_event(event: EnergyVolumeEvent, event_index: int) -> void:
	var direction := _random_direction()
	var start_distance := radius * _rng.randf_range(0.12, 0.24)
	var outer_distance := minf(inner_radius, radius * 0.98) * _rng.randf_range(0.86, 0.98)

	event.start_position = direction * start_distance
	event.direction = direction
	event.max_length = maxf(outer_distance - start_distance, radius * 0.2)
	event.current_length = 0.0
	event.diameter_class = (
		event_index % EnergyVolumeEvent.DiameterClass.size()
	) as EnergyVolumeEvent.DiameterClass
	event.brightness = _rng.randf_range(0.72, 1.0)
	event.lifetime = _rng.randf_range(0.65, 0.95)
	event.age = 0.0
	event.seed = _rng.randf()


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
	for event in _events:
		if event.max_length > 0.0 and candidate.dot(event.direction) > MAX_DIRECTION_DOT:
			return true
	return false
