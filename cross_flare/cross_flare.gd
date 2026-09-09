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

@export var variant: Variant = Variant.SINGLE_RING:
	set(value):
		variant = value
		set_instance_shader_parameter(&"variant", value)

@export var variant_random: bool = true

@export_range(0.05, 20.0, 0.05, "suffix:m") var size: float = 1.0:
	set(value):
		size = value
		set_instance_shader_parameter(&"flare_size", value)
		custom_aabb = AABB(Vector3.ONE * -value * 1.5, Vector3.ONE * value * 3.0)

@export_range(0.0, 20.0, 0.05, "suffix:m") var size_random: float = 0.225

@export_range(0.0, 8.0, 0.05) var brightness: float = 1.6:
	set(value):
		brightness = value
		set_instance_shader_parameter(&"brightness", value)

@export_range(0.0, 8.0, 0.05) var brightness_random: float = 0.25

@export var palette: ShaderMaterial:
	set(value):
		palette = value
		material_override = value

@export_range(-180.0, 180.0, 1.0, "degrees") var angle: float = 0.0:
	set(value):
		angle = value
		_update_rotation()

@export_range(0.0, 180.0, 1.0, "degrees") var angle_random: float = 180.0

@export_range(0.0, 2.0, 0.01) var rotation_amount: float = 1.0:
	set(value):
		rotation_amount = value
		_update_rotation()

@export_range(0.0, 0.8, 0.01) var rotation_slowdown_start: float = 0.25:
	set(value):
		rotation_slowdown_start = value
		_update_rotation()

@export_range(0.0, 0.95, 0.01) var rotation_slowdown_strength: float = 0.9:
	set(value):
		rotation_slowdown_strength = value
		_update_rotation()

@export_range(MIN_DURATION, 1.0, 0.01, "suffix:s") var duration: float = 0.5:
	set(value):
		duration = maxf(value, MIN_DURATION)
		_elapsed = minf(_elapsed, duration)
		set_instance_shader_parameter(&"duration", duration)

@export_range(0.0, 1.0, 0.01, "suffix:s") var duration_random: float = 0.12

@export var autoplay: bool = true

@export var stepped: bool = false:
	set(value):
		stepped = value
		set_instance_shader_parameter(&"stepped", value)

@export_range(1.0, 60.0, 1.0, "suffix:fps") var stepped_fps: float = 24.0:
	set(value):
		stepped_fps = clampf(value, 1.0, 60.0)
		set_instance_shader_parameter(&"stepped_fps", stepped_fps)

@export_group("Color Flow")
@export var flow_speed_offset: float = 0.0:
	set(value):
		flow_speed_offset = value
		set_instance_shader_parameter(&"flow_speed_offset", value)

@export_range(0.0, 4.0, 0.01) var flow_speed_random: float = 0.35

@export_range(-180.0, 180.0, 1.0, "degrees") var flow_direction_offset: float = 0.0:
	set(value):
		flow_direction_offset = value
		set_instance_shader_parameter(&"flow_direction_offset", deg_to_rad(value))

@export_range(0.0, 180.0, 1.0, "degrees") var flow_direction_random: float = 30.0

@export_range(-1.0, 1.0, 0.01) var flow_position_offset: float = 0.0:
	set(value):
		flow_position_offset = value
		set_instance_shader_parameter(&"flow_position_offset", value)

@export_range(0.0, 1.0, 0.01) var flow_position_random: float = 0.25

@export_range(-2.0, 2.0, 0.01) var flow_width_offset: float = 0.0:
	set(value):
		flow_width_offset = value
		set_instance_shader_parameter(&"flow_width_offset", value)

@export_range(0.0, 2.0, 0.01) var flow_width_random: float = 0.20

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

@export_range(0, 2, 1) var island_count_random: int = 1

@export_range(-180.0, 180.0, 1.0, "degrees") var split_direction: float = 180.0:
	set(value):
		split_direction = value
		_update_style()

@export_range(0.0, 180.0, 1.0, "degrees") var split_direction_random: float = 45.0

@export_range(30.0, 360.0, 1.0, "degrees") var split_range: float = 160.0:
	set(value):
		split_range = value
		_update_style()

@export_range(0.0, 180.0, 1.0, "degrees") var split_range_random: float = 40.0

@export var double_full_circle: bool = true:
	set(value):
		double_full_circle = value
		_update_style()

@export_range(0.0, 1.0, 0.01) var split_irregularity: float = 0.65:
	set(value):
		split_irregularity = value
		_update_style()

@export_range(0.0, 1.0, 0.01) var split_irregularity_random: float = 0.20

@export_range(0.1, 0.65, 0.01) var gap_ratio: float = 0.55:
	set(value):
		gap_ratio = value
		_update_style()

