@tool
extends Node2D
class_name PathLine


const LINE_PATH := NodePath("Line")
const GLOW_LINE_PATH := NodePath("GlowLine")
const FADE_CURVE_STEPS := 16


@export_group("曲線")

@export var curved_path: Path2D:
	set(value):
		_disconnect_curve()
		curved_path = value
		_connect_curve()
		_request_rebuild()

## Curve2D を Line2D 用の点列へ変換するときの点間隔。
@export_range(1.0, 64.0, 0.5) var point_interval: float = 8.0:
	set(value):
		point_interval = maxf(value, 1.0)
		_request_rebuild()


@export_group("ライン")

@export var line_material: Material:
	set(value):
		line_material = value
		_request_rebuild()

## 線幅カーブの値を掛ける基準線幅。
@export_range(0.1, 128.0, 0.1) var line_width: float = 12.0:
	set(value):
		line_width = maxf(value, 0.1)
		_request_rebuild()

@export_range(0.0, 1.0, 0.01) var line_opacity: float = 1.0:
	set(value):
		line_opacity = clampf(value, 0.0, 1.0)
		_request_rebuild()

@export_subgroup("太さのフェード")

## 太い状態から細い状態へ変化し始める位置。ライン全体を 0.0～1.0 として指定する。
@export_range(0.0, 1.0, 0.01) var fade_out_start: float = 0.24:
	set(value):
		fade_out_start = clampf(value, 0.0, 1.0)
		_request_rebuild()

## 細い状態から太い状態へ変化し始める位置。ライン全体を 0.0～1.0 として指定する。
@export_range(0.0, 1.0, 0.01) var fade_in_start: float = 0.60:
	set(value):
		fade_in_start = clampf(value, 0.0, 1.0)
		_request_rebuild()

## 2箇所のフェードに共通して使用する幅。
@export_range(0.001, 1.0, 0.001) var fade_width: float = 0.10:
	set(value):
		fade_width = clampf(value, 0.001, 1.0)
		_request_rebuild()

## フェード間の細い部分に適用する line_width の倍率。
@export_range(0.0, 1.0, 0.01) var thin_width_ratio: float = 0.18:
	set(value):
		thin_width_ratio = clampf(value, 0.0, 1.0)
		_request_rebuild()

## 共通イージングの強さ。1.0 で線形になり、大きいほど変化の両端が緩やかになる。
@export_range(1.0, 8.0, 0.1) var fade_easing: float = 2.0:
	set(value):
		fade_easing = maxf(value, 1.0)
		_request_rebuild()


@export_group("更新")

@export var rebuild_now: bool = false:
	set(_value):
		rebuild_now = false
		_request_rebuild()


func _ready() -> void:
	_connect_curve()
	_rebuild()


func _exit_tree() -> void:
	_disconnect_curve()


func _connect_curve() -> void:
	if curved_path == null or curved_path.curve == null:
		return
	if not curved_path.curve.changed.is_connected(_rebuild):
		curved_path.curve.changed.connect(_rebuild)


func _disconnect_curve() -> void:
	if curved_path == null or curved_path.curve == null:
		return
	if curved_path.curve.changed.is_connected(_rebuild):
		curved_path.curve.changed.disconnect(_rebuild)


func _request_rebuild() -> void:
	if is_inside_tree():
		_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return

	var curve_points := PackedVector2Array()
	if curved_path != null and curved_path.curve != null and curved_path.curve.point_count >= 2:
		curve_points = curved_path.curve.tessellate_even_length(5, point_interval)

	var line := get_node_or_null(LINE_PATH) as Line2D
	if line == null:
		return

	line.points = curve_points
	line.width = line_width
	line.width_curve = _build_width_curve()
	line.material = line_material
	line.self_modulate = Color(1.0, 1.0, 1.0, line_opacity)
	line.visible = curve_points.size() >= 2

	var glow_line := get_node_or_null(GLOW_LINE_PATH) as Line2D
	if glow_line != null:
		glow_line.points = curve_points


func _build_width_curve() -> Curve:
	var width_curve := Curve.new()
	width_curve.min_value = 0.0
	width_curve.max_value = 1.0

	var out_start := clampf(fade_out_start, 0.0, 1.0)
	var in_start := clampf(fade_in_start, out_start, 1.0)
	var usable_width := minf(fade_width, minf(in_start - out_start, 1.0 - in_start))
	usable_width = maxf(usable_width, 0.0)

	_add_width_point(width_curve, 0.0, 1.0)
	_add_width_point(width_curve, out_start, 1.0)

	if usable_width > 0.0:
		for index in range(1, FADE_CURVE_STEPS + 1):
			var progress := float(index) / float(FADE_CURVE_STEPS)
			var eased_progress := ease(progress, -fade_easing)
			_add_width_point(
				width_curve,
				out_start + usable_width * progress,
				lerpf(1.0, thin_width_ratio, eased_progress)
			)

	_add_width_point(width_curve, in_start, thin_width_ratio)

	if usable_width > 0.0:
		for index in range(1, FADE_CURVE_STEPS + 1):
			var progress := float(index) / float(FADE_CURVE_STEPS)
			var eased_progress := ease(progress, -fade_easing)
			_add_width_point(
				width_curve,
				in_start + usable_width * progress,
				lerpf(thin_width_ratio, 1.0, eased_progress)
			)

	_add_width_point(width_curve, 1.0, 1.0)
	return width_curve


func _add_width_point(width_curve: Curve, position: float, value: float) -> void:
	var point := Vector2(clampf(position, 0.0, 1.0), clampf(value, 0.0, 1.0))
	var last_index := width_curve.point_count - 1
	if last_index >= 0 and is_equal_approx(width_curve.get_point_position(last_index).x, point.x):
		width_curve.set_point_value(last_index, point.y)
		return

	width_curve.add_point(
		point,
		0.0,
		0.0,
		Curve.TANGENT_LINEAR,
		Curve.TANGENT_LINEAR
	)
