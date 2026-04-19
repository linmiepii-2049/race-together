extends CharacterBody2D

signal pickup_hit(pickup: Area2D)

var balance: Resource
var run_session: Node
var scroll_controller: Node
var spawner: Node

var lateral_vel: float = 0.0

@onready var hurtbox: Area2D = $HurtBox
@onready var thruster: CPUParticles2D = $Thruster
@onready var drift_smoke: CPUParticles2D = $DriftSmoke
@onready var car_body: Sprite2D = $CarBody

const DAMAGE_VISUAL_SUPPRESS_SHIELD_PULSE_USEC := 280_000
const CAR_TEXTURE_PATH := "res://assets/sprites/Gemini_Generated_Image_bm0laibm0laibm0l_3.png"
const _SpriteTextureUtil := preload("res://scripts/game/sprite_texture_util.gd")
## 連線時依權威 peer id 取色，最多 4 人房與盤點長度對齊。
const _MULTIPLAYER_CAR_MODULATES: Array[Color] = [
	Color(1.0, 0.45, 0.42),
	Color(0.38, 0.92, 0.58),
	Color(0.48, 0.68, 1.0),
	Color(1.0, 0.82, 0.38),
]
## 單人模式車身色（貼圖上再疊乘 modulate）。
const _SOLO_CAR_MODULATE := Color(0.62, 0.88, 1.0, 1.0)

var _machine: Node
var _car_body_modulate_base: Color = Color.WHITE
var _suppress_shield_pulse_until_usec: int = 0
var _invuln_pickup_flash_tween: Tween


func _ready() -> void:
	if car_body != null:
		var tex: Texture2D = _load_sprite_texture(CAR_TEXTURE_PATH)
		if tex != null:
			car_body.texture = tex
			_sync_hurtbox_to_car_sprite()


func _sync_hurtbox_to_car_sprite() -> void:
	var util := _SpriteTextureUtil.new()
	var cs := hurtbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
	util.sync_rect_shape_to_sprite(cs, car_body)


func _load_sprite_texture(path: String) -> Texture2D:
	var util = _SpriteTextureUtil.new()
	return util.load_texture(path)


func setup(
	p_balance: Resource,
	p_run: Node,
	p_scroll: Node,
	p_spawner: Node,
	p_machine: Node
) -> void:
	balance = p_balance
	run_session = p_run
	scroll_controller = p_scroll
	spawner = p_spawner
	_machine = p_machine
	position.y = balance.player_anchor_y
	lateral_vel = 0.0
	if hurtbox:
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	EventBus.shield_changed.connect(_on_shield_changed)
	EventBus.run_player_damaged.connect(_on_player_damaged)
	EventBus.pickup_invulnerability_started.connect(_on_pickup_invulnerability_started)
	EventBus.pickup_invulnerability_for_peer.connect(_on_pickup_invulnerability_for_peer)
	_apply_car_body_modulate()


func _apply_car_body_modulate() -> void:
	if car_body == null:
		return
	if multiplayer.has_multiplayer_peer():
		var pid: int = get_multiplayer_authority()
		var idx: int = absi(pid) % _MULTIPLAYER_CAR_MODULATES.size()
		_car_body_modulate_base = _MULTIPLAYER_CAR_MODULATES[idx]
	else:
		_car_body_modulate_base = _SOLO_CAR_MODULATE
	car_body.modulate = _car_body_modulate_base


func reset_player() -> void:
	if balance:
		position.y = balance.player_anchor_y
	position.x = 0.0
	lateral_vel = 0.0
	if _machine:
		_machine.reset_machine()


func apply_control(steer_axis: float, handbrake_pressed: bool, handbrake_held: bool, delta: float) -> void:
	if balance == null or run_session == null or scroll_controller == null or _machine == null:
		return
	if run_session.is_game_over() or not GameManager.is_playing():
		return
	if multiplayer.has_multiplayer_peer() and bool(run_session.call("is_peer_out", get_multiplayer_authority())):
		return
	_machine.process_machine(delta, balance)
	if handbrake_pressed:
		_machine.notify_handbrake(balance)
		if abs(steer_axis) > 0.15:
			lateral_vel += sign(steer_axis) * balance.handbrake_lateral_impulse
		elif abs(lateral_vel) > 30.0:
			lateral_vel -= sign(lateral_vel) * balance.handbrake_lateral_impulse * 0.5
	var scroll_speed: float = scroll_controller.get_scroll_speed()
	var speed_ratio: float = clampf(scroll_speed / maxf(balance.scroll_speed_max, 1.0), 0.0, 1.0)
	var steer_scale: float = lerpf(1.0, balance.high_speed_steer_factor, speed_ratio)
	var accel: float = balance.lateral_accel * steer_scale
	lateral_vel += steer_axis * accel * delta
	# 與速度成比例的阻尼；勿用「每幀固定減少量」否則會壓過小加速度，車子幾乎只會靠手煞衝量才動。
	var damp: float = balance.lateral_friction * delta
	if _machine.is_handbrake():
		damp *= balance.handbrake_friction_mult
	lateral_vel -= lateral_vel * minf(0.95, damp)
	var max_sp: float = balance.max_lateral_speed * lerpf(1.0, 0.72, speed_ratio * 0.85)
	lateral_vel = clampf(lateral_vel, -max_sp, max_sp)
	position.x += lateral_vel * delta
	var half: float = balance.half_lane_width
	position.x = clampf(position.x, -half, half)
	velocity = Vector2.ZERO
	if thruster:
		thruster.emitting = abs(steer_axis) > 0.05 or handbrake_held
	if drift_smoke:
		drift_smoke.emitting = _machine.is_handbrake()
	if multiplayer.has_multiplayer_peer() and is_multiplayer_authority():
		var coord: Node = get_tree().get_first_node_in_group("multiplayer_coordinator") as Node
		if coord != null and coord.has_method("rpc_player_lateral"):
			coord.rpc_player_lateral.rpc(multiplayer.get_unique_id(), position.x)


