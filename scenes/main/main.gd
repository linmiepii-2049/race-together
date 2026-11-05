extends Node2D

@onready var _menu: CanvasLayer = $MainMenu
@onready var _lobby: CanvasLayer = $NetworkLobby
@onready var _cutscene: CanvasLayer = $Cutscene
@onready var _game_root: Node = $GameRoot
@onready var _results: Node = $GameRoot/Results
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
	EventBus.story_lines_requested.connect(_on_story_lines)
	_setup_audio_streams()
	_menu.story_selected.connect(_on_story)
	_menu.endless_selected.connect(_on_endless)
	_menu.online_selected.connect(_on_online)
	_cutscene.sequence_finished.connect(_on_cutscene_finished)
	_results.retry_requested.connect(_on_retry)
	_results.menu_requested.connect(_on_back_to_menu)
	_lobby.back_to_menu.connect(_on_lobby_back)
	_lobby.solo_started.connect(_start_gameplay)
	var launch := GameManager.pending_launch
	GameManager.pending_launch = ""
	if launch == "story":
		_begin_story(false)
	elif launch == "endless":
		_begin_endless()
	elif launch == "online":
		_show_online()
	else:
		GameManager.set_play_mode(GameManager.PlayMode.NONE)
		GameManager.change_state(GameManager.GameState.MENU)
		_menu.visible = true
		_lobby.visible = false
	print("[Main] Scene ready")
	call_deferred("_refresh_local_player_cam_target")


func _refresh_local_player_cam_target() -> void:
	var lp := get_tree().get_first_node_in_group("local_player")
	if lp is Node2D:
		_player = lp as Node2D


func _on_story() -> void:
	_begin_story(true)


func _on_endless() -> void:
	_begin_endless()


func _on_online() -> void:
	_show_online()


func _begin_story(opening: bool) -> void:
	GameManager.set_play_mode(GameManager.PlayMode.STORY)
	_menu.visible = false
	_lobby.visible = false
	if opening:
		GameManager.change_state(GameManager.GameState.CUTSCENE)
		_ensure_bgm()
		_cutscene.play_opening()
	else:
		_start_gameplay()


func _begin_endless() -> void:
	GameManager.set_play_mode(GameManager.PlayMode.ENDLESS)
	_menu.visible = false
	_lobby.visible = false
	_start_gameplay()


func _show_online() -> void:
	GameManager.set_play_mode(GameManager.PlayMode.ONLINE)
	_menu.visible = false
	_cutscene.visible = false
	_lobby.visible = true
	GameManager.change_state(GameManager.GameState.MENU)


func _start_gameplay() -> void:
	_menu.visible = false
	_lobby.visible = false
	_cutscene.visible = false
	if GameManager.play_mode == GameManager.PlayMode.NONE:
		GameManager.set_play_mode(GameManager.PlayMode.ENDLESS)
	if GameManager.play_mode == GameManager.PlayMode.STORY:
		EventBus.story_run_started.emit()
	_ensure_bgm()
	GameManager.change_state(GameManager.GameState.PLAYING)
	call_deferred("_refresh_local_player_cam_target")


func _on_story_lines(lines: Array, kind: String) -> void:
	_cutscene.play_lines(lines, kind)


func _on_cutscene_finished(kind: String) -> void:
	if kind == "opening":
		_start_gameplay()
	elif kind == "interlude":
		EventBus.story_chapter_advanced.emit()
		GameManager.change_state(GameManager.GameState.PLAYING)
	elif kind == "ending":
		EventBus.run_finished.emit(true, "story_clear")
		GameManager.change_state(GameManager.GameState.GAME_OVER)


func _on_retry() -> void:
	GameManager.pending_launch = _launch_id()
	get_tree().paused = false
	if _game_root.has_method("reset_run"):
		_game_root.reset_run()


func _on_back_to_menu() -> void:
	GameManager.pending_launch = ""
	GameManager.set_play_mode(GameManager.PlayMode.NONE)
	get_tree().paused = false
	if _game_root.has_method("reset_run"):
		_game_root.reset_run()


func _on_lobby_back() -> void:
	_lobby.visible = false
	_menu.visible = true
	GameManager.set_play_mode(GameManager.PlayMode.NONE)
	GameManager.change_state(GameManager.GameState.MENU)


func _launch_id() -> String:
	match GameManager.play_mode:
		GameManager.PlayMode.STORY:
			return "story"
		GameManager.PlayMode.ONLINE:
			return "online"
		_:
			return "endless"


func _ensure_bgm() -> void:
	if is_instance_valid(_bgm) and not _bgm.playing:
		_bgm.play()


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
		_on_retry()
