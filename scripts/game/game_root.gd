extends Node2D

@export var balance: Resource

@onready var run_session: Node = $RunSession
@onready var scroll_controller: Node = $ScrollController
@onready var obstacle_spawner: Node = $ObstacleSpawner
@onready var world: Node2D = $World
@onready var road_visual: Node2D = $World/RoadVisual
@onready var players_root: Node2D = $World/Players
@onready var player: CharacterBody2D = $World/Player
@onready var hud: CanvasLayer = $HUD
@onready var player_machine: Node = $World/Player/PlayerStateMachine


func _ready() -> void:
	if balance == null:
		balance = load("res://resources/game/game_balance.tres") as Resource
	world.skew = 0.0
	world.scale = Vector2(1.0, 1.0)
	run_session.setup(balance)
	scroll_controller.setup(balance, run_session)
	obstacle_spawner.setup(balance, run_session, scroll_controller, world)
	if road_visual.has_method("setup"):
		road_visual.call("setup", balance, scroll_controller)
	if player.has_method("setup"):
		player.setup(balance, run_session, scroll_controller, obstacle_spawner, player_machine)
	if player.has_signal("pickup_hit"):
		player.pickup_hit.connect(_on_pickup_hit)
	if not multiplayer.has_multiplayer_peer():
		player.add_to_group("local_player")


func register_spawned_player(p: CharacterBody2D) -> void:
	var machine: Node = p.get_node("PlayerStateMachine")
	p.setup(balance, run_session, scroll_controller, obstacle_spawner, machine)
	if p.has_signal("pickup_hit") and not p.pickup_hit.is_connected(_on_pickup_hit):
		p.pickup_hit.connect(_on_pickup_hit)
	p.remove_from_group("local_player")
	if p.get_multiplayer_authority() == multiplayer.get_unique_id():
		p.add_to_group("local_player")


func _iter_controlled_players() -> Array:
	var out: Array = []
	if players_root.get_child_count() > 0:
		for c in players_root.get_children():
			out.append(c)
		return out
	if is_instance_valid(player) and player.is_inside_tree():
		out.append(player)
	return out


func _physics_process(delta: float) -> void:
	if balance == null:
		return
	if run_session.is_game_over() or not GameManager.is_playing():
		return
	var steer: float = _compute_steer_axis()
	var hb_pressed := Input.is_action_just_pressed("handbrake")
	var hb_held := Input.is_action_pressed("handbrake")
	for p in _iter_controlled_players():
		if p is CharacterBody2D and p.has_method("apply_control"):
			if not multiplayer.has_multiplayer_peer() or p.get_multiplayer_authority() == multiplayer.get_unique_id():
				(p as CharacterBody2D).apply_control(steer, hb_pressed, hb_held, delta)
	obstacle_spawner.cull_offscreen()


func _on_pickup_hit(pickup: Area2D) -> void:
	if is_instance_valid(pickup):
		obstacle_spawner.recycle_node(pickup)


func reset_run() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _compute_steer_axis() -> float:
	var s: float = Input.get_axis("move_left", "move_right")
	if abs(s) < 0.01:
		s = Input.get_axis("ui_left", "ui_right")
	if abs(s) < 0.01:
		var left_on: bool = (
			Input.is_physical_key_pressed(KEY_A)
			or Input.is_physical_key_pressed(KEY_LEFT)
		)
		var right_on: bool = (
			Input.is_physical_key_pressed(KEY_D)
			or Input.is_physical_key_pressed(KEY_RIGHT)
		)
		if left_on and not right_on:
			return -1.0
		if right_on and not left_on:
			return 1.0
	return s
