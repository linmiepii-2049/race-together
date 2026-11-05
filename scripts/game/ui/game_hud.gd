extends CanvasLayer

const DISPLAY_DISTANCE_SCALE := 10.0
const ENDLESS_BAR_SPAN := 8000.0
const HINT_SEC := 3.4
const POPUP_SEC := 0.8

@onready var chapter_label: Label = $Root/TopLeft/ChapterLabel
@onready var score_label: Label = $Root/TopLeft/ScoreLabel
@onready var coin_label: Label = $Root/TopLeft/CoinLabel
@onready var combo_label: Label = $Root/TopLeft/ComboLabel
@onready var popup_label: Label = $Root/TopLeft/PopupLabel
@onready var shield_icons: Control = $Root/TopLeft/ShieldIcons
@onready var peers_shield_label: Label = $Root/TopLeft/PeersShieldLabel
@onready var speed_gauge: Control = $Root/TopRight/SpeedGauge
@onready var speed_value: Label = $Root/TopRight/SpeedValue
@onready var nitro_bar: Control = $Root/Bottom/NitroBar
@onready var progress_caption: Label = $Root/Bottom/ProgressCaption
@onready var progress_bar: Control = $Root/Bottom/ProgressBar
@onready var tutorial: Label = $Root/Tutorial

var _balance: Resource
var _shield_base: Color = Color.WHITE
var _hint_left: float = 0.0
var _popup_left: float = 0.0
var _story_bar: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := get_node_or_null("Root") as Control
	if root:
		root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_balance = load("res://resources/game/game_balance.tres") as Resource
	if shield_icons:
		_shield_base = shield_icons.modulate
	popup_label.visible = false
	tutorial.visible = false
	peers_shield_label.visible = false
	EventBus.run_score_changed.connect(_on_score)
	EventBus.shield_changed.connect(_on_shield)
	EventBus.run_player_damaged.connect(_on_player_damaged)
	EventBus.run_peer_player_damaged.connect(_on_peer_player_damaged)
	EventBus.multiplayer_peers_hud.connect(_on_multiplayer_peers_hud)
	EventBus.run_speed_changed.connect(_on_speed)
	EventBus.run_distance_changed.connect(_on_distance)
	EventBus.chapter_progress.connect(_on_chapter)
	EventBus.nitro_changed.connect(_on_nitro)
	EventBus.coins_changed.connect(_on_coins)
	EventBus.combo_changed.connect(_on_combo)
	EventBus.near_miss.connect(_on_near_miss)
	EventBus.tutorial_hint.connect(_on_hint)
	GameManager.game_state_changed.connect(_on_state)
	_on_state(GameManager.GameState.keys()[GameManager.current_state])


func _process(delta: float) -> void:
	if _hint_left > 0.0:
		_hint_left -= delta
		if _hint_left <= 0.0 and tutorial:
			tutorial.visible = false
	if _popup_left > 0.0:
		_popup_left -= delta
		if _popup_left <= 0.0 and popup_label:
			popup_label.visible = false


func _on_state(state_name: String) -> void:
	visible = (
		state_name == "PLAYING"
		or state_name == "PAUSED"
		or state_name == "GAME_OVER"
		or state_name == "DIALOGUE"
	)


func _on_score(score: int) -> void:
	if score_label:
		score_label.text = "分數  %d" % score


func _on_coins(run_coins: int) -> void:
	if coin_label:
		coin_label.text = "金幣  %d" % run_coins


func _on_shield(current: int, maximum: int) -> void:
	if shield_icons and shield_icons.has_method("set_shields"):
		shield_icons.call("set_shields", current, maximum)


func _on_player_damaged(_remaining: int, _maximum: int) -> void:
	if shield_icons == null:
		return
	var tw := shield_icons.create_tween()
	shield_icons.modulate = Color(1.0, 0.42, 0.38, 1.0)
	tw.tween_property(shield_icons, "modulate", _shield_base, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_peer_player_damaged(peer_id: int, _remaining: int, _maximum: int) -> void:
	if not GameManager.is_online_match() or peer_id != multiplayer.get_unique_id():
		return
	_on_player_damaged(0, 0)


func _on_multiplayer_peers_hud(line: String) -> void:
	if peers_shield_label == null:
		return
	if line.is_empty() or not GameManager.is_online_match():
		peers_shield_label.visible = false
		return
	peers_shield_label.visible = true
	peers_shield_label.text = "全員 " + line


func _on_speed(speed: float) -> void:
	var cap := 520.0
	if _balance != null:
		cap = _balance.scroll_speed_max * _balance.nitro_speed_mult
	if speed_gauge and speed_gauge.has_method("set_ratio"):
		speed_gauge.call("set_ratio", speed / maxf(cap, 1.0))
	if speed_value:
		speed_value.text = "%d" % int(speed)


func _on_distance(total: float) -> void:
	if _story_bar or GameManager.play_mode == GameManager.PlayMode.STORY:
		return
	if chapter_label:
		chapter_label.text = "連線競速" if GameManager.play_mode == GameManager.PlayMode.ONLINE else "無盡迴廊"
	var span := ENDLESS_BAR_SPAN
	if progress_bar and progress_bar.has_method("set_ratio"):
		progress_bar.call("set_ratio", fmod(total, span) / span)
	if progress_caption:
		progress_caption.text = "距離  %d" % int(total / DISPLAY_DISTANCE_SCALE)


func _on_chapter(distance: float, goal: float, title: String) -> void:
	_story_bar = true
	if chapter_label:
		chapter_label.text = title
	if progress_bar and progress_bar.has_method("set_ratio"):
		progress_bar.call("set_ratio", distance / maxf(goal, 1.0))
	if progress_caption:
		progress_caption.text = "進度  %d / %d" % [
			int(distance / DISPLAY_DISTANCE_SCALE),
			int(goal / DISPLAY_DISTANCE_SCALE),
		]


func _on_nitro(charge: float, boosting: bool) -> void:
	if nitro_bar and nitro_bar.has_method("set_ratio"):
		nitro_bar.call("set_ratio", 1.0 if boosting else charge)


func _on_combo(combo: int) -> void:
	if combo_label == null:
		return
	combo_label.text = "連擊  ×%d" % combo if combo > 1 else ""


func _on_near_miss(points: int, _combo: int) -> void:
	if popup_label == null:
		return
	popup_label.text = "擦身  +%d" % points
	popup_label.visible = true
	_popup_left = POPUP_SEC


func _on_hint(text: String) -> void:
	if tutorial == null:
		return
	if text.is_empty():
		tutorial.visible = false
		_hint_left = 0.0
		return
	tutorial.text = text
	tutorial.visible = true
	_hint_left = HINT_SEC
