@tool
extends Node2D


const THICK_LINE_PATH := NodePath("PathLine/Line")
const THIN_LINE_PATH := NodePath("StraightPart/Line")
const NOISE_OFFSET_PARAMETER := &"noise_offset"
const LARGE_NOISE_OFFSET_PARAMETER := &"large_noise_offset"

const THICK_OFFSET_SEED_SALT := 0x13579BDF
const THIN_OFFSET_SEED_SALT := 0x2468ACE0
const LARGE_OFFSET_SEED_SALT := 0x1B873593
const LINE_SEED_STEP := 1_000_003
const GOLDEN_RATIO_FRACTION := 0.61803398875


## MagicCircle 内のライン番号から、太線・細線に再現可能なノイズ座標オフセットを設定する。
func set_noise_variant(line_index: int) -> void:
	_apply_thick_line_offsets(
		_make_noise_offset(line_index, THICK_OFFSET_SEED_SALT),
		_make_large_noise_offset(line_index),
	)
	_apply_unique_material_noise_offset(
		THIN_LINE_PATH,
		_make_noise_offset(line_index, THIN_OFFSET_SEED_SALT),
	)


## 太線はノードプレビューを維持するため、ラインごとに複製したマテリアルの通常Uniformを使う。
func _apply_thick_line_offsets(noise_offset: Vector3, large_noise_offset: Vector2) -> void:
	var line := get_node_or_null(THICK_LINE_PATH) as Line2D
	if line == null:
		return

	var source_material := line.material as ShaderMaterial
	if source_material == null:
		return

	var unique_material := source_material.duplicate() as ShaderMaterial
	unique_material.set_shader_parameter(NOISE_OFFSET_PARAMETER, noise_offset)
	unique_material.set_shader_parameter(LARGE_NOISE_OFFSET_PARAMETER, large_noise_offset)
	line.material = unique_material


## 細線も個別マテリアルの通常Uniformを使い、Visual Shaderのプレビューを維持する。
func _apply_unique_material_noise_offset(line_path: NodePath, noise_offset: Vector3) -> void:
	var line := get_node_or_null(line_path) as Line2D
	if line == null:
		return

	var source_material := line.material as ShaderMaterial
	if source_material == null:
		return

	var unique_material := source_material.duplicate() as ShaderMaterial
	unique_material.set_shader_parameter(NOISE_OFFSET_PARAMETER, noise_offset)
	line.material = unique_material


func _make_noise_offset(line_index: int, seed_salt: int) -> Vector3:
	var rng := RandomNumberGenerator.new()
	var safe_line_index := maxi(line_index, 0)
	rng.seed = seed_salt + safe_line_index * LINE_SEED_STEP
	var z_phase := fposmod(float(safe_line_index) * GOLDEN_RATIO_FRACTION, 1.0)
	return Vector3(rng.randf(), rng.randf(), z_phase)


func _make_large_noise_offset(line_index: int) -> Vector2:
	var rng := RandomNumberGenerator.new()
	var safe_line_index := maxi(line_index, 0)
	rng.seed = LARGE_OFFSET_SEED_SALT + safe_line_index * LINE_SEED_STEP
	return Vector2(rng.randf(), rng.randf())
