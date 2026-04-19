extends Area2D

const BODY_TEXTURE_PATH := "res://assets/sprites/Gemini_Generated_Image_1j05221j05221j05_2.png"
const _SpriteTextureUtil := preload("res://scripts/game/sprite_texture_util.gd")


func _ready() -> void:
	add_to_group("obstacles")
	var body := get_node_or_null("Body") as Sprite2D
	if body != null:
		var tex: Texture2D = _load_sprite_texture(BODY_TEXTURE_PATH)
		if tex != null:
			body.texture = tex
			var util := _SpriteTextureUtil.new()
			util.sync_rect_shape_to_sprite(get_node_or_null("CollisionShape2D") as CollisionShape2D, body)


func _load_sprite_texture(path: String) -> Texture2D:
	var util = _SpriteTextureUtil.new()
	return util.load_texture(path)


var _balance: Resource
var _run: Node
var _scroll: Node
var _t: float = 0.0


func activate(p_balance: Resource, p_run: Node, p_scroll: Node) -> void:
	_balance = p_balance
	_run = p_run
	_scroll = p_scroll
	_t = randf() * TAU


func _physics_process(delta: float) -> void:
	if _scroll == null or _run == null or _balance == null:
		return
	if _run.is_game_over() or not GameManager.is_playing():
		return
	position.y += _scroll.get_scroll_speed() * delta
	_t += delta * 3.3
	position.x += cos(_t) * _balance.drone_lateral_speed * delta
	var lim: float = _balance.get_road_playfield_half_width()
	position.x = clampf(position.x, -lim, lim)
