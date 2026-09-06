class_name RadialEnergyMissProfile
extends Resource

@export_group("Travel")
@export_range(0.05, 2.0, 0.01, "suffix:s") var travel_duration: float = 0.26
@export_range(0.0, 1.0, 0.01, "suffix:s") var travel_duration_variation: float = 0.05
@export_range(1.0, 8.0, 0.1) var movement_power: float = 1.8
@export_range(0.1, 0.99, 0.01) var radius_ratio_min: float = 0.80
@export_range(0.1, 0.99, 0.01) var radius_ratio_max: float = 0.95

@export_group("Disappearance")
@export_range(0.01, 2.0, 0.01, "suffix:s") var fade_duration: float = 0.18
@export_range(0.0, 2.0, 0.01) var length_end_scale: float = 0.8
@export_range(0.1, 8.0, 0.1) var length_change_power: float = 1.2
@export_range(0.0, 2.0, 0.01) var thickness_end_scale: float = 0.0
@export_range(0.1, 8.0, 0.1) var thickness_change_power: float = 1.5
@export_range(0.1, 8.0, 0.1) var fade_power: float = 1.2
