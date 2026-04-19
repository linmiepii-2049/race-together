extends GutTest

var _sp: Node


func before_each() -> void:
	var script: GDScript = load("res://scripts/game/obstacle_spawner.gd") as GDScript
	_sp = script.new() as Node
	add_child(_sp)
	var bal: Resource = load("res://resources/game/game_balance.tres") as Resource
	_sp.balance = bal
	_sp._rng.seed = 999


func after_each() -> void:
	if is_instance_valid(_sp):
		_sp.queue_free()


func test_pick_kind_is_valid_enum() -> void:
	for _i in range(40):
		var k: int = int(_sp.pick_obstacle_kind_for_tests())
		assert_true(k == 0 or k == 1 or k == 2, "kind should be STATIC, DRONE, or LASER")
