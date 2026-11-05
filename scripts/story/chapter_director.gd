extends Node

const _Story := preload("res://scripts/story/story_script.gd")
const _Rules := preload("res://scripts/game/score_rules.gd")
const _BossScene := preload("res://scenes/game/obstacles/BossDrone.tscn")

var active: bool = false
var chapter_index: int = 0

var _origin: float = 0.0
var _last_total: float = 0.0
var _waiting: bool = false
var _hint_stage: int = 0
var _boss: Node = null


func _ready() -> void:
	EventBus.story_run_started.connect(_on_story_started)
	EventBus.story_chapter_advanced.connect(advance_chapter)
	EventBus.run_distance_changed.connect(_on_distance)
	EventBus.run_game_over.connect(_on_failed)


func _on_story_started() -> void:
	active = true
	chapter_index = 0
	_origin = 0.0
	_last_total = 0.0
	_waiting = false
	_hint_stage = 0
	_apply_chapter()


func advance_chapter() -> void:
	if not active:
		return
	chapter_index += 1
	if chapter_index >= _Story.chapter_count():
		active = false
		return
	_origin = _last_total
	_waiting = false
	_hint_stage = 0
	_apply_chapter()


func _on_failed(_reason: String) -> void:
	active = false
	_waiting = true
	_clear_boss()


func _on_distance(total: float) -> void:
	_last_total = total
	if not active or _waiting or not GameManager.is_playing():
		return
	var data := _Story.chapter(chapter_index)
	var goal := float(data["goal"])
	var progressed := total - _origin
	EventBus.chapter_progress.emit(progressed, goal, str(data["title"]))
	_hints(progressed)
	if _Rules.chapter_reached(progressed, goal):
		_waiting = true
		_on_chapter_cleared()


func _apply_chapter() -> void:
	var data := _Story.chapter(chapter_index)
	EventBus.wave_set_requested.emit(str(data["wave"]))
	EventBus.chapter_progress.emit(0.0, float(data["goal"]), str(data["title"]))
	if bool(data["boss"]):
		_spawn_boss()
	else:
		_clear_boss()
	if bool(data["tutorial"]):
		var hints: Array = _Story.tutorial_hints()
		if not hints.is_empty():
			EventBus.tutorial_hint.emit(str(hints[0]["text"]))
			_hint_stage = 1
	else:
		EventBus.tutorial_hint.emit("")


func _hints(progress: float) -> void:
	var data := _Story.chapter(chapter_index)
	if not bool(data["tutorial"]):
		return
	var hints: Array = _Story.tutorial_hints()
	while _hint_stage < hints.size() and progress >= float(hints[_hint_stage]["at"]):
		EventBus.tutorial_hint.emit(str(hints[_hint_stage]["text"]))
		_hint_stage += 1


func _on_chapter_cleared() -> void:
	_clear_boss()
	if chapter_index >= _Story.chapter_count() - 1:
		active = false
		EventBus.story_lines_requested.emit(_Story.ending_lines(), "ending")
		GameManager.change_state(GameManager.GameState.CUTSCENE)
		return
	EventBus.story_lines_requested.emit(_Story.interlude_lines(chapter_index), "interlude")
	GameManager.change_state(GameManager.GameState.DIALOGUE)


func _spawn_boss() -> void:
	_clear_boss()
	var world := get_parent().get_node_or_null("World") as Node2D
	if world == null:
		return
	var boss := _BossScene.instantiate()
	world.add_child(boss)
	boss.position = Vector2(0, -40)
	var root := get_parent()
	if boss.has_method("activate"):
		boss.call("activate", root.get("balance"), root.get_node("RunSession"), root.get_node("ScrollController"))
	_boss = boss


func _clear_boss() -> void:
	if is_instance_valid(_boss):
		_boss.queue_free()
	_boss = null
