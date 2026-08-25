@tool
extends Line2D

@export_range(0.0, 1000.0, 1.0, "suffix:px") var radius: float = 40.0:
	set(value):
		radius = maxf(value, 0.0)
		_rebuild()

@export_range(16, 512, 1) var segments: int = 128:
	set(value):
		segments = maxi(value, 16)
		_rebuild()


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	var ring_points := PackedVector2Array()
	for index in range(segments):
		var angle := TAU * float(index) / float(segments)
		ring_points.append(Vector2.RIGHT.rotated(angle) * radius)
	points = ring_points
