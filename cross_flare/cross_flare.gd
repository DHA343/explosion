@tool
class_name CrossFlare
extends MeshInstance3D

signal finished

enum Variant {
	CROSS_ONLY,
	SINGLE_RING,
	DOUBLE_RING,
}

const MIN_DURATION: float = 0.1
const MIN_TIMING_SPAN: float = 0.001

@export var variant: Variant = Variant.SINGLE_RING:
	set(value):
		variant = value
		_update_variant_size_parameters()

@export var variant_random: bool = true

@export_range(0.1, 5.0, 0.05, "suffix:m") var size: float = 0.675:
	set(value):
		size = clampf(value, 0.1, 5.0)
		_update_variant_size_parameters()
		custom_aabb = AABB(Vector3.ONE * -size * 1.5, Vector3.ONE * size * 3.0)

@export_range(0.0, 1.0, 0.01) var size_random_ratio: float = 0.33

@export_range(0.0, 8.0, 0.05) var intensity: float = 1.6:
	set(value):
		intensity = clampf(value, 0.0, 8.0)
		_update_effect_parameters()

@export var palette: ShaderMaterial:
	set(value):
		palette = value
		material_override = value

@export_group("Rotation")
@export_range(-180.0, 180.0, 1.0, "degrees") var angle: float = 0.0:
	set(value):
		angle = value
		_update_rotation()

@export_range(0.0, 180.0, 1.0, "degrees") var angle_random: float = 180.0

@export_range(0.0, 10.0, 0.1, "suffix:rad/s") var rotation_speed: float = 5.17:
	set(value):
		rotation_speed = clampf(value, 0.0, 10.0)
		_update_rotation()

@export_range(0.0, 1.0, 0.01) var rotation_speed_random_ratio: float = 0.13

@export_group("Playback")
@export_range(MIN_DURATION, 1.0, 0.01, "suffix:s") var duration: float = 0.45:
	set(value):
		duration = clampf(value, MIN_DURATION, 1.0)
		_elapsed = minf(_elapsed, duration)
		_update_effect_parameters()

@export_range(0.0, 1.0, 0.01) var duration_random_ratio: float = 0.11

@export var autoplay: bool = true

@export var stepped: bool = true:
	set(value):
		stepped = value
		_update_stepped_parameters()

@export_range(1.0, 60.0, 1.0, "suffix:fps") var stepped_fps: float = 24.0:
	set(value):
		stepped_fps = clampf(value, 1.0, 60.0)
		_update_stepped_parameters()

@export_group("Motion Timing")
@export_range(0.0, 1.0, 0.01) var growth_end: float = 0.55:
	set(value):
		growth_end = clampf(value, 0.0, 1.0)
		_update_motion_timing()

@export_range(0.0, 1.0, 0.01) var width_fade_start: float = 0.6:
	set(value):
		width_fade_start = clampf(value, 0.0, 1.0)
		width_fade_start = minf(width_fade_start, maxf(0.0, width_fade_end - MIN_TIMING_SPAN))
		_update_motion_timing()

@export_range(0.0, 1.0, 0.01) var width_fade_end: float = 0.8:
	set(value):
		width_fade_end = clampf(value, 0.0, 1.0)
		width_fade_end = maxf(width_fade_end, minf(1.0, width_fade_start + MIN_TIMING_SPAN))
		_update_motion_timing()

@export_range(0.0, 1.0, 0.01) var shrink_start: float = 0.6:
	set(value):
		shrink_start = clampf(value, 0.0, 1.0)
		shrink_start = minf(shrink_start, maxf(0.0, shrink_end - MIN_TIMING_SPAN))
		_update_motion_timing()

@export_range(0.0, 1.0, 0.01) var shrink_end: float = 0.8:
	set(value):
		shrink_end = clampf(value, 0.0, 1.0)
		shrink_end = maxf(shrink_end, minf(1.0, shrink_start + MIN_TIMING_SPAN))
		_update_motion_timing()

@export_range(0.0, 1.0, 0.01) var shortening_start: float = 0.7:
	set(value):
		shortening_start = clampf(value, 0.0, 1.0)
		shortening_start = minf(shortening_start, maxf(0.0, shortening_end - MIN_TIMING_SPAN))
		_update_motion_timing()

