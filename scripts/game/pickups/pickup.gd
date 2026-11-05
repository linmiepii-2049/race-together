extends Area2D

enum PickupType { SHIELD, INVULNERABLE, COIN, MAGNET }

const TEXTURE_SHIELD := "res://assets/sprites/image (27).png"
const TEXTURE_INVULNERABLE := "res://assets/sprites/image (28).png"
const _SpriteTextureUtil := preload("res://scripts/game/sprite_texture_util.gd")
## 貼圖較大時縮放後的較長邊（像素級視覺大小參考）
const SPRITE_TARGET_MAX_PX := 56.0

var _balance: Resource
var _run: Node
var _scroll: Node
var pickup_type: PickupType = PickupType.SHIELD
var _pull_target: Node2D


func _ready() -> void:
	add_to_group("pickups")


func activate(p_balance: Resource, p_run: Node, p_scroll: Node, forced_type: int = -1) -> void:
	_balance = p_balance
	_run = p_run
	_scroll = p_scroll
	if forced_type >= 0:
		pickup_type = forced_type as PickupType
	else:
		pickup_type = PickupType.SHIELD if randf() < 0.55 else PickupType.INVULNERABLE
	var path: String = TEXTURE_SHIELD if pickup_type == PickupType.SHIELD or pickup_type == PickupType.COIN else TEXTURE_INVULNERABLE
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
	match pickup_type:
		PickupType.COIN:
			body.modulate = Color(1.0, 0.84, 0.25)
		PickupType.MAGNET:
			body.modulate = Color(0.35, 0.85, 1.0)
		_:
			body.modulate = Color.WHITE
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
	if pickup_type != PickupType.COIN or not _run.has_method("magnet_active") or not bool(_run.call("magnet_active")):
		return
	if not is_instance_valid(_pull_target):
		var found := get_tree().get_first_node_in_group("local_player")
		if found is Node2D:
			_pull_target = found
	if not is_instance_valid(_pull_target) or _balance == null:
		return
	var parent_2d := get_parent() as Node2D
	if parent_2d == null:
		return
	var dest := parent_2d.to_local(_pull_target.global_position)
	var pull: float = _balance.magnet_pull_px * delta
	position.x = move_toward(position.x, dest.x, pull)
	position.y = move_toward(position.y, dest.y, pull * 0.45)
