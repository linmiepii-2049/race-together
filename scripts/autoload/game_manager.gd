extends Node

signal game_state_changed(new_state: String)

enum GameState { MENU, PLAYING, PAUSED, GAME_OVER, CUTSCENE, DIALOGUE }
enum PlayMode { NONE, STORY, ENDLESS, ONLINE }

var current_state: GameState = GameState.MENU
var play_mode: PlayMode = PlayMode.NONE
## 重載場景後要直接進入的模式：""、"story"、"endless"、"online"。
var pending_launch: String = ""
var profile: RefCounted

const _ProfileScript := preload("res://scripts/game/player_profile.gd")


func _ready() -> void:
	profile = _ProfileScript.new()
	profile.load_from(profile.DEFAULT_PATH)
	apply_saved_volume()


func set_play_mode(mode: PlayMode) -> void:
	play_mode = mode


func apply_saved_volume() -> void:
	if profile == null:
		return
	var idx := AudioServer.get_bus_index("Master")
	if idx < 0:
		return
	var v: float = clampf(float(profile.volume), 0.0, 1.0)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(v, 0.0001)))


func change_state(new_state: GameState) -> void:
	var old_state := current_state
	current_state = new_state
	game_state_changed.emit(GameState.keys()[new_state])
	print("[GameManager] State: %s -> %s" % [GameState.keys()[old_state], GameState.keys()[new_state]])


func is_playing() -> bool:
	return current_state == GameState.PLAYING


func is_game_over() -> bool:
	return current_state == GameState.GAME_OVER


## Godot 4.6 預設是 OfflineMultiplayerPeer，has_multiplayer_peer() 也會是 true。
## 只有真正的 WebRTC 對局才算連線。
func is_online_match() -> bool:
	var peer: MultiplayerPeer = multiplayer.multiplayer_peer
	return peer != null and peer is WebRTCMultiplayerPeer


func pause() -> void:
	if current_state == GameState.PLAYING:
		change_state(GameState.PAUSED)
		get_tree().paused = true


func resume() -> void:
	if current_state == GameState.PAUSED:
		change_state(GameState.PLAYING)
		get_tree().paused = false
