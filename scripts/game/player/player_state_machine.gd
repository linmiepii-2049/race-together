extends Node

enum StateId { NORMAL, HANDBRAKE, BOOST }

var current: StateId = StateId.NORMAL
var _handbrake_time_left: float = 0.0
var _boost_time_left: float = 0.0


func reset_machine() -> void:
	current = StateId.NORMAL
	_handbrake_time_left = 0.0
	_boost_time_left = 0.0


func notify_handbrake(balance: Resource) -> void:
	if balance == null or current == StateId.BOOST:
		return
	current = StateId.HANDBRAKE
	_handbrake_time_left = balance.handbrake_duration_sec


func notify_boost(balance: Resource) -> void:
	if balance == null:
		return
	current = StateId.BOOST
	_boost_time_left = balance.nitro_boost_sec


func process_machine(delta: float, _balance: Resource) -> void:
	match current:
		StateId.HANDBRAKE:
			_handbrake_time_left -= delta
			if _handbrake_time_left <= 0.0:
				current = StateId.NORMAL
		StateId.BOOST:
			_boost_time_left -= delta
			if _boost_time_left <= 0.0:
				current = StateId.NORMAL


func is_handbrake() -> bool:
	return current == StateId.HANDBRAKE


func is_boosting() -> bool:
	return current == StateId.BOOST
