extends Node

const _Rules := preload("res://scripts/game/score_rules.gd")

var balance: Resource
var run_session: Node
var world: Node2D
var rules: RefCounted
var _prev_y: Dictionary = {}
var _player: Node2D


func setup(p_balance: Resource, p_run: Node, p_world: Node2D, p_rules: RefCounted) -> void:
	balance = p_balance
	run_session = p_run
	world = p_world
	rules = p_rules


func _physics_process(_delta: float) -> void:
	if balance == null or world == null or rules == null or run_session == null:
		return
	if run_session.is_game_over() or not GameManager.is_playing():
		return
	var player := _resolve_player()
	if player == null:
		return
	for c in world.get_children():
		if not is_instance_valid(c) or not c is Node2D or not (c as Node).visible:
			continue
		if not (c as Node).is_in_group("obstacles"):
			continue
		var body := c as Node2D
		var prev := float(_prev_y.get(body, body.position.y))
		if _Rules.is_near_miss(
			player.position,
			body.position,
			prev,
			balance.near_miss_hit_half,
			balance.near_miss_outer_half,
		):
			var pts: int = rules.register_near_miss(balance)
			_award(pts)
			EventBus.near_miss.emit(pts, rules.combo)
		_prev_y[body] = body.position.y


func _award(pts: int) -> void:
	if not GameManager.is_online_match() or multiplayer.is_server():
		run_session.add_score(pts)
		return
	var coord := get_tree().get_first_node_in_group("multiplayer_coordinator")
	if coord != null and coord.has_method("rpc_client_bonus_score"):
		coord.rpc_client_bonus_score.rpc(pts)


func _resolve_player() -> Node2D:
	if is_instance_valid(_player):
		return _player
	var n := get_tree().get_first_node_in_group("local_player")
	if n is Node2D:
		_player = n
	return _player
