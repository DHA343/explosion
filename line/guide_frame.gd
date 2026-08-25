@tool
extends Node2D
class_name GuideFrame

# =====================================================
#  構造
# =====================================================
@export_group("構造")

## 外円の半径
@export var outer_radius: float = 400.0:
	set(v):
		outer_radius = maxf(0.0, v)
		queue_redraw()

## 内円の半径
@export var inner_radius: float = 90.0:
	set(v):
		inner_radius = maxf(0.0, v)
		queue_redraw()

## 周囲に並べる楕円の数
@export_range(1, 60, 1) var ellipse_count: int = 10:
	set(v):
		ellipse_count = maxi(1, v)
		queue_redraw()

## 中心から楕円の中心までの距離
@export_range(0, 500, 1.0) var ellipse_distance: float = 270.0:
	set(v):
		ellipse_distance = v
		queue_redraw()

## 楕円の長半径（円周の接線方向）
@export_range(0, 500, 1.0) var ellipse_a: float = 160.0:
	set(v):
		ellipse_a = maxf(1.0, v)
		queue_redraw()

## 楕円の短半径（放射方向）
@export_range(0, 500, 1.0) var ellipse_b: float = 140.0:
	set(v):
		ellipse_b = maxf(1.0, v)
		queue_redraw()

## 楕円全体の角度オフセット（度）
@export_range(-360.0, 360.0, 0.1) var angle_offset_deg: float = 0.0:
	set(v):
		angle_offset_deg = v
		queue_redraw()

## 楕円自体の傾き補正（度）。0 で長軸が円周の接線方向
@export_range(-180.0, 180.0, 0.1) var ellipse_tilt_deg: float = 0.0:
	set(v):
		ellipse_tilt_deg = v
		queue_redraw()


# =====================================================
#  表示
# =====================================================
@export_group("表示")

## ゲーム実行時にもガイドを表示する
@export var visible_in_game: bool = false:
	set(v):
		visible_in_game = v
		queue_redraw()

@export var show_outer_circle: bool = true:
	set(v):
		show_outer_circle = v
		queue_redraw()

@export var show_inner_circle: bool = true:
	set(v):
		show_inner_circle = v
		queue_redraw()

@export var show_ellipses: bool = true:
	set(v):
		show_ellipses = v
		queue_redraw()

## 中心の十字線
@export var show_center_cross: bool = true:
	set(v):
		show_center_cross = v
		queue_redraw()

## 各楕円の中心へ引く放射線
@export var show_spokes: bool = false:
	set(v):
		show_spokes = v
		queue_redraw()

@export var guide_color: Color = Color(1, 1, 1, 0.18):
	set(v):
		guide_color = v
		queue_redraw()

@export var circle_color: Color = Color(0.5, 0.7, 1.0, 0.25):
	set(v):
		circle_color = v
		queue_redraw()

@export var line_thickness: float = 1.0:
	set(v):
		line_thickness = maxf(0.5, v)
		queue_redraw()

## 強調表示したい楕円の番号（-1 で無効）
@export_range(-1, 59, 1) var highlight_index: int = -1:
	set(v):
		highlight_index = v
		queue_redraw()

@export var highlight_color: Color = Color(0.4, 0.9, 1.0, 0.6):
	set(v):
		highlight_color = v
		queue_redraw()

@export_range(8, 256, 1) var segments: int = 96:
	set(v):
		segments = maxi(8, v)
		queue_redraw()


# =====================================================
#  形状データの取得（PathLine から参照される）
# =====================================================
## i 番目の楕円の情報を返す
func get_ellipse_info(index: int) -> Dictionary:
	var ang := deg_to_rad(angle_offset_deg) + TAU * float(index) / float(ellipse_count)
	return {
		"center": Vector2.RIGHT.rotated(ang) * ellipse_distance,
		"a": ellipse_a,
		"b": ellipse_b,
		"rot": ang + PI * 0.5 + deg_to_rad(ellipse_tilt_deg),
	}


func ellipse_point(index: int, t: float) -> Vector2:
	var e := get_ellipse_info(index)
	return e["center"] + Vector2(e["a"] * cos(t), e["b"] * sin(t)).rotated(e["rot"])


func ellipse_polyline(index: int, seg: int = -1) -> PackedVector2Array:
	var n := segments if seg <= 0 else seg
	var pts := PackedVector2Array()
	for i in range(n + 1):
		pts.append(ellipse_point(index, TAU * float(i) / float(n)))
	return pts


## 全ガイド図形の輪郭点をまとめて返す（吸着用）
func collect_snap_points(density: int = 256) -> PackedVector2Array:
	var pts := PackedVector2Array()
	if show_ellipses:
		for i in ellipse_count:
			for j in density:
				pts.append(ellipse_point(i, TAU * float(j) / float(density)))
	if show_inner_circle and inner_radius > 0.0:
		for j in density:
			pts.append(Vector2.RIGHT.rotated(TAU * float(j) / float(density)) * inner_radius)
	if show_outer_circle and outer_radius > 0.0:
		for j in density:
			pts.append(Vector2.RIGHT.rotated(TAU * float(j) / float(density)) * outer_radius)
	return pts


# =====================================================
#  描画
# =====================================================
func _draw() -> void:
	if not Engine.is_editor_hint() and not visible_in_game:
		return

	if show_outer_circle and outer_radius > 0.0:
		draw_arc(Vector2.ZERO, outer_radius, 0.0, TAU, segments * 2, circle_color, line_thickness, true)

	if show_inner_circle and inner_radius > 0.0:
		draw_arc(Vector2.ZERO, inner_radius, 0.0, TAU, segments, circle_color, line_thickness, true)

	if show_spokes:
		for i in ellipse_count:
			var e := get_ellipse_info(i)
			draw_line(Vector2.ZERO, e["center"], guide_color, line_thickness, true)

	if show_ellipses:
		for i in ellipse_count:
			var col := guide_color
			if highlight_index == i:
				col = highlight_color
			draw_polyline(ellipse_polyline(i), col, line_thickness, true)

	if show_center_cross:
		var r := maxf(outer_radius, ellipse_distance + ellipse_b) * 1.05
		draw_line(Vector2(-r, 0), Vector2(r, 0), guide_color, line_thickness, true)
		draw_line(Vector2(0, -r), Vector2(0, r), guide_color, line_thickness, true)
