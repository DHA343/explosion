@tool
class_name EnergySphere
extends Node3D

const STREAKS_TEXTURE_PARAMETER: StringName = &"streaks_texture"
const DISTORTION_TEXTURE_PARAMETER: StringName = &"captured_texture"
const SPHERE_RADIUS_PARAMETER: StringName = &"sphere_radius"

@export_range(0.01, 1.0, 0.01)
var radius: float = 0.5:
	set(value):
		radius = value
		if is_node_ready():
			_update_radius()

var _source_camera: Camera3D
var _spawn_progress: float = 1.0
var _radius_progress: float = 1.0
var _aura_started: bool = false

@onready var _streaks_viewport: SubViewport = $InflowStreaksViewport
@onready var _inflow_streaks: InflowStreaks = $InflowStreaks
@onready var _energy_shell: EnergyShell = $EnergyShell
@onready var _distortion_capture: DistortionCapture = $DistortionCapture
@onready var _distortion_viewport: SubViewport = $DistortionCapture/DistortionViewport
@onready var _distortion_shell: DistortionShell = $DistortionShell
@onready var _aura_flow: AuraFlow = $AuraFlow
@onready var _core_glow: MeshInstance3D = $CoreGlow
@onready var _core_color: MeshInstance3D = $CoreColor
@onready var _drift_particles: GPUParticles3D = $DriftParticles
@onready var _inflow_particles: GPUParticles3D = $InflowParticles
@onready var _spawn_animator: EnergySphereSpawnAnimator = $EnergySphereSpawnAnimator
@onready var _cross_flare_spawner: CrossFlareSpawner = $CrossFlareSpawner


func _ready() -> void:
	_update_radius()

	var material := _inflow_streaks.material_override as ShaderMaterial
	assert(material != null, "InflowStreaks requires a ShaderMaterial override.")

	# NOTE: シリアライズされたViewportTextureは3Dエディタのカスタムシェーダーで解決されない。
	# 両方の子がSceneTreeへ入った後にライブテクスチャを設定し、
	# エディタと実行時の出力を揃える。
	material.set_shader_parameter(
		STREAKS_TEXTURE_PARAMETER,
		_streaks_viewport.get_texture()
	)

	var distortion_material := _distortion_shell.material_override as ShaderMaterial
	assert(distortion_material != null, "DistortionShell requires a ShaderMaterial override.")
	distortion_material.set_shader_parameter(
		DISTORTION_TEXTURE_PARAMETER,
		_distortion_viewport.get_texture()
	)

	if _source_camera != null:
		_setup_distortion()

	if Engine.is_editor_hint():
		show()
		return

	if not _spawn_animator.spawn_progress_changed.is_connected(_on_spawn_progress_changed):
		_spawn_animator.spawn_progress_changed.connect(_on_spawn_progress_changed)

	reset_spawn()


func setup(source_camera: Camera3D) -> void:
	assert(source_camera != null, "EnergySphere requires a source Camera3D.")
	_source_camera = source_camera

	if is_node_ready():
		_setup_distortion()


func play_spawn() -> void:
	if _spawn_animator.is_playing():
		return

	_aura_started = false
	_aura_flow.reset_spawn()
	_apply_spawn_progress(0.0)
	_reset_spawn_particles()
	_cross_flare_spawner.begin_spawn()
	_spawn_animator.play_spawn()


func reset_spawn() -> void:
	_aura_started = false
	_spawn_animator.reset_spawn()
	_apply_spawn_progress(0.0)
	_reset_spawn_particles()
	_aura_flow.reset_spawn()
	_cross_flare_spawner.reset_spawn()
	hide()


func is_spawn_playing() -> bool:
	return _spawn_animator.is_playing()


func _update_radius() -> void:
	if _spawn_progress > 0.0:
		_apply_effective_radius(radius * _radius_progress)


func _apply_effective_radius(effective_radius: float) -> void:
	_energy_shell.radius = effective_radius
	_inflow_streaks.radius = effective_radius
	_distortion_shell.radius = effective_radius
	_aura_flow.radius = effective_radius
	_update_core_radius(effective_radius)


func _update_core_radius(effective_radius: float) -> void:
	var core_glow_material := _core_glow.get_active_material(0) as ShaderMaterial
	assert(core_glow_material != null, "CoreGlow requires a ShaderMaterial.")
	core_glow_material.set_shader_parameter(
		SPHERE_RADIUS_PARAMETER,
		effective_radius
	)

	var core_color_material := _core_color.get_active_material(0) as ShaderMaterial
	assert(core_color_material != null, "CoreColor requires a ShaderMaterial.")
	core_color_material.set_shader_parameter(
		SPHERE_RADIUS_PARAMETER,
		effective_radius
	)

	var core_glow_mesh := _core_glow.mesh as BoxMesh
	assert(core_glow_mesh != null, "CoreGlow requires a BoxMesh.")
	core_glow_mesh.size = Vector3.ONE * effective_radius * 2.0

	var core_color_mesh := _core_color.mesh as BoxMesh
	assert(core_color_mesh != null, "CoreColor requires a BoxMesh.")
	core_color_mesh.size = Vector3.ONE * effective_radius * 2.0


func _on_spawn_progress_changed(progress: float) -> void:
	_apply_spawn_progress(progress)


func _apply_spawn_progress(progress: float) -> void:
	_spawn_progress = clampf(progress, 0.0, 1.0)
	_radius_progress = pow(
		_spawn_progress,
		_spawn_animator.radius_growth_power
	)

	_drift_particles.amount_ratio = _spawn_progress
	_inflow_particles.amount_ratio = _spawn_progress

	if is_zero_approx(_spawn_progress):
		hide()
		return

	_apply_effective_radius(radius * _radius_progress)

	if (
		not _aura_started
		and _radius_progress >= _spawn_animator.aura_start_radius_ratio
	):
		_aura_started = true
		_aura_flow.begin_spawn()

	show()


func _reset_spawn_particles() -> void:
	_drift_particles.amount_ratio = 0.0
	_inflow_particles.amount_ratio = 0.0
	_drift_particles.restart()
	_inflow_particles.restart()


func _setup_distortion() -> void:
	_distortion_capture.setup(_source_camera)
	_distortion_shell.setup(_source_camera)
