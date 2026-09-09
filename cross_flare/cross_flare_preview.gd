extends Node3D

const PALETTES: Array[ShaderMaterial] = [
	preload("res://cross_flare/palettes/rainbow.tres"),
	preload("res://cross_flare/palettes/magenta.tres"),
	preload("res://cross_flare/palettes/yellow.tres"),
	preload("res://cross_flare/palettes/gold.tres"),
	preload("res://cross_flare/palettes/pearl.tres"),
]

var _progress: float = 0.0
var _speed: float = 1.0
var _playing: bool = false
var _target: int = 0
var _editors: Dictionary[StringName, SpinBox] = {}

@onready var _flares: Array[CrossFlare] = [$Cross, $SingleRing, $DoubleRing]
@onready var _timeline: HSlider = $Controls/Timeline
@onready var _time_label: Label = $Controls/Time


func _ready() -> void:
	var palette_picker: OptionButton = $Controls/Palette
	for label in ["シアン主体", "マゼンタ主体", "黄主体", "橙・金", "白・淡色＋シアン"]:
		palette_picker.add_item(label)
	palette_picker.item_selected.connect(_on_palette_selected)
	$Controls/Buttons/Play.pressed.connect(_start.bind(1.0))
	$Controls/Buttons/Slow.pressed.connect(_start.bind(0.25))
	$Controls/Buttons/Stepped.toggled.connect(_on_stepped_toggled)
	_timeline.value_changed.connect(_on_time_changed)
	_build_settings()
	_show_time(4.0 / 15.0)


func _process(delta: float) -> void:
	if _playing:
		_show_time(minf(_progress + delta * _speed / _flares[0].duration, 1.0))
		if _progress >= 1.0:
			_playing = false


func _on_time_changed(value: float) -> void:
	_playing = false
	_show_time(value)


func _on_palette_selected(index: int) -> void:
	for flare in _targets():
		flare.palette = PALETTES[index]


func _targets() -> Array[CrossFlare]:
	if _target == 0:
		return _flares
	return [_flares[_target - 1]]


func _build_settings() -> void:
	var picker := OptionButton.new()
	for title in ["編集対象：全種類", "十字のみ", "単リング", "二重リング"]:
		picker.add_item(title)
	picker.item_selected.connect(_on_target_selected)
	$Controls.add_child(picker)
	var grid := GridContainer.new()
	grid.columns = 6
	$Controls.add_child(grid)
	_add_setting(grid, "色面の方向 °", &"flow_direction", -180, 180, 1)
	_add_setting(grid, "色の移動量 ±", &"flow_travel", -1.5, 1.5, 0.01)
	_add_setting(grid, "色の開始位置", &"flow_offset", -1, 1, 0.01)
	_add_setting(grid, "色帯の幅", &"flow_width", 0.25, 3, 0.05)
	_add_setting(grid, "島の数", &"island_count", 3, 5, 1)
	_add_setting(grid, "分裂シード", &"split_seed", 0, 9999, 1)
	_add_setting(grid, "分裂範囲 °", &"split_range", 30, 360, 1)
	_add_setting(grid, "分裂の方向 °", &"split_direction", -180, 180, 1)
	_add_setting(grid, "ばらつき", &"split_irregularity", 0, 1, 0.01)
	_add_setting(grid, "隙間の割合", &"gap_ratio", 0.1, 0.65, 0.01)
	_add_setting(grid, "分裂開始 0〜1", &"split_start", 0, 0.45, 0.005)
	_add_setting(grid, "分裂終了 0〜1", &"split_end", 0, 0.46, 0.005)
	_add_setting(grid, "輪郭のぼかし", &"edge_softness", 0, 0.04, 0.001)
	_add_setting(grid, "光のにじみ", &"halo_strength", 0, 1, 0.01)
	var full := CheckButton.new()
	full.name = "FullCircle"
	full.text = "二重外リングは全周分裂"
	full.button_pressed = true
	full.toggled.connect(func(value: bool) -> void:
		for flare in _targets():
			flare.double_full_circle = value)
	$Controls.add_child(full)


func _add_setting(grid: GridContainer, title: String, property: StringName,
		minimum: float, maximum: float, increment: float) -> void:
	var label := Label.new()
	label.text = title
	grid.add_child(label)
	var editor := SpinBox.new()
	editor.min_value = minimum
	editor.max_value = maximum
	editor.step = increment
	editor.custom_minimum_size.x = 110
	editor.value = float(_flares[0].get(property))
	editor.value_changed.connect(func(value: float) -> void:
		for flare in _targets():
			flare.set(property, value))
	grid.add_child(editor)
	_editors[property] = editor


func _on_target_selected(index: int) -> void:
	_target = index
	var flare: CrossFlare = _targets()[0]
	for property: StringName in _editors:
		_editors[property].set_value_no_signal(float(flare.get(property)))
	$Controls/FullCircle.set_pressed_no_signal(flare.double_full_circle)
	$Controls/Palette.select(PALETTES.find(flare.palette))


func _on_stepped_toggled(enabled: bool) -> void:
	for flare in _flares:
		flare.stepped = enabled


func _start(speed: float) -> void:
	_speed = speed
	_show_time(0.0)
	_playing = true


func _show_time(value: float) -> void:
	_progress = value
	for flare in _flares:
		flare.seek(value * flare.duration)
	_timeline.set_value_no_signal(value)
	_time_label.text = "%.3f 秒 ／ %.3f 秒   コマ %d / 15" % [
		value * _flares[0].duration, _flares[0].duration, mini(int(value * 15.0 + 0.0001), 15)
	]