@export_range(0.0, 1.0, 0.01) var shortening_end: float = 0.9:
	set(value):
		shortening_end = clampf(value, 0.0, 1.0)
		shortening_end = maxf(shortening_end, minf(1.0, shortening_start + MIN_TIMING_SPAN))
		_update_motion_timing()

@export_range(0.0, 1.0, 0.01) var stretch_start: float = 0.72:
	set(value):
		stretch_start = clampf(value, 0.0, 1.0)
		stretch_start = minf(stretch_start, maxf(0.0, stretch_end - MIN_TIMING_SPAN))
		_update_motion_timing()

@export_range(0.0, 1.0, 0.01) var stretch_end: float = 1.0:
	set(value):
		stretch_end = clampf(value, 0.0, 1.0)
		stretch_end = maxf(stretch_end, minf(1.0, stretch_start + MIN_TIMING_SPAN))
		_update_motion_timing()

@export_group("Color Flow")
@export_range(0.0, 1.0, 0.01) var flow_position_random: float = 0.5

@export_group("Ring Shape")
@export_range(0.01, 0.15, 0.005) var ring_peak_width: float = 0.065:
	set(value):
		ring_peak_width = value
		_update_ring_shape_parameters()

@export_range(0.1, 0.8, 0.01) var ring_min_width_ratio: float = 0.4:
	set(value):
		ring_min_width_ratio = value
		_update_ring_shape_parameters()

@export_group("Ring Breakup")
@export_range(0, 9999, 1) var split_seed: int = 1:
	set(value):
		split_seed = value
		_update_style()

@export var split_seed_random: bool = true

@export_range(3, 5, 1) var island_count: int = 4:
	set(value):
		island_count = value
		_update_style()

@export_range(-180.0, 180.0, 1.0, "degrees") var split_direction: float = 180.0:
	set(value):
		split_direction = value
		_update_style()

@export_range(30.0, 360.0, 1.0, "degrees") var split_range: float = 160.0:
	set(value):
		split_range = value
		_update_style()

@export var double_full_circle: bool = true:
	set(value):
		double_full_circle = value
		_update_style()

@export_range(0.0, 1.0, 0.01) var split_irregularity: float = 0.65:
	set(value):
		split_irregularity = value
		_update_style()

@export_range(0.0, 1.0, 0.01) var gap_ratio: float = 0.85:
	set(value):
		gap_ratio = clampf(value, 0.0, 1.0)
		_update_style()

@export_range(0.0, 1.0, 0.01) var split_start: float = 0.29:
	set(value):
		split_start = value
		split_start = clampf(split_start, 0.0, 1.0)
		split_start = minf(split_start, maxf(0.0, split_end - MIN_TIMING_SPAN))
		_update_style()

@export_range(0.0, 1.0, 0.01) var split_end: float = 0.40:
	set(value):
		split_end = clampf(value, 0.0, 1.0)
		split_end = maxf(split_end, minf(1.0, split_start + MIN_TIMING_SPAN))
		_update_style()

@export_group("Tail")
@export_range(0.0, 1.0, 0.01) var tail_breakup_strength: float = 0.0:
	set(value):
		tail_breakup_strength = value
		_update_tail_parameters()

@export_range(0.0, 1.0, 0.01) var tail_breakup_start: float = 0.84:
	set(value):
		tail_breakup_start = value
		_update_tail_parameters()

@export_range(3, 6, 1) var tail_fragment_count: int = 4:
	set(value):
		tail_fragment_count = value
		_update_tail_parameters()

@export_range(0.0, 1.0, 0.01) var tail_irregularity: float = 0.65:
	set(value):
		tail_irregularity = value
		_update_tail_parameters()

@export_range(0.0, 1.0, 0.01) var tail_width_ratio: float = 0.30:
	set(value):
		tail_width_ratio = value
		_update_tail_parameters()

@export_group("Halo")
@export_range(0.0, 1.0, 0.01) var halo_strength: float = 0.3:
	set(value):
		halo_strength = value
		_update_effect_parameters()

@export_range(0.005, 0.20, 0.005) var halo_width: float = 0.06:
	set(value):
		halo_width = maxf(value, 0.005)
		_update_effect_parameters()