func _on_hurtbox_area_entered(area: Area2D) -> void:
	if run_session == null:
		return
	var coord: Node = get_tree().get_first_node_in_group("multiplayer_coordinator") as Node
	var online := multiplayer.has_multiplayer_peer()
	if area.is_in_group("obstacles"):
		if area is Area2D and not (area as Area2D).monitoring:
			return
		if online and coord != null:
			if multiplayer.is_server():
				run_session.call("register_hit_for_peer", get_multiplayer_authority())
			else:
				coord.rpc_client_obstacle_hit.rpc()
		else:
			run_session.register_hit_from_obstacle()
	elif area.is_in_group("pickups"):
		if online and coord != null:
			if multiplayer.is_server():
				_apply_pickup_effect(area)
				coord.rpc_pickup_recycle.rpc(area.name)
			else:
				if area.has_method("is_shield_pickup") and bool(area.call("is_shield_pickup")):
					coord.rpc_client_pickup_shield.rpc(area.name)
				else:
					coord.rpc_client_pickup_invulnerable.rpc(area.name)
		else:
			_apply_pickup_effect(area)
			pickup_hit.emit(area)


func _apply_pickup_effect(area: Area2D) -> void:
	if area.has_method("is_shield_pickup"):
		var is_shield := bool(area.call("is_shield_pickup"))
		if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
			var pid := get_multiplayer_authority()
			if is_shield:
				run_session.call("apply_pickup_shield_for_peer", pid)
			else:
				run_session.call("apply_pickup_invulnerable_for_peer", pid)
				var c: Node = get_tree().get_first_node_in_group("multiplayer_coordinator") as Node
				if c != null and c.has_method("rpc_pickup_invuln_fx"):
					c.rpc_pickup_invuln_fx.rpc(pid, balance.invulnerable_pickup_sec)
		else:
			if is_shield:
				run_session.apply_pickup_shield()
			else:
				run_session.apply_pickup_invulnerable()


func _on_shield_changed(_current: int, _maximum: int) -> void:
	if car_body == null:
		return
	if Time.get_ticks_usec() < _suppress_shield_pulse_until_usec:
		return
	var tw := create_tween()
	tw.tween_property(car_body, "modulate:a", 0.78, 0.06)
	tw.tween_property(car_body, "modulate:a", 1.0, 0.12)


func _on_pickup_invulnerability_for_peer(peer_id: int, duration_sec: float) -> void:
	if peer_id != get_multiplayer_authority():
		return
	_on_pickup_invulnerability_started(duration_sec)


func _on_pickup_invulnerability_started(duration_sec: float) -> void:
	if car_body == null:
		return
	if _invuln_pickup_flash_tween != null and _invuln_pickup_flash_tween.is_valid():
		_invuln_pickup_flash_tween.kill()
	car_body.self_modulate = Color.WHITE
	var half_cycle: float = 0.075
	var cycle: float = half_cycle * 2.0
	var steps: int = clampi(int(ceil(duration_sec / cycle)), 1, 512)
	var tw := create_tween()
	_invuln_pickup_flash_tween = tw
	for _i in steps:
		tw.tween_property(car_body, "self_modulate", Color(0.52, 0.88, 1.0, 0.52), half_cycle)
		tw.tween_property(car_body, "self_modulate", Color(1.25, 1.08, 0.78, 1.0), half_cycle)
	tw.tween_callback(
		func () -> void:
			if is_instance_valid(car_body):
				car_body.self_modulate = Color.WHITE
			_invuln_pickup_flash_tween = null
	)


func _on_player_damaged(_remaining: int, _maximum: int) -> void:
	_suppress_shield_pulse_until_usec = Time.get_ticks_usec() + DAMAGE_VISUAL_SUPPRESS_SHIELD_PULSE_USEC
	const HIT_COLOR := Color(1.0, 0.32, 0.28, 1.0)
	if car_body != null:
		var twb := create_tween()
		car_body.modulate = HIT_COLOR
		twb.tween_property(car_body, "modulate", _car_body_modulate_base, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
