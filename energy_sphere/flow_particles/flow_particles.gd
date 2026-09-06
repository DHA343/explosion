@tool
class_name FlowParticles
extends Node3D

@export_range(8, 12, 1) var cluster_count: int = 10:
	set(value):
		cluster_count = value
		if is_node_ready():
			_update_cluster_activation()

@export var seed: int = 343:
	set(value):
		seed = value
		if is_node_ready():
			_sync_clusters()

@export_group("Cluster")
@export_range(1.0, 10.0, 0.1, "suffix:s") var cluster_lifetime_min: float = 3.0
@export_range(1.0, 10.0, 0.1, "suffix:s") var cluster_lifetime_max: float = 6.0
@export_range(1.0, 1.3, 0.01) var cluster_radius_min_ratio: float = 1.0
@export_range(1.0, 1.5, 0.01) var cluster_radius_max_ratio: float = 1.12
@export_range(0.5, 4.0, 0.05) var cluster_radius_bias: float = 2.0
@export_range(0.0, 0.15, 0.005) var cluster_radial_wander_ratio: float = 0.04
@export_range(0.1, 8.0, 0.1) var cluster_radial_follow: float = 2.0
@export_range(0.0, 0.4, 0.01) var cluster_outward_drift_ratio: float = 0.10

@export_group("Cluster Motion")
@export_range(0.05, 1.5, 0.01) var cluster_speed: float = 0.45
@export_range(0.0, 0.5, 0.01) var cluster_speed_variation: float = 0.25
@export_range(0.1, 4.0, 0.05) var cluster_flow_scale: float = 0.8
@export_range(0.0, 2.0, 0.01) var cluster_flow_evolution_speed: float = 0.25
@export_range(0.0, 2.0, 0.01) var cluster_steering_strength: float = 0.8
@export_range(1.0, 90.0, 1.0, "suffix:°/s") var cluster_max_turn_speed: float = 35.0

@export_group("Plume")
@export_range(0.1, 1.5, 0.01) var plume_length_ratio: float = 0.45
@export_range(0.05, 0.8, 0.01) var plume_width_ratio: float = 0.18
@export_range(0.0, 0.95, 0.01) var plume_taper: float = 0.75
@export_range(0.5, 5.0, 0.05) var plume_density_power: float = 2.0
@export_range(0.0, 0.5, 0.01) var cluster_size_variation: float = 0.25

@export_group("Particles")
@export_range(64, 384, 1) var particles_per_cluster: int = 180
@export_range(0.5, 4.0, 0.05, "suffix:s") var particle_lifetime_min: float = 1.0
@export_range(0.5, 4.0, 0.05, "suffix:s") var particle_lifetime_max: float = 2.0
@export_range(0.002, 0.1, 0.001) var particle_size_min_ratio: float = 0.010
@export_range(0.002, 0.1, 0.001) var particle_size_max_ratio: float = 0.020
@export_range(0.0, 1.0, 0.01) var plume_outward_speed: float = 0.12
@export_range(0.0, 1.0, 0.01) var plume_bend_strength: float = 0.16
@export_range(0.0, 2.0, 0.01) var plume_bend_speed: float = 0.45

@export_group("Particle Turbulence")
@export_range(0.0, 1.5, 0.01) var particle_turbulence_strength: float = 0.22
@export_range(0.1, 8.0, 0.05) var particle_turbulence_scale: float = 3.0
@export_range(0.0, 2.0, 0.01) var particle_turbulence_speed: float = 0.65
@export_range(0.0, 1.0, 0.01) var particle_radial_turbulence: float = 0.35
@export_range(0.0, 8.0, 0.05) var plume_cohesion: float = 2.0

@export_group("Color")
@export var purple_color: Color = Color(0.54, 0.24, 1.0, 1.0)
@export var cyan_color: Color = Color(0.15, 0.88, 1.0, 1.0)
@export_range(0.0, 1.0, 0.01) var cyan_ratio: float = 0.50
@export_range(0.0, 0.5, 0.01) var cluster_brightness_variation: float = 0.25
@export_range(0.0, 0.3, 0.01) var cluster_saturation_variation: float = 0.10
@export_range(0.0, 0.3, 0.01) var particle_brightness_variation: float = 0.12

@export_group("Appearance")
@export_range(0.0, 0.3, 0.01) var cluster_pulse_amount: float = 0.10
@export_range(0.1, 4.0, 0.05) var cluster_pulse_speed: float = 1.2
@export_range(0.0, 1.0, 0.01) var opacity: float = 0.60
@export_range(0.0, 8.0, 0.05) var emission_strength: float = 2.2

