extends Node

const _PlayerScene := preload("res://scenes/game/player/Player.tscn")
const _PeerOrder := preload("res://scripts/game/mp_peer_order.gd")

var _game_root: Node2D
var _sync_tick: int = 0


func _ready() -> void:
	add_to_group("multiplayer_coordinator")
	_game_root = get_parent() as Node2D
	GameManager.game_state_changed.connect(_on_game_state_changed)
	if multiplayer.has_multiplayer_peer():
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)


func _physics_process(_delta: float) -> void:
	if not multiplayer.has_multiplayer_peer():
		return
	if not multiplayer.is_server():
		return
	if not GameManager.is_playing():
		return
	var rs: Node = _game_root.get_node("RunSession")
	_sync_tick += 1
	if _sync_tick % 2 != 0:
		return
	var go: bool = bool(rs.call("is_game_over"))
	var ids: PackedInt32Array = rs.call("get_ordered_peer_ids") as PackedInt32Array
	var sh: PackedInt32Array = rs.call("build_shield_packed") as PackedInt32Array
	var inv: PackedInt32Array = rs.call("build_invuln_packed") as PackedInt32Array
	var el: PackedInt32Array = rs.call("build_elim_packed") as PackedInt32Array
	rpc_sync_run_state.rpc(rs.score, ids, sh, inv, el, go)


@rpc("call_local", "reliable")
func rpc_bootstrap_seed(run_seed: int) -> void:
	var sp: Node = _game_root.get_node("ObstacleSpawner")
	if sp.has_method("set_run_seed"):
		sp.call("set_run_seed", run_seed)


@rpc("call_local", "reliable")
func rpc_net_ob_spawn(kind: int, px: float, py: float, pickup_counter: int) -> void:
	var sp: Node = _game_root.get_node("ObstacleSpawner")
	if sp.has_method("apply_net_spawn"):
		sp.call("apply_net_spawn", kind, px, py, pickup_counter)


@rpc("call_local", "reliable")
func rpc_sync_run_state(
	p_score: int,
	peer_ids: PackedInt32Array,
	shields: PackedInt32Array,
	invulns: PackedInt32Array,
	elims: PackedInt32Array,
	p_game_over: bool,
) -> void:
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		return
	var rs: Node = _game_root.get_node("RunSession")
	if rs.has_method("sync_from_host"):
		rs.call("sync_from_host", p_score, peer_ids, shields, invulns, elims, p_game_over)


@rpc("any_peer", "reliable")
func rpc_client_obstacle_hit() -> void:
	if not multiplayer.is_server():
		return
	var who := multiplayer.get_remote_sender_id()
	if who == 0:
		who = multiplayer.get_unique_id()
	var rs: Node = _game_root.get_node("RunSession")
	rs.call("register_hit_for_peer", who)


@rpc("any_peer", "reliable")
func rpc_client_pickup_shield(pickup_name: String) -> void:
	if not multiplayer.is_server():
		return
	var who := multiplayer.get_remote_sender_id()
	if who == 0:
		who = multiplayer.get_unique_id()
	var rs: Node = _game_root.get_node("RunSession")
	rs.call("apply_pickup_shield_for_peer", who)
	rpc_pickup_recycle.rpc(pickup_name)


@rpc("any_peer", "reliable")
func rpc_client_pickup_invulnerable(pickup_name: String) -> void:
	if not multiplayer.is_server():
		return
	var who := multiplayer.get_remote_sender_id()
	if who == 0:
		who = multiplayer.get_unique_id()
	var rs: Node = _game_root.get_node("RunSession")
	var dur: float = 3.0
	if _game_root.balance != null:
		dur = float(_game_root.balance.invulnerable_pickup_sec)
	rs.call("apply_pickup_invulnerable_for_peer", who)
	rpc_pickup_invuln_fx.rpc(who, dur)
	rpc_pickup_recycle.rpc(pickup_name)


@rpc("call_local", "reliable")
func rpc_pickup_invuln_fx(peer_id: int, duration_sec: float) -> void:
	EventBus.pickup_invulnerability_for_peer.emit(peer_id, duration_sec)


@rpc("call_local", "reliable")
func rpc_peer_damage_feedback(peer_id: int, remaining_shield: int, maximum_shield: int) -> void:
	EventBus.run_peer_player_damaged.emit(peer_id, remaining_shield, maximum_shield)


@rpc("any_peer", "call_local", "unreliable")
func rpc_player_lateral(peer_id: int, lateral_x: float) -> void:
	if multiplayer.get_unique_id() == peer_id:
		return
	var pc: Node2D = _game_root.get_node("World/Players") as Node2D
	var n := pc.get_node_or_null("Player_%d" % peer_id)
	if n is CharacterBody2D:
		(n as CharacterBody2D).position.x = lateral_x


@rpc("call_local", "reliable")
func rpc_pickup_recycle(pickup_name: String) -> void:
	var w: Node2D = _game_root.get_node("World") as Node2D
	var a: Node = w.find_child(pickup_name, true, false)
	if a != null and is_instance_valid(a):
		var sp: Node = _game_root.get_node("ObstacleSpawner")
		sp.call("recycle_node", a)


func _on_game_state_changed(state_name: String) -> void:
	if state_name != "PLAYING":
		return
	if not multiplayer.has_multiplayer_peer():
		return
	call_deferred("_deferred_start_network_game")


func _deferred_start_network_game() -> void:
	if not multiplayer.has_multiplayer_peer():
		return
	_rebuild_players_from_peers()
	if multiplayer.is_server():
		var run_seed := randi()
		rpc_bootstrap_seed.rpc(run_seed)


func _all_sorted_peer_ids() -> Array[int]:
	return _PeerOrder.sorted_peer_ids(multiplayer.get_unique_id(), multiplayer.get_peers())


func _rebuild_players_from_peers() -> void:
	var world: Node2D = _game_root.get_node("World") as Node2D
	var pc: Node2D = world.get_node("Players") as Node2D
	var legacy: Node = world.get_node_or_null("Player")
	if legacy != null and is_instance_valid(legacy):
		legacy.queue_free()
	for c in pc.get_children():
		c.queue_free()
	var balance: Resource = _game_root.balance
	var ids := _all_sorted_peer_ids()
	var idx := 0
	for peer_id in ids:
		var p: CharacterBody2D = _PlayerScene.instantiate() as CharacterBody2D
		p.name = "Player_%d" % peer_id
		p.set_multiplayer_authority(peer_id)
		var row_y: float = balance.player_anchor_y + float(idx) * 48.0
		p.position = Vector2(0.0, row_y)
		pc.add_child(p)
		if _game_root.has_method("register_spawned_player"):
			_game_root.call("register_spawned_player", p)
		idx += 1
	var rs: Node = _game_root.get_node("RunSession")
	rs.call("init_peers_for_multiplayer", ids)


func _on_peer_connected(_id: int) -> void:
	if not GameManager.is_playing():
		return
	if not multiplayer.has_multiplayer_peer():
		return
	call_deferred("_rebuild_players_from_peers")


func _on_peer_disconnected(id: int) -> void:
	var pc: Node2D = _game_root.get_node("World/Players") as Node2D
	var n := pc.get_node_or_null("Player_%d" % id)
	if n != null and is_instance_valid(n):
		n.queue_free()
