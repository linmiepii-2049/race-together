extends CanvasLayer

signal retry_requested
signal menu_requested

const _Style := preload("res://scripts/game/ui/neon_style.gd")

@onready var _title: Label = $Center/Panel/Margin/VBox/Title
@onready var _blurb: Label = $Center/Panel/Margin/VBox/Blurb
@onready var _score: Label = $Center/Panel/Margin/VBox/ScoreLabel
@onready var _best: Label = $Center/Panel/Margin/VBox/BestLabel
@onready var _record: Label = $Center/Panel/Margin/VBox/RecordLabel
@onready var _coins: Label = $Center/Panel/Margin/VBox/CoinLabel
@onready var _retry: Button = $Center/Panel/Margin/VBox/BtnRetry
@onready var _menu: Button = $Center/Panel/Margin/VBox/BtnMenu

var _run_score: int = 0
var _run_coins: int = 0
var _shown: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	$Center/Panel.add_theme_stylebox_override("panel", _Style.panel())
	_Style.button(_retry)
	_Style.button(_menu)
	EventBus.run_score_changed.connect(func(s: int) -> void: _run_score = s)
	EventBus.coins_changed.connect(func(c: int) -> void: _run_coins = c)
	EventBus.run_game_over.connect(_on_fail)
	EventBus.run_finished.connect(_on_finish)
	_retry.pressed.connect(func() -> void: retry_requested.emit())
	_menu.pressed.connect(func() -> void: menu_requested.emit())


func _on_fail(_reason: String) -> void:
	_present(false)


func _on_finish(victory: bool, _reason: String) -> void:
	_present(victory)


func _present(victory: bool) -> void:
	if _shown:
		return
	_shown = true
	visible = true
	var mode_key := "endless"
	var mode_label := "無盡"
	match GameManager.play_mode:
		GameManager.PlayMode.STORY:
			mode_key = "story"
			mode_label = "故事"
		GameManager.PlayMode.ONLINE:
			mode_key = "online"
			mode_label = "連線"
	var summary := {}
	if GameManager.profile != null:
		summary = GameManager.profile.call("commit_run", mode_key, _run_score, _run_coins)
	_title.text = "車隊歸來" if victory else "護盾耗盡"
	if victory:
		_blurb.text = "獵鷹墜入霓虹。被劫走的車隊回到你身邊。"
	else:
		_blurb.text = "迴廊沒有放過你。車隊還在別人手上。"
	_score.text = "%s分數　%d" % [mode_label, _run_score]
	_best.text = "最佳　%d" % int(summary.get("best", _run_score))
	_record.visible = bool(summary.get("is_new_record", false))
	_coins.text = "本局金幣　+%d　　持有　%d" % [
		int(summary.get("earned", _run_coins)),
		int(summary.get("coins", _run_coins)),
	]
