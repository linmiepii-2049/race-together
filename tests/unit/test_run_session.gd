extends GutTest

var _balance: Resource
var _rs: Node


func before_each() -> void:
	var base: Resource = load("res://resources/game/game_balance.tres") as Resource
	_balance = base.duplicate(true) as Resource
	_balance.invulnerable_after_hit_sec = 0.0
	var script: GDScript = load("res://scripts/game/run_session.gd") as GDScript
	_rs = script.new() as Node
	add_child(_rs)
	_rs.call("setup", _balance)


func after_each() -> void:
	if is_instance_valid(_rs):
		_rs.queue_free()
	GameManager.change_state(GameManager.GameState.PLAYING)


func test_hit_reduces_shield() -> void:
	assert_eq(_rs.shield, 3)
	_rs.call("register_hit_from_obstacle")
	assert_eq(_rs.shield, 2)
	assert_false(_rs.call("is_game_over"))


func test_add_score_increments() -> void:
	_rs.call("add_score", 5)
	assert_eq(_rs.score, 5)


func test_three_hits_triggers_game_over() -> void:
	_rs.call("register_hit_from_obstacle")
	_rs.call("register_hit_from_obstacle")
	_rs.call("register_hit_from_obstacle")
	assert_true(_rs.call("is_game_over"))
	assert_eq(GameManager.current_state, GameManager.GameState.GAME_OVER)
