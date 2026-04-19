extends Node

enum ObstacleKind { STATIC, DRONE, LASER }

const ObstacleStaticScene := preload("res://scenes/game/obstacles/ObstacleStatic.tscn")
const ObstacleDroneScene := preload("res://scenes/game/obstacles/ObstacleDrone.tscn")
const ObstacleLaserScene := preload("res://scenes/game/obstacles/ObstacleLaser.tscn")
const PickupScene := preload("res://scenes/game/pickups/Pickup.tscn")

var balance: Resource
var run_session: Node
var scroll_controller: Node
var world: Node2D

var _rng := RandomNumberGenerator.new()
var _spawn_cooldown: float = 0.0
var _pickup_counter: int = 0

var _pool_static: Array[Node] = []
var _pool_drone: Array[Node] = []
var _pool_laser: Array[Node] = []
var _pool_pickup: Array[Node] = []


func setup(p_balance: Resource, p_run: Node, p_scroll: Node, p_world: Node2D) -> void:
	balance = p_balance
	run_session = p_run
	scroll_controller = p_scroll
	world = p_world
	_rng.randomize()
	_spawn_cooldown = 0.4


func set_run_seed(run_seed: int) -> void:
	_rng.seed = run_seed


func apply_net_spawn(kind: int, px: float, py: float, pickup_counter: int) -> void:
	_pickup_counter = pickup_counter
	var pos := Vector2(px, py)
	if kind == -1:
		_spawn_pickup(pos)
		return
	match int(kind):
		ObstacleKind.STATIC:
			_activate_static(pos)
		ObstacleKind.DRONE:
			_activate_drone(pos)
		ObstacleKind.LASER:
			_activate_laser(pos)


func _physics_process(delta: float) -> void:
	if balance == null or run_session == null or world == null:
		return
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return
	if run_session.is_game_over() or not GameManager.is_playing():
		return
	_spawn_cooldown -= delta
	if _spawn_cooldown > 0.0:
		return
	var interval: float = balance.spawn_interval_start - float(run_session.score) * balance.spawn_interval_per_score
	interval = maxf(interval, balance.spawn_interval_min)
	_spawn_cooldown = interval
	_spawn_one()


func pick_obstacle_kind_for_tests() -> ObstacleKind:
	return _pick_kind_weighted()


func _pick_kind_weighted() -> ObstacleKind:
	var w0: float = balance.weight_static
	var w1: float = balance.weight_drone
	var w2: float = balance.weight_laser
	var t: float = _rng.randf() * (w0 + w1 + w2)
	if t < w0:
		return ObstacleKind.STATIC
	if t < w0 + w1:
		return ObstacleKind.DRONE
	return ObstacleKind.LASER


func _spawn_one() -> void:
	var half: float = balance.half_lane_width
	var margin: float = balance.spawn_margin_x
	var x: float = _rng.randf_range(-half + margin, half - margin)
	var y: float = balance.spawn_y
	_pickup_counter += 1
	var coord: Node = get_parent().get_node_or_null("MultiplayerCoordinator")
	if multiplayer.has_multiplayer_peer() and coord != null:
		if _pickup_counter >= 7:
			_pickup_counter = 0
			coord.rpc_net_ob_spawn.rpc(-1, x, y, 0)
			return
		var spawn_kind := _pick_kind_weighted()
		coord.rpc_net_ob_spawn.rpc(int(spawn_kind), x, y, _pickup_counter)
		return
	if _pickup_counter >= 7:
		_pickup_counter = 0
		_spawn_pickup(Vector2(x, y))
		return
	var kind := _pick_kind_weighted()
	match kind:
		ObstacleKind.STATIC:
			_activate_static(Vector2(x, y))
		ObstacleKind.DRONE:
			_activate_drone(Vector2(x, y))
		ObstacleKind.LASER:
			_activate_laser(Vector2(x, y))


func _get_from_pool(pool: Array[Node], scene: PackedScene) -> Node:
	var n: Node = null
	if not pool.is_empty():
		n = pool.pop_back()
	else:
		n = scene.instantiate()
		world.add_child(n)
	return n


func _recycle(node: Node, pool: Array[Node]) -> void:
	if not is_instance_valid(node):
		return
	node.visible = false
	node.process_mode = Node.PROCESS_MODE_DISABLED
	if node is Area2D:
		(node as Area2D).monitoring = false
		(node as Area2D).set_deferred("monitoring", false)
	pool.append(node)


func recycle_node(node: Node) -> void:
	if not is_instance_valid(node):
		return
	if node.is_in_group("pickups"):
		_recycle(node, _pool_pickup)
		return
	var node_name := String(node.name)
	if node_name.begins_with("Static"):
		_recycle(node, _pool_static)
	elif node_name.begins_with("Drone"):
		_recycle(node, _pool_drone)
	elif node_name.begins_with("Laser"):
		_recycle(node, _pool_laser)


func _activate_static(pos: Vector2) -> void:
	var n := _get_from_pool(_pool_static, ObstacleStaticScene)
	n.name = "Static_%d" % Time.get_ticks_msec()
	n.process_mode = Node.PROCESS_MODE_INHERIT
	n.visible = true
	n.position = pos
	if n is Area2D:
		(n as Area2D).monitoring = true
	if n.has_method("activate"):
		n.call("activate", balance, run_session, scroll_controller)


func _activate_drone(pos: Vector2) -> void:
	var n := _get_from_pool(_pool_drone, ObstacleDroneScene)
	n.name = "Drone_%d" % Time.get_ticks_msec()
	n.process_mode = Node.PROCESS_MODE_INHERIT
	n.visible = true
	n.position = pos
	if n is Area2D:
		(n as Area2D).monitoring = true
	if n.has_method("activate"):
		n.call("activate", balance, run_session, scroll_controller)


func _activate_laser(pos: Vector2) -> void:
	var n := _get_from_pool(_pool_laser, ObstacleLaserScene)
	n.name = "Laser_%d" % Time.get_ticks_msec()
	n.process_mode = Node.PROCESS_MODE_INHERIT
	n.visible = true
	n.position = pos
	if n is Area2D:
		(n as Area2D).monitoring = true
	if n.has_method("activate"):
		n.call("activate", balance, run_session, scroll_controller)


func _spawn_pickup(pos: Vector2) -> void:
	var n := _get_from_pool(_pool_pickup, PickupScene)
	n.name = "Pickup_%d" % Time.get_ticks_msec()
	n.process_mode = Node.PROCESS_MODE_INHERIT
	n.visible = true
	n.position = pos
	if n is Area2D:
		(n as Area2D).monitoring = true
	if n.has_method("activate"):
		n.call("activate", balance, run_session, scroll_controller)


func cull_offscreen() -> void:
	if balance == null or world == null:
		return
	var limit: float = balance.despawn_y
	for c in world.get_children():
		if not is_instance_valid(c):
			continue
		if c.visible and c.position.y > limit:
			recycle_node(c)
