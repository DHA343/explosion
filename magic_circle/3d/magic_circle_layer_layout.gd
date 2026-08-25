@tool
class_name MagicCircleLayerLayout
extends Resource

@export_range(0.01, 5.0, 0.01) var scale_factor: float = 1.0:
	set(value):
		var clamped_value := clampf(value, 0.01, 5.0)
		if is_equal_approx(scale_factor, clamped_value):
			return
		scale_factor = clamped_value
		emit_changed()

@export_range(-360.0, 360.0, 0.1, "suffix:°") var rotation_deg: float = 0.0:
	set(value):
		var clamped_value := clampf(value, -360.0, 360.0)
		if is_equal_approx(rotation_deg, clamped_value):
			return
		rotation_deg = clamped_value
		emit_changed()
