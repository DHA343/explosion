class_name MagicCircleSpawnAnimator
extends Node

signal effect_weight_changed(effect_weight: float)
signal spawn_finished

const ROTATION_TWEEN_SAMPLE_COUNT := 256

@export var auto_play: bool = false
@export var profile: MagicCircleSpawnProfile = preload(
	"res://magic_circle/animation/default_spawn_profile.tres"
)

var _layers: Array[MagicCircleLayer3D] = []
var _rotation_source: MagicCircle
var _normal_rotation_speed: float = 0.0
var _rotation_tween_remaining_areas := PackedFloat32Array()
var _elapsed: float = 0.0
var _playing: bool = false


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	if not _playing:
		return

	_elapsed += delta
	for index in _layers.size():
		var ring_local_time := _elapsed - _ring_start_time(index)
		var body_local_time := ring_local_time - _body_start_delay(index)
		_apply_ring_state(index, ring_local_time)
		_apply_body_state(index, body_local_time)

	var total_duration := _get_total_duration()
	effect_weight_changed.emit(_spawn_effect_weight(total_duration))
	if _elapsed >= total_duration:
		_finish_spawn()


func setup(layers: Array[MagicCircleLayer3D], rotation_source: MagicCircle) -> void:
	_layers = layers
	_rotation_source = rotation_source
	assert(profile != null, "MagicCircleSpawnAnimator: Spawn Profileが設定されていません。")
	for layer in _layers:
		layer.capture_animation_state()
	if auto_play:
		play_spawn()
	else:
		_prepare_waiting_state()


func play_spawn() -> void:
	if _layers.is_empty() or _rotation_source == null:
		push_error("MagicCircleSpawnAnimator: setup()でLayerと回転元を設定する必要があります。")
		return

	_prepare_spawn_state()
	_playing = true
	set_process(true)


func is_playing() -> bool:
	return _playing


func _prepare_waiting_state() -> void:
	_prepare_spawn_state()
	for layer in _layers:
		layer.hide_rings()


func _prepare_spawn_state() -> void:
	_normal_rotation_speed = _rotation_source.overall_rotation_speed
	_build_rotation_tween_lookup()
	_elapsed = 0.0
	effect_weight_changed.emit(0.0)
	for index in _layers.size():
		var ring_local_time := -_ring_start_time(index)
		var body_local_time := ring_local_time - _body_start_delay(index)
		_apply_ring_state(index, ring_local_time)
		_apply_body_state(index, body_local_time)


func _apply_ring_state(index: int, local_time: float) -> void:
	var source_index := _get_ring_source_index(index)
	var is_started := local_time >= 0.0
	var rise_progress := _ring_rise_progress(index, local_time) if is_started else 0.0
	var reveal_progress := _ring_reveal_progress(index, local_time) if is_started else 0.0
	var glow_reveal_progress := _glow_reveal_progress(local_time) if is_started else 0.0
	_layers[index].apply_ring_state(
		_layers[source_index],
		rise_progress,
		reveal_progress,
		glow_reveal_progress,
		is_started
	)


func _apply_body_state(index: int, local_time: float) -> void:
	var scale_progress := _scale_progress(local_time)
	var rotation_progress := _normalized_progress(local_time, profile.rotation_duration)
	var rotation_offset := _rotation_offset_angle(rotation_progress)
	_layers[index].apply_body_state(scale_progress, rotation_offset)


func _get_ring_source_index(index: int) -> int:
	if index <= 1:
		return 0
	return index - 2


func _ring_start_time(index: int) -> float:
	if index <= 0:
		return 0.0
	var first_cycle_duration := maxf(profile.ring_reveal_duration + profile.spawn_interval, 0.0)
	var rise_cycle_duration := maxf(profile.ring_rise_duration + profile.spawn_interval, 0.0)
	return first_cycle_duration + float(index - 1) * rise_cycle_duration


func _body_start_delay(index: int) -> float:
	var ring_duration := profile.ring_reveal_duration if index == 0 else profile.ring_rise_duration
	return maxf(ring_duration - profile.body_spawn_lead_time, 0.0)


