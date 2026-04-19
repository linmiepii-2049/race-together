extends CanvasLayer

@onready var score_label: Label = $Root/Margin/VBox/ScoreLabel
@onready var shield_label: Label = $Root/Margin/VBox/ShieldLabel
@onready var peers_shield_label: Label = $Root/Margin/VBox/PeersShieldLabel
@onready var game_over_panel: PanelContainer = $Root/GameOverPanel

var _shield_label_base_modulate: Color = Color.WHITE


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := get_node_or_null("Root") as Control
	if root:
		root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.focus_mode = Control.FOCUS_NONE
	var panel := get_node_or_null("Root/GameOverPanel") as Control
	if panel:
		panel.focus_mode = Control.FOCUS_NONE
	game_over_panel.visible = false
	if shield_label:
		_shield_label_base_modulate = shield_label.modulate
	EventBus.run_score_changed.connect(_on_score)
	EventBus.shield_changed.connect(_on_shield)
	EventBus.run_player_damaged.connect(_on_player_damaged)
	EventBus.run_peer_player_damaged.connect(_on_peer_player_damaged)
	EventBus.multiplayer_peers_hud.connect(_on_multiplayer_peers_hud)
	EventBus.run_game_over.connect(_on_game_over)


func _on_score(score: int) -> void:
	if score_label:
		score_label.text = "分數 %d" % score


func _on_shield(current: int, maximum: int) -> void:
	if shield_label:
		shield_label.text = "護盾 %d / %d" % [current, maximum]


func _on_player_damaged(_remaining: int, _maximum: int) -> void:
	if shield_label == null:
		return
	var tw := shield_label.create_tween()
	const HIT := Color(1.0, 0.42, 0.38, 1.0)
	shield_label.modulate = HIT
	tw.tween_property(shield_label, "modulate", _shield_label_base_modulate, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_peer_player_damaged(peer_id: int, _remaining: int, _maximum: int) -> void:
	if not multiplayer.has_multiplayer_peer() or peer_id != multiplayer.get_unique_id():
		return
	_on_player_damaged(0, 0)


func _on_multiplayer_peers_hud(line: String) -> void:
	if peers_shield_label == null:
		return
	if line.is_empty() or not multiplayer.has_multiplayer_peer():
		peers_shield_label.visible = false
		return
	peers_shield_label.visible = true
	peers_shield_label.text = "全員 " + line


func _on_game_over(_reason: String) -> void:
	if game_over_panel:
		game_over_panel.visible = true


func hide_game_over() -> void:
	if game_over_panel:
		game_over_panel.visible = false