var playing: bool = false
var _elapsed: float = 0.0
var _flow_direction: float = 0.0
var _flow_position: float = 0.0


func _ready() -> void:
	if not Engine.is_editor_hint():
		if variant_random:
			variant = randi_range(Variant.CROSS_ONLY, Variant.DOUBLE_RING)
		size *= 1.0 + randf_range(-size_random_ratio, size_random_ratio)
		size = clampf(size, 0.1, 5.0)
		rotation_speed *= 1.0 + randf_range(-rotation_speed_random_ratio,
			rotation_speed_random_ratio)
		rotation_speed = clampf(rotation_speed, 0.0, 10.0)
		angle += randf_range(-angle_random, angle_random)
		angle = fposmod(angle + 180.0, 360.0) - 180.0
		duration *= 1.0 + randf_range(-duration_random_ratio, duration_random_ratio)
		duration = clampf(duration, MIN_DURATION, 1.0)
		_flow_direction = randf_range(-PI, PI)
		_flow_position = randf_range(-flow_position_random, flow_position_random)

		if split_seed_random:
			split_seed = randi_range(0, 9999)

	if palette == null:
		push_error("CrossFlare requires a ShaderMaterial palette.")
	else:
		material_override = palette

	_update_style()
	_update_variant_size_parameters()
	_update_effect_parameters()
	_update_rotation()
	_update_stepped_parameters()
	_update_color_flow_parameters()
	_update_motion_timing()
	_update_ring_shape_parameters()
	_update_tail_parameters()
	set_instance_shader_parameter(&"progress", 0.0)
	custom_aabb = AABB(Vector3.ONE * -size * 1.5, Vector3.ONE * size * 3.0)
	seek(0.0)
	if not Engine.is_editor_hint() and autoplay:
		play()


func _process(delta: float) -> void:
	if playing and not Engine.is_editor_hint():
		seek(_elapsed + delta)
		if _elapsed >= duration:
			playing = false
			finished.emit()


func play() -> void:
	seek(0.0)
	playing = true


func seek(seconds: float) -> void:
	_elapsed = clampf(seconds, 0.0, duration)
	var progress := _elapsed / duration
	set_instance_shader_parameter(&"progress", progress)


func _update_style() -> void:
	set_instance_shader_parameter(&"breakup_shape",
		Vector4(deg_to_rad(split_direction), deg_to_rad(split_range), island_count, split_irregularity))
	set_instance_shader_parameter(&"breakup_time",
		Vector4(split_start, split_end, gap_ratio, 0.0 if double_full_circle else 1.0))
	set_instance_shader_parameter(&"breakup_seed", float(split_seed))


func _update_effect_parameters() -> void:
	set_instance_shader_parameter(&"effect_parameters",
		Vector4(intensity, duration, halo_strength, halo_width))


func _update_color_flow_parameters() -> void:
	set_instance_shader_parameter(&"color_flow_parameters", Vector2(_flow_direction, _flow_position))


func _update_motion_timing() -> void:
	set_instance_shader_parameter(&"motion_timing_a",
		Vector4(growth_end, width_fade_start, width_fade_end, shrink_start))
	set_instance_shader_parameter(&"motion_timing_b",
		Vector4(shrink_end, shortening_start, shortening_end, stretch_start))
	set_instance_shader_parameter(&"motion_timing_c", Vector2(stretch_end, tail_width_ratio))


func _update_ring_shape_parameters() -> void:
	set_instance_shader_parameter(&"ring_shape", Vector2(ring_peak_width, ring_min_width_ratio))


func _update_tail_parameters() -> void:
	set_instance_shader_parameter(&"tail_parameters",
		Vector4(tail_breakup_strength, tail_breakup_start, tail_fragment_count, tail_irregularity))
	_update_motion_timing()


func _update_variant_size_parameters() -> void:
	set_instance_shader_parameter(&"variant_size", Vector2(variant, size))


func _update_stepped_parameters() -> void:
	set_instance_shader_parameter(&"stepped_parameters", Vector2(1.0 if stepped else 0.0, stepped_fps))


func _update_rotation() -> void:
	set_instance_shader_parameter(&"initial_angle", deg_to_rad(angle))
	set_instance_shader_parameter(&"rotation_speed_radians", rotation_speed)
