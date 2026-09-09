class_name CrossFlareRandomization
extends Resource

const MIN_DURATION: float = 0.1

@export_flags("Cross Only", "Single Ring", "Double Ring") var variant_mask: int = 7

@export_group("Size")
@export_range(0.05, 20.0, 0.05, "suffix:m") var size_min: float = 1.0
@export_range(0.05, 20.0, 0.05, "suffix:m") var size_max: float = 1.0

@export_group("Brightness")
@export_range(0.0, 8.0, 0.05) var brightness_base: float = 1.6
@export_range(0.0, 8.0, 0.05) var brightness_random: float = 0.0

@export_group("Angle")
@export_range(-180.0, 180.0, 1.0, "degrees") var angle_base: float = 0.0
@export_range(0.0, 180.0, 1.0, "degrees") var angle_random: float = 0.0

@export_group("Duration")
@export_range(MIN_DURATION, 1.0, 0.01, "suffix:s") var duration_base: float = 0.5
@export_range(0.0, 1.0, 0.01, "suffix:s") var duration_random: float = 0.0

@export_group("Color Flow")
@export_range(0.0, 4.0, 0.01) var flow_speed_random: float = 0.0
@export_range(0.0, 180.0, 1.0, "degrees") var flow_direction_random: float = 0.0
@export_range(0.0, 1.0, 0.01) var flow_position_random: float = 0.0
@export_range(0.0, 2.0, 0.01) var flow_width_random: float = 0.0

@export_group("Ring Breakup")
@export_range(3, 5, 1) var island_count_min: int = 4
@export_range(3, 5, 1) var island_count_max: int = 4
@export_range(-180.0, 180.0, 1.0, "degrees") var split_direction_base: float = 180.0
@export_range(0.0, 180.0, 1.0, "degrees") var split_direction_random: float = 0.0
@export_range(30.0, 360.0, 1.0, "degrees") var split_range_base: float = 160.0
@export_range(0.0, 180.0, 1.0, "degrees") var split_range_random: float = 0.0
@export_range(0.0, 1.0, 0.01) var split_irregularity_base: float = 0.65
@export_range(0.0, 1.0, 0.01) var split_irregularity_random: float = 0.0
@export_range(0.1, 0.65, 0.01) var gap_ratio_base: float = 0.55
@export_range(0.0, 0.55, 0.01) var gap_ratio_random: float = 0.0
@export_range(0.0, 0.45, 0.005) var split_start_base: float = 0.29
@export_range(0.0, 0.45, 0.005) var split_start_random: float = 0.0
@export_range(0.0, 0.46, 0.005) var split_end_base: float = 0.40
@export_range(0.0, 0.46, 0.005) var split_end_random: float = 0.0

@export_group("Halo")
@export_range(0.0, 1.0, 0.01) var halo_strength_base: float = 0.3
@export_range(0.0, 1.0, 0.01) var halo_strength_random: float = 0.0


func apply_to(flare: CrossFlare, rng: RandomNumberGenerator) -> void:
	flare.variant = _sample_variant(rng)
	flare.size = clampf(_sample_min_max(size_min, size_max, rng), 0.05, 20.0)
	flare.brightness = maxf(_sample_base_random(brightness_base, brightness_random, rng), 0.0)
	flare.angle = _normalize_angle_degrees(_sample_base_random(angle_base, angle_random, rng))
	flare.duration = maxf(_sample_base_random(duration_base, duration_random, rng), MIN_DURATION)

	flare.flow_speed_offset = _sample_symmetric(flow_speed_random, rng)
	flare.flow_direction_offset = _sample_symmetric(flow_direction_random, rng)
	flare.flow_position_offset = _sample_symmetric(flow_position_random, rng)
	flare.flow_width_offset = _sample_symmetric(flow_width_random, rng)

	flare.split_seed = rng.randi_range(0, 9999)
	flare.island_count = _sample_int_min_max(island_count_min, island_count_max, rng)
	flare.split_direction = _normalize_angle_degrees(
		_sample_base_random(split_direction_base, split_direction_random, rng))
	flare.split_range = clampf(
		_sample_base_random(split_range_base, split_range_random, rng), 30.0, 360.0)
	flare.split_irregularity = clampf(
		_sample_base_random(split_irregularity_base, split_irregularity_random, rng), 0.0, 1.0)
	flare.gap_ratio = clampf(
		_sample_base_random(gap_ratio_base, gap_ratio_random, rng), 0.1, 0.65)

	var sampled_start := clampf(
		_sample_base_random(split_start_base, split_start_random, rng), 0.0, 0.45)
	var sampled_end := clampf(
		_sample_base_random(split_end_base, split_end_random, rng), 0.0, 0.46)
	sampled_end = maxf(sampled_end, sampled_start + 0.001)
	flare.split_start = sampled_start
	flare.split_end = minf(sampled_end, 0.46)

	flare.halo_strength = clampf(
		_sample_base_random(halo_strength_base, halo_strength_random, rng), 0.0, 1.0)


func _sample_variant(rng: RandomNumberGenerator) -> CrossFlare.Variant:
	var variants: Array[CrossFlare.Variant] = []
	for variant_value: CrossFlare.Variant in [
		CrossFlare.Variant.CROSS_ONLY,
		CrossFlare.Variant.SINGLE_RING,
		CrossFlare.Variant.DOUBLE_RING,
	]:
		if variant_mask & (1 << int(variant_value)):
			variants.append(variant_value)
	if variants.is_empty():
		return CrossFlare.Variant.SINGLE_RING
	return variants[rng.randi_range(0, variants.size() - 1)]


func _sample_min_max(minimum_value: float, maximum_value: float,
		rng: RandomNumberGenerator) -> float:
	var minimum := minf(minimum_value, maximum_value)
	var maximum := maxf(minimum_value, maximum_value)
	return rng.randf_range(minimum, maximum)


func _sample_int_min_max(minimum_value: int, maximum_value: int,
		rng: RandomNumberGenerator) -> int:
	var minimum := mini(minimum_value, maximum_value)
	var maximum := maxi(minimum_value, maximum_value)
	return clampi(rng.randi_range(minimum, maximum), 3, 5)


func _sample_base_random(base: float, random_width: float,
		rng: RandomNumberGenerator) -> float:
	return base + rng.randf_range(-absf(random_width), absf(random_width))


func _sample_symmetric(random_width: float, rng: RandomNumberGenerator) -> float:
	return rng.randf_range(-absf(random_width), absf(random_width))


func _normalize_angle_degrees(value: float) -> float:
	return fposmod(value + 180.0, 360.0) - 180.0
