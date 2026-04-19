extends Area2D

const BODY_TEXTURE_PATH := "res://assets/sprites/Gemini_Generated_Image_qmbsb5qmbsb5qmbs_4.png"
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


func activate(p_balance: Resource, p_run: Node, p_scroll: Node) -> void:
	_balance = p_balance
	_run = p_run
	_scroll = p_scroll


func _physics_process(delta: float) -> void:
	if _scroll == null or _run == null:
		return
	if _run.is_game_over() or not GameManager.is_playing():
		return
	position.y += _scroll.get_scroll_speed() * delta