func _ring_reveal_progress(index: int, local_time: float) -> float:
	var duration := profile.ring_reveal_duration if index == 0 else profile.ring_rise_duration
	var progress := _normalized_progress(local_time, duration)
	return float(Tween.interpolate_value(
		0.0,
		1.0,
		progress,
		1.0,
		profile.ring_reveal_transition,
		profile.ring_reveal_ease
	))


func _ring_rise_progress(index: int, local_time: float) -> float:
	if index == 0:
		return 1.0
	var progress := _normalized_progress(local_time, profile.ring_rise_duration)
	return float(Tween.interpolate_value(
		0.0,
		1.0,
		progress,
		1.0,
		profile.ring_rise_transition,
		profile.ring_rise_ease
	))


func _glow_reveal_progress(local_time: float) -> float:
	return _normalized_progress(local_time, profile.glow_reveal_duration)


func _normalized_progress(local_time: float, duration: float) -> float:
	if local_time <= 0.0:
		return 0.0
	if duration <= 0.0:
		return 1.0
	return clampf(local_time / duration, 0.0, 1.0)


func _scale_progress(local_time: float) -> float:
	var progress := _normalized_progress(local_time, profile.scale_duration)
	return float(Tween.interpolate_value(
		0.0,
		1.0,
		progress,
		1.0,
		profile.scale_transition,
		profile.scale_ease
	))


func _rotation_offset_angle(progress: float) -> float:
	var extra_speed_multiplier := maxf(profile.initial_speed_multiplier, 1.0) - 1.0
	return (
		extra_speed_multiplier
		* _normal_rotation_speed
		* profile.rotation_duration
		* _sample_remaining_tween_area(progress)
	)


func _build_rotation_tween_lookup() -> void:
	_rotation_tween_remaining_areas.resize(ROTATION_TWEEN_SAMPLE_COUNT + 1)
	_rotation_tween_remaining_areas[ROTATION_TWEEN_SAMPLE_COUNT] = 0.0

	var step := 1.0 / float(ROTATION_TWEEN_SAMPLE_COUNT)
	for sample in range(ROTATION_TWEEN_SAMPLE_COUNT - 1, -1, -1):
		var u0 := float(sample) * step
		var u1 := float(sample + 1) * step
		var speed0 := _rotation_extra_speed_ratio(u0)
		var speed1 := _rotation_extra_speed_ratio(u1)
		_rotation_tween_remaining_areas[sample] = (
			_rotation_tween_remaining_areas[sample + 1]
			+ (speed0 + speed1) * 0.5 * step
		)


func _rotation_extra_speed_ratio(progress: float) -> float:
	var decay_progress := float(Tween.interpolate_value(
		0.0,
		1.0,
		clampf(progress, 0.0, 1.0),
		1.0,
		profile.rotation_transition,
		profile.rotation_ease
	))
	return 1.0 - decay_progress


func _sample_remaining_tween_area(progress: float) -> float:
	if _rotation_tween_remaining_areas.is_empty():
		_build_rotation_tween_lookup()

	var sample_position := clampf(progress, 0.0, 1.0) * float(ROTATION_TWEEN_SAMPLE_COUNT)
	var lower_index := mini(floori(sample_position), ROTATION_TWEEN_SAMPLE_COUNT)
	if lower_index >= ROTATION_TWEEN_SAMPLE_COUNT:
		return 0.0
	return lerpf(
		_rotation_tween_remaining_areas[lower_index],
		_rotation_tween_remaining_areas[lower_index + 1],
		sample_position - float(lower_index)
	)


func _get_total_duration() -> float:
	var body_duration := maxf(profile.scale_duration, profile.rotation_duration)
	var total_duration := 0.0
	for index in _layers.size():
		total_duration = maxf(
			total_duration,
			_ring_start_time(index) + maxf(
				_body_start_delay(index) + body_duration,
				profile.glow_reveal_duration
			)
		)
	return total_duration


func _spawn_effect_weight(total_duration: float) -> float:
	var progress := _normalized_progress(_elapsed, total_duration)
	return progress * progress * (3.0 - 2.0 * progress)


func _finish_spawn() -> void:
	for layer in _layers:
		layer.restore_animation_state()
	_playing = false
	set_process(false)
	spawn_finished.emit()
