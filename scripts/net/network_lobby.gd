extends CanvasLayer

signal solo_started

const _ROOM := preload("res://scripts/net/room_code.gd")

@export var default_signaling_url: String = "ws://127.0.0.1:9080"

@onready var _url: LineEdit = $Root/Panel/Margin/VBox/UrlRow/UrlField
@onready var _code: LineEdit = $Root/Panel/Margin/VBox/CodeRow/CodeField
@onready var _status: Label = $Root/Panel/Margin/VBox/StatusLabel
@onready var _btn_solo: Button = $Root/Panel/Margin/VBox/BtnSolo
@onready var _btn_host: Button = $Root/Panel/Margin/VBox/BtnHost
@onready var _btn_join: Button = $Root/Panel/Margin/VBox/BtnJoin
@onready var _btn_seal: Button = $Root/Panel/Margin/VBox/BtnSeal
@onready var _btn_begin_net: Button = $Root/Panel/Margin/VBox/BtnBeginNet
@onready var _session: Node = $WebRtcMultiplayerSession


func _ready() -> void:
	_url.text = _resolve_initial_signaling_url()
	_btn_solo.pressed.connect(_on_solo)
	_btn_host.pressed.connect(_on_host)
	_btn_join.pressed.connect(_on_join)
	_btn_seal.pressed.connect(_on_seal)
	_btn_begin_net.pressed.connect(_on_begin_net)
	_session.lobby_joined.connect(_on_lobby_joined)
	_session.disconnected.connect(_on_session_disconnected)
	_btn_seal.disabled = true
	_btn_begin_net.disabled = true


func _on_solo() -> void:
	_session.stop()
	visible = false
	solo_started.emit()


func _on_begin_net() -> void:
	visible = false
	solo_started.emit()


func _on_host() -> void:
	_set_status("連線信令伺服器…")
	_btn_host.disabled = true
	_btn_join.disabled = true
	_code.text = ""
	var url := _url.text.strip_edges()
	_session.start(url, "", false)


func _on_join() -> void:
	var raw := _code.text
	var c := _ROOM.normalize(raw)
	if not _ROOM.is_valid(c):
		_set_status("房間碼須為 6 位英數（不含 0/O/I/1）")
		return
	_set_status("加入房間…")
	_btn_host.disabled = true
	_btn_join.disabled = true
	_session.start(_url.text.strip_edges(), c, false)


func _on_seal() -> void:
	_session.seal_lobby()
	_set_status("已送出封房（稍後可關閉信令連線）")


func _on_lobby_joined(room: String) -> void:
	_code.text = room
	_set_status("房間：" + room + "（分享此碼給好友）")
	_btn_begin_net.disabled = false
	if multiplayer.is_server():
		_btn_seal.disabled = false


func _on_session_disconnected() -> void:
	_set_status("已斷線：" + str(_session.close_code) + " " + _session.close_reason)
	_btn_host.disabled = false
	_btn_join.disabled = false
	_btn_seal.disabled = true
	_btn_begin_net.disabled = true


func _set_status(t: String) -> void:
	_status.text = t


func _resolve_initial_signaling_url() -> String:
	if not OS.has_feature("web"):
		return default_signaling_url
	var from_project := str(ProjectSettings.get_setting("racecar/signaling_url_web", "")).strip_edges()
	if from_project != "":
		return from_project
	if Engine.has_singleton("JavaScriptBridge"):
		var js: Variant = Engine.get_singleton("JavaScriptBridge")
		if js is Object and (js as Object).has_method("eval"):
			var q: Variant = (js as Object).call(
				"eval",
				"(() => { const p = new URLSearchParams(window.location.search); return p.get('signal') || ''; })()",
				true,
			)
			if q is String and str(q).strip_edges() != "":
				return str(q).strip_edges()
	call_deferred("_warn_web_signaling_config")
	return ""


func _warn_web_signaling_config() -> void:
	_set_status("Web：請在 project.godot 的 racecar/signaling_url_web 填入 wss://…，或網址加上 ?signal=（見 DEPLOY.md）")
