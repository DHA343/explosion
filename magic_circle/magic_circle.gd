@tool
class_name MagicCircle
extends Node2D

enum PatternOrder { FORWARD, PING_PONG }

const LINES_CONTAINER_PATH := ^"Lines"
const RINGS_CONTAINER_PATH := ^"Rings"

# ============================================================
# 構成
# ============================================================
@export_group("構成")

## false: Body用ViewportではInner Ringを除外する。
@export var inner_ring_visible: bool = true:
	set(value):
		inner_ring_visible = value
		_update_inner_ring_visibility()

## 1本ぶんのラインシーン（PathLine など）
@export var line_scene: PackedScene:
	set(v):
		line_scene = v
		_request_rebuild()

## 線の本数
@export_range(1, 64, 1) var line_count: int = 10:
	set(v):
		line_count = maxi(1, v)
		_request_rebuild()

## 線をずらす角度（度）
@export_range(-360.0, 360.0, 0.1) var angle_step_deg: float = 36.0:
	set(v):
		angle_step_deg = v
		_request_rebuild()

## true: 中心対称に開く / false: 片側だけに開く
@export var center_spread: bool = true:
	set(v):
		center_spread = v
		_request_rebuild()

## 全体の初期角度（度）
@export_range(-360.0, 360.0, 0.1) var base_angle_deg: float = 0.0:
	set(v):
		base_angle_deg = v
		_request_rebuild()

# ============================================================
# 回転
# ============================================================
@export_group("回転")

## 線ごとの回転速度パターン（rad/秒）
@export var speed_pattern: PackedFloat32Array = PackedFloat32Array([1.0, 2.0, 3.0, 2.0, 1.0, 0.0]):
	set(v):
		speed_pattern = v
		refresh_speeds()

## FORWARD: 1,2,3,1,2,3… / PING_PONG: 1,2,3,2,1,2,3…
@export var pattern_order: PatternOrder = PatternOrder.FORWARD:
	set(v):
		pattern_order = v
		refresh_speeds()

## 速度の一括倍率
@export_range(-0.2, 0.5, 0.01) var speed_scale: float = 0.16:
	set(v):
		speed_scale = v
		refresh_speeds()

## 魔法陣全体の回転速度（rad/秒、正の値で時計回り）
@export_range(-0.5, 0.5, 0.01) var overall_rotation_speed: float = 0.1

# ============================================================
# エディタ
# ============================================================
@export_group("エディタ")

## エディタ上にも線を生成して表示する
@export var preview_in_editor: bool = true:
	set(v):
		preview_in_editor = v
		_request_rebuild()

## 各線の速度をコンソールに出力する
@export var debug_print_speeds: bool = false:
	set(v):
		debug_print_speeds = v
		if v:
			_print_speeds()

## 押すと再構築（チェックは自動で戻る）
@export var rebuild_now: bool = false:
	set(_v):
		rebuild_now = false
		_rebuild()

# ============================================================
# 内部状態
# ============================================================
var _lines: Array = []   # [{ "node": Node2D, "speed": float, "base": float }]

func _ready() -> void:
	_update_inner_ring_visibility()
	_rebuild()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	rotation -= overall_rotation_speed * delta
	for l in _lines:
		var ln: Node2D = l["node"]
		if is_instance_valid(ln):
			ln.rotation -= float(l["speed"]) * delta

# ============================================================
# 速度計算
# ============================================================

## 線の回転速度（speed_scale 適用済み）
func get_line_speed(index: int) -> float:
	if speed_pattern.is_empty():
		return 0.0
	var n := speed_pattern.size()
	var idx := 0
	if pattern_order == PatternOrder.PING_PONG and n > 1:
		var period := n * 2 - 2
		var p := posmod(index, period)
		idx = p if p < n else period - p
	else:
		idx = posmod(index, n)
	return speed_pattern[idx] * speed_scale

# ============================================================
# 構築
# ============================================================

func _request_rebuild() -> void:
	if is_inside_tree():
		_rebuild()


func _update_inner_ring_visibility() -> void:
	var rings := get_node_or_null(RINGS_CONTAINER_PATH) as CanvasItem
	if rings != null:
		rings.visible = inner_ring_visible

func _clear() -> void:
	var lines_container := get_node_or_null(LINES_CONTAINER_PATH) as Node2D
	for l in _lines:
		var ln = l["node"]
		if is_instance_valid(ln):
			if ln.get_parent() != null:
				ln.get_parent().remove_child(ln)
			ln.queue_free()
	_lines.clear()
	# 取りこぼし対策
	if lines_container == null:
		return
	for ch in lines_container.get_children():
		if ch is Node2D and String(ch.name).begins_with("Line"):
			lines_container.remove_child(ch)
			ch.queue_free()

func _rebuild() -> void:
	if not is_inside_tree():
		return
	_clear()
	if Engine.is_editor_hint() and not preview_in_editor:
		return
	if line_scene == null:
		return
	var lines_container := get_node_or_null(LINES_CONTAINER_PATH) as Node2D
	if lines_container == null:
		push_warning("MagicCircle: Linesコンテナが見つかりません。")
		return

	var base := deg_to_rad(base_angle_deg)
	var step := deg_to_rad(angle_step_deg)

	for i in line_count:
		var pivot := Node2D.new()
		pivot.name = "Line%d" % i
		var offset := float(i) * step
		if center_spread:
			offset = (float(i) - float(line_count - 1) * 0.5) * step
		offset += base
		pivot.rotation = offset
		lines_container.add_child(pivot)

		var inst := line_scene.instantiate()
		pivot.add_child(inst)
		if inst.has_method(&"set_noise_variant"):
			inst.call(&"set_noise_variant", i)

		_lines.append({
			"node": pivot,
			"speed": get_line_speed(i),
			"base": offset,
		})

	if debug_print_speeds:
		_print_speeds()

# ============================================================
# 更新ユーティリティ
# ============================================================

## 再構築せず速度だけ入れ直す
func refresh_speeds() -> void:
	if _lines.is_empty():
		return
	for i in _lines.size():
		_lines[i]["speed"] = get_line_speed(i)
	if debug_print_speeds:
		_print_speeds()

func _print_speeds() -> void:
	print("--- MagicCircle ---")
	print("ライン総数: %d" % _lines.size())
	for i in _lines.size():
		var spd := get_line_speed(i)
		var mark := "  ← 静止" if is_zero_approx(spd) else ""
		print("  Line%d  速度: %.4f%s" % [i, spd, mark])
