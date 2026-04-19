extends Node

signal game_state_changed(new_state: String)

enum GameState { MENU, PLAYING, PAUSED, GAME_OVER }

var current_state: GameState = GameState.MENU


func change_state(new_state: GameState) -> void:
	var old_state := current_state
	current_state = new_state
	game_state_changed.emit(GameState.keys()[new_state])
	print("[GameManager] State: %s -> %s" % [GameState.keys()[old_state], GameState.keys()[new_state]])


func is_playing() -> bool:
	return current_state == GameState.PLAYING


func is_game_over() -> bool:
	return current_state == GameState.GAME_OVER


func pause() -> void:
	if current_state == GameState.PLAYING:
		change_state(GameState.PAUSED)
		get_tree().paused = true


func resume() -> void:
	if current_state == GameState.PAUSED:
		change_state(GameState.PLAYING)
		get_tree().paused = false
