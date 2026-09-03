class_name EnergyVolumeEvent
extends RefCounted

enum DiameterClass {
	THIN,
	MEDIUM,
	THICK,
}

const GROWTH_END := 0.48
const HOLD_END := 0.68

var start_position: Vector3 = Vector3.ZERO
var direction: Vector3 = Vector3.RIGHT
var max_length: float = 0.0
var current_length: float = 0.0
var diameter_class: DiameterClass = DiameterClass.MEDIUM
var brightness: float = 1.0
var lifetime: float = 1.0
var age: float = 0.0
@warning_ignore("shadowed_global_identifier")
var seed: float = 0.0


func advance(delta: float) -> void:
	age += delta
	current_length = max_length * growth_progress()


func growth_progress() -> float:
	var normalized_age := clampf(age / lifetime, 0.0, 1.0)
	return smoothstep(0.0, 1.0, minf(normalized_age / GROWTH_END, 1.0))


func visibility() -> float:
	var normalized_age := clampf(age / lifetime, 0.0, 1.0)
	if normalized_age <= HOLD_END:
		return 1.0

	return 1.0 - smoothstep(HOLD_END, 1.0, normalized_age)


func is_expired() -> bool:
	return age >= lifetime
