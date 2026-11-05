extends CanvasLayer

signal story_selected
signal endless_selected
signal online_selected

const _Skins := preload("res://scripts/game/car_skins.gd")
const _Style := preload("res://scripts/game/ui/neon_style.gd")

@onready var _buttons: Control = $Center/Panel/Margin/Stack/Buttons
@onready var _settings: Control = $Center/Panel/Margin/Stack/Settings
@onready var _coin_label: Label = $Center/Panel/Margin/Stack/Settings/CoinLabel
@onready var _volume: HSlider = $Center/Panel/Margin/Stack/Settings/Volume
@onready var _skin_box: VBoxContainer = $Center/Panel/Margin/Stack/Settings/SkinBox
@onready var _panel: PanelContainer = $Center/Panel


func _ready() -> void:
	_panel.add_theme_stylebox_override("panel", _Style.panel())
	for b in _buttons.get_children():
		if b is Button:
			_Style.button(b)
	_Style.button($Center/Panel/Margin/Stack/Settings/BtnSettingsBack)
	$Center/Panel/Margin/Stack/Buttons/BtnStory.pressed.connect(func() -> void: story_selected.emit())
	$Center/Panel/Margin/Stack/Buttons/BtnEndless.pressed.connect(func() -> void: endless_selected.emit())
	$Center/Panel/Margin/Stack/Buttons/BtnOnline.pressed.connect(func() -> void: online_selected.emit())
	$Center/Panel/Margin/Stack/Buttons/BtnSettings.pressed.connect(_open_settings)
	$Center/Panel/Margin/Stack/Settings/BtnSettingsBack.pressed.connect(_close_settings)
	_volume.value_changed.connect(_on_volume)
	_show_home()


func _show_home() -> void:
	_buttons.visible = true
	_settings.visible = false


func _open_settings() -> void:
	_buttons.visible = false
	_settings.visible = true
	_refresh_settings()


func _close_settings() -> void:
	_show_home()


func _refresh_settings() -> void:
	var profile: RefCounted = GameManager.profile
	var coins := 0
	var volume := 0.8
	if profile != null:
		coins = int(profile.coins)
		volume = float(profile.volume)
	_coin_label.text = "持有金幣　%d" % coins
	_volume.set_value_no_signal(volume * 100.0)
	for c in _skin_box.get_children():
		c.queue_free()
	for entry in _Skins.all_skins():
		var skin_id := str(entry["id"])
		var cost := int(entry["cost"])
		var unlocked := profile != null and bool(profile.call("is_unlocked", skin_id))
		var selected := profile != null and str(profile.selected_skin) == skin_id
		var b := Button.new()
		if unlocked and selected:
			b.text = "▶ %s・使用中" % str(entry["name"])
		elif unlocked:
			b.text = "%s・已解鎖" % str(entry["name"])
		else:
			b.text = "%s・%d 金幣解鎖" % [str(entry["name"]), cost]
		_Style.button(b)
		b.pressed.connect(_on_skin.bind(skin_id, cost))
		_skin_box.add_child(b)


func _on_skin(skin_id: String, cost: int) -> void:
	if GameManager.profile == null:
		return
	GameManager.profile.call("try_unlock", skin_id, cost)
	_refresh_settings()


func _on_volume(v: float) -> void:
	if GameManager.profile == null:
		return
	GameManager.profile.volume = clampf(v / 100.0, 0.0, 1.0)
	GameManager.apply_saved_volume()
	GameManager.profile.save()
