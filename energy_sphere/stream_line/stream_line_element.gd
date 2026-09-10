@tool
class_name StreamLineElement
extends MeshInstance3D

enum LineKind {
	CYAN,
	NAVY,
	WHITE,
}

@export_group("Line")

@export_enum("Cyan", "Navy", "White") var line_kind: int = LineKind.CYAN:
	set(value):
		line_kind = clampi(value, LineKind.CYAN, LineKind.WHITE)
		_notify_stream_line()

@export_range(0.01, 0.18, 0.005, "suffix:m") var width: float = 0.06:
	set(value):
		width = clampf(value, 0.01, 0.18)
		_notify_stream_line()

@export_range(-0.30, 0.30, 0.01, "suffix:m") var offset: float = 0.0:
	set(value):
		offset = clampf(value, -0.30, 0.30)
		_notify_stream_line()

@export_range(0.0, 0.10, 0.005, "suffix:m") var line_wave_amplitude: float = 0.025:
	set(value):
		line_wave_amplitude = clampf(value, 0.0, 0.10)
		_notify_stream_line()

@export_range(0.0, 1.0, 0.01) var line_wave_phase: float = 0.0:
	set(value):
		line_wave_phase = clampf(value, 0.0, 1.0)
		_notify_stream_line()


func _notify_stream_line() -> void:
	if not is_inside_tree():
		return

	var parent := get_parent()
	if parent != null and parent.has_method("refresh_element"):
		parent.refresh_element(self)
