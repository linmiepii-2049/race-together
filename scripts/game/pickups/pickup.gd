extends Area2D

enum PickupType { SHIELD, INVULNERABLE }

const TEXTURE_SHIELD := "res://assets/sprites/image (27).png"
const TEXTURE_INVULNERABLE := "res://assets/sprites/image (28).png"
const _SpriteTextureUtil := preload("res://scripts/game/sprite_texture_util.gd")
## 貼圖較大時縮放後的較長邊（像素級視覺大小參考）
const SPRITE_TARGET_MAX_PX := 56.0

var _balance: Resource
var _run: Node
var _scroll: Node
var pickup_type: PickupType = PickupType.SHIELD


func _ready() -> void:
	add_to_group("pickups")


func activate(p_balance: Resource, p_run: Node, p_scroll: Node) -> void:
	_balance = p_balance
	_run = p_run
	_scroll = p_scroll
	pickup_type = PickupType.SHIELD if randf() < 0.55 else PickupType.INVULNERABLE
	var path: String = (
		TEXTURE_SHIELD if pickup_type == PickupType.SHIELD else TEXTURE_INVULNERABLE
	)
	var body := get_node_or_null("Body") as Sprite2D
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body == null:
		return
	var util := _SpriteTextureUtil.new()
	var tex: Texture2D = util.load_texture(path)
	if tex == null:
		return
	body.texture = tex
	var sz: Vector2 = tex.get_size()
	var m: float = maxf(sz.x, sz.y)
	body.scale = Vector2.ONE if m < 1.0 else Vector2(SPRITE_TARGET_MAX_PX / m, SPRITE_TARGET_MAX_PX / m)
	util.sync_rect_shape_to_sprite(collision, body)


func get_pickup_type() -> PickupType:
	return pickup_type


func is_shield_pickup() -> bool:
	return pickup_type == PickupType.SHIELD


func _physics_process(delta: float) -> void:
	if _scroll == null or _run == null:
		return
	if _run.is_game_over() or not GameManager.is_playing():
		return
	position.y += _scroll.get_scroll_speed() * delta
