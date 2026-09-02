class_name ShellContactEvent
extends RefCounted

enum Phase {
	GROWTH,
	CONTACT,
	DETACH,
	RESIDUE,
}

var phase: Phase = Phase.GROWTH
var elapsed: float = 0.0
var lifetime: float = 0.2
var direction: Vector3 = Vector3.RIGHT
var start_position: Vector3 = Vector3.ZERO
var contact_position: Vector3 = Vector3.RIGHT
var width_class: int = 0
var body_width: float = 0.05
var hot_core_width: float = 0.03
var brightness: float = 1.0
var depth_tilt: float = 0.0
var bend_offset: Vector3 = Vector3.ZERO
var contact_scale: float = 1.0
var growth_duration: float = 0.07
var contact_duration: float = 0.04
var detach_duration: float = 0.06
var residue_duration: float = 0.0
var random_seed: float = 0.0
var is_active: bool = false


func advance(delta: float) -> void:
	elapsed += delta
	_update_phase()


func growth_progress() -> float:
	return clampf(elapsed / growth_duration, 0.0, 1.0)


func detach_progress() -> float:
	var detach_start := growth_duration + contact_duration
	return clampf((elapsed - detach_start) / detach_duration, 0.0, 1.0)


func filament_visibility() -> float:
	if phase == Phase.RESIDUE:
		return 0.0
	if phase != Phase.DETACH:
		return 1.0

	return 1.0 - smoothstep(0.62, 1.0, detach_progress())


func contact_visibility() -> float:
	var contact_start := growth_duration * 0.82
	if elapsed < contact_start:
		return 0.0
	if elapsed < growth_duration:
		return smoothstep(contact_start, growth_duration, elapsed)
	if phase == Phase.CONTACT:
		return 1.0
	if phase == Phase.DETACH:
		return lerpf(1.0, 0.58, detach_progress())
	if residue_duration <= 0.0:
		return 0.0

	var residue_start := growth_duration + contact_duration + detach_duration
	return 0.58 * (1.0 - smoothstep(
		residue_start,
		residue_start + residue_duration,
		elapsed
	))


func _update_phase() -> void:
	if elapsed < growth_duration:
		phase = Phase.GROWTH
	elif elapsed < growth_duration + contact_duration:
		phase = Phase.CONTACT
	elif elapsed < growth_duration + contact_duration + detach_duration:
		phase = Phase.DETACH
	else:
		phase = Phase.RESIDUE
