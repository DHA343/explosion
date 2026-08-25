@tool
extends Node2D

@export_range(0.0, 1000.0, 1.0, "suffix:px") var radius: float = 40.0:
	set(value):
		radius = maxf(value, 0.0)
		queue_redraw()

@export var color: Color = Color.WHITE:
	set(value):
		color = value
		queue_redraw()


func _draw() -> void:
	var diameter := radius * 2.0
	var rect := Rect2(Vector2(-radius, -radius), Vector2(diameter, diameter))
	draw_rect(rect, color, true)
