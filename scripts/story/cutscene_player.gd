extends CanvasLayer

signal sequence_finished(kind: String)

const _Story := preload("res://scripts/story/story_script.gd")
const _Style := preload("res://scripts/game/ui/neon_style.gd")
const CHAR_INTERVAL := 0.028

@onready var _speaker: Label = $Center/Panel/Margin/VBox/Speaker
@onready var _body: Label = $Center/Panel/Margin/VBox/Body
@onready var _art: Control = $Center/Panel/Margin/VBox/Art

var _lines: Array = []
var _index: int = 0
var _kind: String = ""
var _full: String = ""
var _shown: int = 0
var _char_acc: float = 0.0


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	var panel := get_node_or_null("Center/Panel") as PanelContainer
	if panel:
		panel.add_theme_stylebox_override("panel", _Style.panel())
	_ignore_mouse(self)


func _ignore_mouse(n: Node) -> void:
	if n is Control:
		(n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in n.get_children():
		_ignore_mouse(child)


func play_opening() -> void:
	play_lines(_Story.opening_lines(), "opening")


func play_lines(lines: Array, kind: String) -> void:
	_lines = lines
	_kind = kind
	_index = 0
	visible = true
	_show_current()


func _show_current() -> void:
	var line: Dictionary = _lines[_index]
	_speaker.text = str(line["speaker"])
	_full = str(line["text"])
	_shown = 0
	_char_acc = 0.0
	_body.text = ""
	if _art.has_method("set_panel"):
		_art.call("set_panel", int(line.get("panel", 0)))


func _process(delta: float) -> void:
	if not visible or _shown >= _full.length():
		return
	_char_acc += delta
	while _char_acc >= CHAR_INTERVAL and _shown < _full.length():
		_char_acc -= CHAR_INTERVAL
		_shown += 1
	_body.text = _full.substr(0, _shown)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var advance := event.is_action_pressed("ui_accept")
	var skip_all := event.is_action_pressed("ui_cancel")
	var click := (
		event is InputEventMouseButton
		and (event as InputEventMouseButton).pressed
		and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
	)
	if not advance and not skip_all and not click:
		return
	if skip_all:
		_finish()
	elif _shown < _full.length():
		_shown = _full.length()
		_body.text = _full
	else:
		_advance()
	get_viewport().set_input_as_handled()


func _advance() -> void:
	_index += 1
	if _index >= _lines.size():
		_finish()
		return
	_show_current()


func _finish() -> void:
	if not visible:
		return
	visible = false
	var kind := _kind
	_lines = []
	sequence_finished.emit(kind)
