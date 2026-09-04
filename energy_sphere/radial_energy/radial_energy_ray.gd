class_name RadialEnergyRay
extends RefCounted

enum ThicknessClass {
	THIN,
	MEDIUM,
	THICK,
}

const EXTEND_END := 0.48
const RETRACT_START := 0.65
const FADE_START := 0.78

var start_position: Vector3 = Vector3.ZERO
var direction: Vector3 = Vector3.RIGHT
var max_length: float = 0.0
var thickness_class: ThicknessClass = ThicknessClass.MEDIUM
var brightness: float = 1.0
var lifetime: float = 1.0
var age: float = 0.0
@warning_ignore("shadowed_global_identifier")
var seed: float = 0.0


func advance(delta: float) -> void:
	age += delta


func length_progress() -> float:
	var normalized_age := clampf(age / lifetime, 0.0, 1.0)
	if normalized_age <= EXTEND_END:
		return smoothstep(0.0, 1.0, normalized_age / EXTEND_END)
	if normalized_age <= RETRACT_START:
		return 1.0
	return 1.0 - smoothstep(RETRACT_START, 1.0, normalized_age)


func visibility() -> float:
	var normalized_age := clampf(age / lifetime, 0.0, 1.0)
	if normalized_age <= FADE_START:
		return 1.0

	return 1.0 - smoothstep(FADE_START, 1.0, normalized_age)


func retract_thickness_scale() -> float:
	var normalized_age := clampf(age / lifetime, 0.0, 1.0)
	if normalized_age <= RETRACT_START:
		return 1.0

	return 1.0 - smoothstep(RETRACT_START, 1.0, normalized_age)


func is_expired() -> bool:
	return age >= lifetime
