@tool
class_name MagicCircleLayout
extends Resource

@export_range(0.0, 100.0, 0.1, "suffix:m") var vertical_spacing: float = 17.0:
	set(value):
		var clamped_value := clampf(value, 0.0, 100.0)
		if is_equal_approx(vertical_spacing, clamped_value):
			return
		vertical_spacing = clamped_value
		emit_changed()

@export var layers: Array[MagicCircleLayerLayout] = []:
	set(value):
		_disconnect_layer_signals()
		layers = value
		_connect_layer_signals()
		emit_changed()


func _connect_layer_signals() -> void:
	for layer in layers:
		if layer != null and not layer.changed.is_connected(_on_layer_changed):
			layer.changed.connect(_on_layer_changed)


func _disconnect_layer_signals() -> void:
	for layer in layers:
		if layer != null and layer.changed.is_connected(_on_layer_changed):
			layer.changed.disconnect(_on_layer_changed)


func _on_layer_changed() -> void:
	emit_changed()
