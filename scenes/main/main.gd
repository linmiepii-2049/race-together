extends Node2D


func _ready() -> void:
	GameManager.change_state(GameManager.GameState.PLAYING)
	print("[Main] Scene ready")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if GameManager.is_playing():
			GameManager.pause()
		else:
			GameManager.resume()
