@tool
class_name MagicCircleLayer3D
extends Node3D

## Body・Ring・Glow Ringで構成される魔法陣の1段。

var _base_body_basis: Basis
var _base_ring_basis: Basis
var _base_ring_origin: Vector3
var _base_glow_ring_basis: Basis
var _base_glow_ring_origin: Vector3

@onready var _body: MagicCircleSurface3D = $Body
@onready var _ring: MagicCircleSurface3D = $Ring
@onready var _glow_ring: MagicCircleSurface3D = $GlowRing


func bind_viewports(
	body_viewport: SubViewport,
	ring_viewport: SubViewport,
	glow_ring_viewport: SubViewport
) -> void:
	_body.bind_viewport(body_viewport)
	_ring.bind_viewport(ring_viewport)
	_glow_ring.bind_viewport(glow_ring_viewport)


func set_appearance(appearance: MagicCircleAppearance3D) -> void:
	_body.blend_balance = appearance.blend_balance
	_ring.blend_balance = appearance.blend_balance
	_glow_ring.blend_balance = appearance.blend_balance
	_body.intensity = appearance.body_intensity
	_ring.intensity = appearance.ring_intensity
	_glow_ring.intensity = appearance.glow_intensity


func set_layout(layer_y: float, angle_rad: float, scale_factor: float) -> void:
	position.y = layer_y
	rotation.y = angle_rad
	scale = Vector3.ONE * scale_factor


func capture_animation_state() -> void:
	_base_body_basis = _body.transform.basis
	_base_ring_basis = _ring.transform.basis
	_base_ring_origin = _ring.transform.origin
	_base_glow_ring_basis = _glow_ring.transform.basis
	_base_glow_ring_origin = _glow_ring.transform.origin


func hide_rings() -> void:
	var ring_transform := _ring.transform
	ring_transform.basis = _base_ring_basis.scaled(Vector3.ZERO)
	_ring.transform = ring_transform
	_ring.set_opacity(0.0)

	var glow_ring_transform := _glow_ring.transform
	glow_ring_transform.basis = _base_glow_ring_basis.scaled(Vector3.ZERO)
	_glow_ring.transform = glow_ring_transform
	_glow_ring.set_opacity(0.0)


func apply_ring_state(
	source_layer: MagicCircleLayer3D,
	rise_progress: float,
	reveal_progress: float,
	glow_reveal_progress: float,
	is_started: bool
) -> void:
	var start_position := to_local(source_layer.global_position)
	var ring_transform := _ring.transform
	var glow_ring_transform := _glow_ring.transform

	if is_started:
		var ring_position := start_position.lerp(_base_ring_origin, rise_progress)
		ring_transform.basis = _base_ring_basis
		glow_ring_transform.basis = _base_glow_ring_basis
		ring_transform.origin = ring_position
		glow_ring_transform.origin = ring_position
		_ring.set_opacity(reveal_progress)
		_glow_ring.set_opacity(glow_reveal_progress)
	else:
		ring_transform.basis = _base_ring_basis.scaled(Vector3.ZERO)
		glow_ring_transform.basis = _base_glow_ring_basis.scaled(Vector3.ZERO)
		ring_transform.origin = start_position
		glow_ring_transform.origin = start_position
		_ring.set_opacity(0.0)
		_glow_ring.set_opacity(0.0)

	_ring.transform = ring_transform
	_glow_ring.transform = glow_ring_transform


func apply_body_state(scale_progress: float, rotation_offset: float) -> void:
	var animated_basis := _base_body_basis * Basis(Vector3.FORWARD, rotation_offset)
	animated_basis = animated_basis.scaled(Vector3.ONE * scale_progress)

	var body_transform := _body.transform
	body_transform.basis = animated_basis
	_body.transform = body_transform


func restore_animation_state() -> void:
	var body_transform := _body.transform
	body_transform.basis = _base_body_basis
	_body.transform = body_transform

	var ring_transform := _ring.transform
	ring_transform.basis = _base_ring_basis
	ring_transform.origin = _base_ring_origin
	_ring.transform = ring_transform
	_ring.set_opacity(1.0)

	var glow_ring_transform := _glow_ring.transform
	glow_ring_transform.basis = _base_glow_ring_basis
	glow_ring_transform.origin = _base_glow_ring_origin
	_glow_ring.transform = glow_ring_transform
	_glow_ring.set_opacity(1.0)
