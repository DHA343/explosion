class_name MagicCircleSpawnProfile
extends Resource

@export_group("スポーン")
@export_range(-1.0, 1.0, 0.01, "suffix:s") var spawn_interval: float = -0.1

@export_group("リング上昇")
@export_range(0.0, 1.0, 0.01, "suffix:s") var ring_rise_duration: float = 0.4
@export var ring_rise_transition: Tween.TransitionType = Tween.TRANS_CUBIC
@export var ring_rise_ease: Tween.EaseType = Tween.EASE_OUT

@export_subgroup("リング表示")
@export_range(0.0, 1.0, 0.01, "suffix:s") var glow_reveal_duration: float = 0.08
@export_range(0.0, 1.0, 0.01, "suffix:s") var ring_reveal_duration: float = 0.4
@export var ring_reveal_transition: Tween.TransitionType = Tween.TRANS_QUAD
@export var ring_reveal_ease: Tween.EaseType = Tween.EASE_IN

@export_group("拡大")
@export_range(0.0, 1.0, 0.01, "suffix:s") var body_spawn_lead_time: float = 0.1
@export_range(0.0, 1.0, 0.01, "suffix:s") var scale_duration: float = 0.6
@export var scale_transition: Tween.TransitionType = Tween.TRANS_EXPO
@export var scale_ease: Tween.EaseType = Tween.EASE_OUT

@export_group("回転")
@export_range(0.0, 1000.0, 10.0, "suffix:x") var initial_speed_multiplier: float = 800.0
@export_range(0.0, 1.0, 0.01, "suffix:s") var rotation_duration: float = 0.7
@export var rotation_transition: Tween.TransitionType = Tween.TRANS_EXPO
@export var rotation_ease: Tween.EaseType = Tween.EASE_OUT
