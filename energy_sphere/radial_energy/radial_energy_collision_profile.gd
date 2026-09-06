class_name RadialEnergyCollisionProfile
extends Resource

@export_group("Approach")
@export_range(0.05, 2.0, 0.01, "suffix:s") var approach_duration: float = 0.17
@export_range(0.0, 1.0, 0.01, "suffix:s") var approach_duration_variation: float = 0.03
@export_range(1.0, 8.0, 0.1) var movement_power: float = 1.8

@export_group("Impact Response")
@export_range(0.05, 2.0, 0.01, "suffix:s") var impact_response_duration: float = 0.09
@export_range(0.01, 2.0, 0.01, "suffix:s") var fade_duration: float = 0.09

@export_group("Disappearance")
@export_range(0.0, 2.0, 0.01) var length_end_scale: float = 0.0
@export_range(0.1, 8.0, 0.1) var length_change_power: float = 1.2
@export_range(0.05, 0.95, 0.01) var peak_end_position_ratio: float = 0.75
@export_range(0.0, 2.0, 0.01) var thickness_end_scale: float = 1.6
@export_range(0.1, 8.0, 0.1) var thickness_change_power: float = 1.5
@export_range(0.1, 8.0, 0.1) var fade_power: float = 1.2

@export_group("Impact Mark")
@export_range(0.0, 1.0, 0.01) var impact_mark_opacity: float = 0.5
@export_range(0.01, 1.0, 0.01) var impact_mark_softness: float = 0.35
@export_range(0.1, 4.0, 0.01) var impact_mark_size_multiplier: float = 1.5
