extends Area2D

const BEAM_TEXTURE_PATH := "res://assets/sprites/Gemini_Generated_Image_1iuj7f1iuj7f1iuj_1.png"
const _SpriteTextureUtil := preload("res://scripts/game/sprite_texture_util.gd")


func _ready() -> void:
	add_to_group("obstacles")
	var beam := get_node_or_null("Beam") as Sprite2D
	if beam != null:
		var tex: Texture2D = _load_sprite_texture(BEAM_TEXTURE_PATH)
		if tex != null:
			beam.texture = tex
			var util := _SpriteTextureUtil.new()
			util.sync_rect_shape_to_sprite(get_node_or_null("CollisionShape2D") as CollisionShape2D, beam)


func _load_sprite_texture(path: String) -> Texture2D:
	var util = _SpriteTextureUtil.new()
	return util.load_texture(path)


var _balance: Resource
var _run: Node
var _scroll: Node
var _phase_on: bool = true
var _timer: float = 0.0


func activate(p_balance: Resource, p_run: Node, p_scroll: Node) -> void:
	_balance = p_balance
	_run = p_run
	_scroll = p_scroll
	_phase_on = true
	_timer = 0.0
	_set_beam_active(true)


func _set_beam_active(on: bool) -> void:
	monitoring = on
	monitorable = on
	var beam := get_node_or_null("Beam") as CanvasItem
	if beam:
		beam.modulate = Color(1.0, 0.25, 0.35, 1.0) if on else Color(0.25, 1.0, 0.9, 0.35)


func _physics_process(delta: float) -> void:
	if _scroll == null or _run == null or _balance == null:
		return
	if _run.is_game_over() or not GameManager.is_playing():
		return
	position.y += _scroll.get_scroll_speed() * delta
	_timer += delta
	var dur: float = _balance.laser_on_sec if _phase_on else _balance.laser_off_sec
	if _timer >= dur:
		_timer = 0.0
		_phase_on = not _phase_on
		_set_beam_active(_phase_on)