@export_range(0.0, 0.55, 0.01) var gap_ratio_random: float = 0.08

@export_range(0.0, 0.45, 0.005) var split_start: float = 0.29:
	set(value):
		split_start = value
		_update_style()

@export_range(0.0, 0.45, 0.005) var split_start_random: float = 0.04

@export_range(0.0, 0.46, 0.005) var split_end: float = 0.40:
	set(value):
		split_end = value
		_update_style()

@export_range(0.0, 0.46, 0.005) var split_end_random: float = 0.04

@export_group("Edges")
@export_range(0.0, 0.04, 0.001) var edge_softness: float = 0.008:
	set(value):
		edge_softness = value
		_update_style()

@export_range(0.0, 1.0, 0.01) var halo_strength: float = 0.3:
	set(value):
		halo_strength = value
		_update_style()

@export_range(0.0, 1.0, 0.01) var halo_strength_random: float = 0.08

var playing: bool = false
var _elapsed: float = 0.0


func _ready() -> void:
	if not Engine.is_editor_hint():
		if variant_random:
			variant = randi_range(Variant.CROSS_ONLY, Variant.DOUBLE_RING)
		size += randf_range(-size_random, size_random)
		size = clampf(size, 0.05, 20.0)
		brightness += randf_range(-brightness_random, brightness_random)
		brightness = clampf(brightness, 0.0, 8.0)
		angle += randf_range(-angle_random, angle_random)
		angle = fposmod(angle + 180.0, 360.0) - 180.0
		duration += randf_range(-duration_random, duration_random)
		duration = clampf(duration, MIN_DURATION, 1.0)

		flow_speed_offset += randf_range(-flow_speed_random, flow_speed_random)
		flow_direction_offset += randf_range(-flow_direction_random, flow_direction_random)
		flow_direction_offset = fposmod(flow_direction_offset + 180.0, 360.0) - 180.0
		flow_position_offset += randf_range(-flow_position_random, flow_position_random)
		flow_position_offset = clampf(flow_position_offset, -1.0, 1.0)
		flow_width_offset += randf_range(-flow_width_random, flow_width_random)
		flow_width_offset = clampf(flow_width_offset, -2.0, 2.0)

		if split_seed_random:
			split_seed = randi_range(0, 9999)
		island_count += randi_range(-island_count_random, island_count_random)
		island_count = clampi(island_count, 3, 5)
		split_direction += randf_range(-split_direction_random, split_direction_random)
		split_direction = fposmod(split_direction + 180.0, 360.0) - 180.0
		split_range += randf_range(-split_range_random, split_range_random)
		split_range = clampf(split_range, 30.0, 360.0)
		split_irregularity += randf_range(-split_irregularity_random, split_irregularity_random)
		split_irregularity = clampf(split_irregularity, 0.0, 1.0)
		gap_ratio += randf_range(-gap_ratio_random, gap_ratio_random)
		gap_ratio = clampf(gap_ratio, 0.1, 0.65)
		split_start += randf_range(-split_start_random, split_start_random)
		split_start = clampf(split_start, 0.0, 0.45)
		split_end += randf_range(-split_end_random, split_end_random)
		split_end = clampf(split_end, 0.0, 0.46)
		split_end = maxf(split_end, split_start + 0.001)
		split_end = minf(split_end, 0.46)
		halo_strength += randf_range(-halo_strength_random, halo_strength_random)
		halo_strength = clampf(halo_strength, 0.0, 1.0)

	if palette == null:
		push_error("CrossFlare requires a ShaderMaterial palette.")
	else:
		material_override = palette

	_update_style()
	set_instance_shader_parameter(&"variant", variant)
	set_instance_shader_parameter(&"flare_size", size)
	set_instance_shader_parameter(&"brightness", brightness)
	_update_rotation()
	set_instance_shader_parameter(&"stepped", stepped)
	set_instance_shader_parameter(&"stepped_fps", stepped_fps)
	set_instance_shader_parameter(&"duration", duration)
	set_instance_shader_parameter(&"flow_speed_offset", flow_speed_offset)
	set_instance_shader_parameter(&"flow_direction_offset", deg_to_rad(flow_direction_offset))
	set_instance_shader_parameter(&"flow_position_offset", flow_position_offset)
	set_instance_shader_parameter(&"flow_width_offset", flow_width_offset)
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
	set_instance_shader_parameter(&"edge_style", Vector2(edge_softness, halo_strength))


func _update_rotation() -> void:
	set_instance_shader_parameter(&"rotation_profile", Vector4(deg_to_rad(angle),
		rotation_amount, rotation_slowdown_start, rotation_slowdown_strength))
