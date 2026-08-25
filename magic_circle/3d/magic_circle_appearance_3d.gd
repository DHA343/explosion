@tool
class_name MagicCircleAppearance3D
extends Resource

@export_group("Surface")
## 0.0でAdd寄り、1.0でMix寄りの合成になる。
@export_range(0.0, 1.0, 0.01) var blend_balance: float = 0.5:
	set(value):
		var clamped_value := clampf(value, 0.0, 1.0)
		if is_equal_approx(blend_balance, clamped_value):
			return
		blend_balance = clamped_value
		emit_changed()

@export_range(0.0, 2.0, 0.05) var body_intensity: float = 1.0:
	set(value):
		var clamped_value := clampf(value, 0.0, 8.0)
		if is_equal_approx(body_intensity, clamped_value):
			return
		body_intensity = clamped_value
		emit_changed()

@export_range(0.0, 2.0, 0.05) var ring_intensity: float = 1.0:
	set(value):
		var clamped_value := clampf(value, 0.0, 8.0)
		if is_equal_approx(ring_intensity, clamped_value):
			return
		ring_intensity = clamped_value
		emit_changed()

@export_range(0.0, 2.0, 0.05) var glow_intensity: float = 1.0:
	set(value):
		var clamped_value := clampf(value, 0.0, 8.0)
		if is_equal_approx(glow_intensity, clamped_value):
			return
		glow_intensity = clamped_value
		emit_changed()
