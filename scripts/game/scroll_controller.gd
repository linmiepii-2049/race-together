extends Node

signal scroll_speed_changed(speed: float)

var balance: Resource
var run_session: Node

var scroll_speed: float = 0.0
var _distance_accum: float = 0.0


func setup(p_balance: Resource, p_run_session: Node) -> void:
	balance = p_balance
	run_session = p_run_session
	scroll_speed = balance.base_scroll_speed
	scroll_speed_changed.emit(scroll_speed)


func get_scroll_speed() -> float:
	return scroll_speed


func _physics_process(delta: float) -> void:
	if balance == null or run_session == null or run_session.is_game_over():
		return
	if not GameManager.is_playing():
		return
	var target: float = balance.base_scroll_speed + float(run_session.score) * balance.scroll_ramp_per_score
	scroll_speed = move_toward(scroll_speed, mini(target, balance.scroll_speed_max), 140.0 * delta)
	scroll_speed_changed.emit(scroll_speed)
	_distance_accum += scroll_speed * delta
	if _distance_accum >= 12.0:
		var pts := int(_distance_accum / 12.0)
		_distance_accum -= float(pts) * 12.0
		if not multiplayer.has_multiplayer_peer() or multiplayer.is_server():
			run_session.add_score(pts)
