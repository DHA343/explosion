@tool
class_name MagicCircle3D
extends Node3D

const LAYER_SCENE: PackedScene = preload("res://magic_circle/3d/magic_circle_layer_3d.tscn")

@export var appearance: MagicCircleAppearance3D = preload(
	"res://magic_circle/3d/default_appearance.tres"
):
	set(value):
		_disconnect_appearance_signal()
		appearance = value
		_connect_appearance_signal()
		_apply_appearance()

@export var layout: MagicCircleLayout = preload("res://magic_circle/3d/default_layout.tres"):
	set(value):
		_disconnect_layout_signal()
		layout = value
		_connect_layout_signal()
		_rebuild_layers()

var _layers: Array[MagicCircleLayer3D] = []
var _base_light_energy: float = 0.0
var _effect_weight: float = 1.0

@onready var _body_viewport: SubViewport = $MagicCircleViewport
@onready var _ring_viewport: SubViewport = $MagicCircleRingViewport
@onready var _glow_ring_viewport: SubViewport = $MagicCircleRingGlowViewport
@onready var _rotation_source: MagicCircle = $MagicCircleViewport/MagicCircle
@onready var _layers_container: Node3D = $Layers
@onready var _spawn_animator: MagicCircleSpawnAnimator = $MagicCircleSpawnAnimator
@onready var _local_light: OmniLight3D = $LocalLight


func _ready() -> void:
	_connect_appearance_signal()
	_connect_layout_signal()
	_rebuild_layers()
	_apply_appearance()
	if Engine.is_editor_hint():
		return

	assert(appearance != null, "MagicCircle3D: Appearanceが設定されていません。")
	assert(layout != null, "MagicCircle3D: Layoutが設定されていません。")
	assert(not _layers.is_empty(), "MagicCircle3D: Layoutには1つ以上のLayerを設定してください。")
	_base_light_energy = _local_light.light_energy
	_spawn_animator.effect_weight_changed.connect(_on_effect_weight_changed)
	for layer in _layers:
		layer.bind_viewports(_body_viewport, _ring_viewport, _glow_ring_viewport)
	_spawn_animator.setup(_layers, _rotation_source)


func play_spawn() -> void:
	_spawn_animator.play_spawn()


func is_spawn_playing() -> bool:
	return _spawn_animator.is_playing()


func _on_effect_weight_changed(effect_weight: float) -> void:
	_effect_weight = clampf(effect_weight, 0.0, 1.0)
	_apply_light_energy()


func _connect_appearance_signal() -> void:
	if appearance != null and not appearance.changed.is_connected(_on_appearance_changed):
		appearance.changed.connect(_on_appearance_changed)


func _disconnect_appearance_signal() -> void:
	if appearance != null and appearance.changed.is_connected(_on_appearance_changed):
		appearance.changed.disconnect(_on_appearance_changed)


func _on_appearance_changed() -> void:
	_apply_appearance()


func _apply_appearance() -> void:
	if not is_node_ready() or appearance == null:
		return

	for layer in _layers:
		layer.set_appearance(appearance)


func _apply_light_energy() -> void:
	if not is_node_ready():
		return
	_local_light.light_energy = _base_light_energy * _effect_weight


func _connect_layout_signal() -> void:
	if layout != null and not layout.changed.is_connected(_on_layout_changed):
		layout.changed.connect(_on_layout_changed)


func _disconnect_layout_signal() -> void:
	if layout != null and layout.changed.is_connected(_on_layout_changed):
		layout.changed.disconnect(_on_layout_changed)


func _on_layout_changed() -> void:
	_rebuild_layers()


func _rebuild_layers() -> void:
	if not is_node_ready():
		return

	_clear_layers()
	if layout == null:
		return

	var center_index := float(layout.layers.size() - 1) * 0.5
	for index in layout.layers.size():
		var layer_layout := layout.layers[index]
		if layer_layout == null:
			push_warning("MagicCircle3D: LayoutのLayer %dが設定されていません。" % (index + 1))
			continue

		var layer := LAYER_SCENE.instantiate() as MagicCircleLayer3D
		assert(layer != null, "MagicCircle3D: Layer SceneのルートはMagicCircleLayer3Dである必要があります。")
		layer.name = "Layer%02d" % (index + 1)
		_layers_container.add_child(layer, false, Node.INTERNAL_MODE_BACK)
		var layer_y := (float(index) - center_index) * layout.vertical_spacing
		layer.set_layout(layer_y, deg_to_rad(layer_layout.rotation_deg), layer_layout.scale_factor)
		if appearance != null:
			layer.set_appearance(appearance)
		_layers.append(layer)


func _clear_layers() -> void:
	for layer in _layers:
		if is_instance_valid(layer):
			if layer.get_parent() == _layers_container:
				_layers_container.remove_child(layer)
			layer.queue_free()
	_layers.clear()
