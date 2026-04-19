extends Node2D

@onready var _lobby: CanvasLayer = $NetworkLobby
@onready var _game_root: Node = $GameRoot
@onready var _cam: Camera2D = $Camera2D
var _player: Node2D = null
@onready var _damage_edge: Panel = $DamageFeedback/DamageEdge
@onready var _bgm: AudioStreamPlayer = $BGM
@onready var _damage_sfx: AudioStreamPlayer = $DamageSFX

var _cam_shake_t: float = 0.0
## 與 `game_balance.player_anchor_y` 一致；無 local_player 時相機勿留在舊的 (640,360) 世界座標。
const _CAMERA_WORLD_FALLBACK := Vector2(0.0, 560.0)
const CAM_SHAKE_DURATION := 0.34
const CAM_SHAKE_MAG_PX := 18.0
const DAMAGE_EDGE_FLASH_IN := 0.055
const DAMAGE_EDGE_FLASH_OUT := 0.32


func _ready() -> void:
	GameManager.game_state_changed.connect(_on_game_state_changed)
	EventBus.run_player_damaged.connect(_on_run_player_damaged)
	EventBus.run_peer_player_damaged.connect(_on_run_peer_player_damaged)
	_setup_audio_streams()
	GameManager.change_state(GameManager.GameState.MENU)
	_lobby.solo_started.connect(_on_lobby_play_started)
	print("[Main] Scene ready")
	call_deferred("_refresh_local_player_cam_target")


func _refresh_local_player_cam_target() -> void:
	var lp := get_tree().get_first_node_in_group("local_player")
	if lp is Node2D:
		_player = lp as Node2D


func _on_lobby_play_started() -> void:
	_bgm.play()
	GameManager.change_state(GameManager.GameState.PLAYING)
	call_deferred("_refresh_local_player_cam_target")


func _setup_audio_streams() -> void:
	var s: AudioStream = _bgm.stream
	if s is AudioStreamMP3:
		(s as AudioStreamMP3).loop = true


func _on_game_state_changed(state_name: String) -> void:
	if state_name == "PAUSED":
		_bgm.stream_paused = true
	elif state_name == "PLAYING":
		_bgm.stream_paused = false


func _process(delta: float) -> void:
	if not is_instance_valid(_player) or not _player.is_inside_tree():
		var lp := get_tree().get_first_node_in_group("local_player")
		if lp is Node2D:
			_player = lp as Node2D
	if is_instance_valid(_player):
		# 道路與關卡以 x=0 為車道中心；相機若跟玩家 lateral 平移，左右會露出大片未繪製區（灰底）。
		var pg: Vector2 = _player.global_position
		_cam.global_position = Vector2(0.0, pg.y)
	else:
		_cam.global_position = _CAMERA_WORLD_FALLBACK
	if _cam_shake_t > 0.0:
		_cam_shake_t -= delta
		var a: float = clampf(_cam_shake_t / CAM_SHAKE_DURATION, 0.0, 1.0)
		var mag: float = CAM_SHAKE_MAG_PX * a * a
		_cam.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * mag
	else:
		_cam.offset = Vector2.ZERO


func _on_run_player_damaged(_remaining: int, _maximum: int) -> void:
	if is_instance_valid(_damage_sfx):
		_damage_sfx.play()
	_cam_shake_t = CAM_SHAKE_DURATION
	Input.vibrate_handheld(220, 0.85)
	if not is_instance_valid(_damage_edge):
		return
	_damage_edge.modulate = Color(1, 1, 1, 0)
	var tw := create_tween()
	tw.tween_property(_damage_edge, "modulate:a", 1.0, DAMAGE_EDGE_FLASH_IN).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_damage_edge, "modulate:a", 0.0, DAMAGE_EDGE_FLASH_OUT).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _on_run_peer_player_damaged(peer_id: int, _r: int, _m: int) -> void:
	if not multiplayer.has_multiplayer_peer() or peer_id != multiplayer.get_unique_id():
		return
	_on_run_player_damaged(0, 0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if GameManager.is_playing():
			GameManager.pause()
		elif GameManager.current_state == GameManager.GameState.PAUSED:
			GameManager.resume()
	if event.is_action_pressed("restart_run") and GameManager.is_game_over():
		if _game_root.has_method("reset_run"):
			_game_root.reset_run()