@export_group("View")
@export_range(0.05, 1.0, 0.01) var silhouette_width: float = 0.65
@export_range(0.0, 1.0, 0.01) var front_back_opacity: float = 0.08

var radius: float = 0.5:
	set(value):
		radius = value
		if is_node_ready():
			_update_radius()

var _clusters: Array[FlowCluster] = []

@onready var _cluster01: FlowCluster = $Cluster01
@onready var _cluster02: FlowCluster = $Cluster02
@onready var _cluster03: FlowCluster = $Cluster03
@onready var _cluster04: FlowCluster = $Cluster04
@onready var _cluster05: FlowCluster = $Cluster05
@onready var _cluster06: FlowCluster = $Cluster06
@onready var _cluster07: FlowCluster = $Cluster07
@onready var _cluster08: FlowCluster = $Cluster08
@onready var _cluster09: FlowCluster = $Cluster09
@onready var _cluster10: FlowCluster = $Cluster10
@onready var _cluster11: FlowCluster = $Cluster11
@onready var _cluster12: FlowCluster = $Cluster12


func _ready() -> void:
	_clusters = [
		_cluster01, _cluster02, _cluster03, _cluster04, _cluster05, _cluster06,
		_cluster07, _cluster08, _cluster09, _cluster10, _cluster11, _cluster12
	]
	_sync_clusters()


func _sync_clusters() -> void:
	for index in _clusters.size():
		var cluster := _clusters[index]
		cluster.cluster_lifetime_min = cluster_lifetime_min
		cluster.cluster_lifetime_max = cluster_lifetime_max
		cluster.cluster_radius_min_ratio = cluster_radius_min_ratio
		cluster.cluster_radius_max_ratio = cluster_radius_max_ratio
		cluster.cluster_radius_bias = cluster_radius_bias
		cluster.cluster_radial_wander_ratio = cluster_radial_wander_ratio
		cluster.cluster_radial_follow = cluster_radial_follow
		cluster.cluster_outward_drift_ratio = cluster_outward_drift_ratio
		cluster.cluster_speed = cluster_speed
		cluster.cluster_speed_variation = cluster_speed_variation
		cluster.cluster_flow_scale = cluster_flow_scale
		cluster.cluster_flow_evolution_speed = cluster_flow_evolution_speed
		cluster.cluster_steering_strength = cluster_steering_strength
		cluster.cluster_max_turn_speed = cluster_max_turn_speed
		cluster.plume_length_ratio = plume_length_ratio
		cluster.plume_width_ratio = plume_width_ratio
		cluster.plume_taper = plume_taper
		cluster.plume_density_power = plume_density_power
		cluster.cluster_size_variation = cluster_size_variation
		cluster.particles_per_cluster = particles_per_cluster
		cluster.particle_lifetime_min = particle_lifetime_min
		cluster.particle_lifetime_max = particle_lifetime_max
		cluster.particle_size_min_ratio = particle_size_min_ratio
		cluster.particle_size_max_ratio = particle_size_max_ratio
		cluster.plume_outward_speed = plume_outward_speed
		cluster.plume_bend_strength = plume_bend_strength
		cluster.plume_bend_speed = plume_bend_speed
		cluster.particle_turbulence_strength = particle_turbulence_strength
		cluster.particle_turbulence_scale = particle_turbulence_scale
		cluster.particle_turbulence_speed = particle_turbulence_speed
		cluster.particle_radial_turbulence = particle_radial_turbulence
		cluster.plume_cohesion = plume_cohesion
		cluster.purple_color = purple_color
		cluster.cyan_color = cyan_color
		cluster.cyan_ratio = cyan_ratio
		cluster.cluster_brightness_variation = cluster_brightness_variation
		cluster.cluster_saturation_variation = cluster_saturation_variation
		cluster.particle_brightness_variation = particle_brightness_variation
		cluster.cluster_pulse_amount = cluster_pulse_amount
		cluster.cluster_pulse_speed = cluster_pulse_speed
		cluster.opacity = opacity
		cluster.emission_strength = emission_strength
		cluster.silhouette_width = silhouette_width
		cluster.front_back_opacity = front_back_opacity
		cluster.radius = radius
		cluster.update_visibility_aabb(plume_length_ratio, plume_width_ratio)
		cluster.initialize(seed + index * 7919, index < cluster_count)

	_update_cluster_activation()


func _update_cluster_activation() -> void:
	for index in _clusters.size():
		_clusters[index].set_enabled(index < cluster_count)


func _update_radius() -> void:
	for cluster in _clusters:
		cluster.radius = radius
		cluster.update_visibility_aabb(plume_length_ratio, plume_width_ratio)
