extends Node

enum StateId { NORMAL, HANDBRAKE }

var current: StateId = StateId.NORMAL
var _handbrake_time_left: float = 0.0


func reset_machine() -> void:
	current = StateId.NORMAL
	_handbrake_time_left = 0.0


func notify_handbrake(balance: Resource) -> void:
	if balance == null:
		return
	current = StateId.HANDBRAKE
	_handbrake_time_left = balance.handbrake_duration_sec


func process_machine(delta: float, balance: Resource) -> void:
	if current == StateId.HANDBRAKE:
		_handbrake_time_left -= delta
		if _handbrake_time_left <= 0.0:
			current = StateId.NORMAL


func is_handbrake() -> bool:
	return current == StateId.HANDBRAKE
