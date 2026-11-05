extends Area2D

enum Phase { HOVER, LUNGE, RETREAT }

const BODY_TEXTURE_PATH := "res://assets/sprites/Gemini_Generated_Image_1j05221j05221j05_2.png"
const _SpriteTextureUtil := preload("res://scripts/game/sprite_texture_util.gd")
const _RING := Color(1.0, 0.3, 0.72, 0.85)

var _balance: Resource
var _run: Node
var _phase: Phase = Phase.HOVER
var _time_left: float = 0.0
var _player: Node2D


func _ready() -> void:
	add_to_group("obstacles")
	var body := get_node_or_null("Body") as Sprite2D
	if body != null:
		var util := _SpriteTextureUtil.new()
		var tex: Texture2D = util.load_texture(BODY_TEXTURE_PATH)
		if tex != null:
			body.texture = tex
			util.sync_rect_shape_to_sprite(get_node_or_null("CollisionShape2D") as CollisionShape2D, body)
		body.modulate = Color(1.0, 0.45, 0.85)


func activate(p_balance: Resource, p_run: Node, _p_scroll: Node) -> void:
	_balance = p_balance
	_run = p_run
	_phase = Phase.HOVER
	_time_left = p_balance.boss_hover_sec
	queue_redraw()


func _draw() -> void:
	draw_arc(Vector2.ZERO, 78.0, 0.0, TAU, 36, _RING, 3.0, true)


func _physics_process(delta: float) -> void:
	if _balance == null or _run == null:
		return
	if _run.is_game_over() or not GameManager.is_playing():
		return
	var player := _resolve_player()
	if player == null:
		return
	_time_left -= delta
	match _phase:
		Phase.HOVER:
			var hover := Vector2(player.position.x, player.position.y - _balance.boss_hover_gap)
			position = position.move_toward(hover, _balance.boss_lateral_speed * delta)
			if _time_left <= 0.0:
				_phase = Phase.LUNGE
				_time_left = _balance.boss_lunge_sec
		Phase.LUNGE:
			position.x = move_toward(position.x, player.position.x, _balance.boss_lateral_speed * 1.4 * delta)
			position.y = move_toward(position.y, player.position.y - 36.0, _balance.boss_lunge_speed * delta)
			if _time_left <= 0.0:
				_phase = Phase.RETREAT
				_time_left = _balance.boss_retreat_sec
		Phase.RETREAT:
			var back_y: float = player.position.y - float(_balance.boss_hover_gap)
			position.y = move_toward(position.y, back_y, float(_balance.boss_lunge_speed) * delta)
			if _time_left <= 0.0:
				_phase = Phase.HOVER
				_time_left = _balance.boss_hover_sec
	var lim: float = _balance.get_road_playfield_half_width()
	position.x = clampf(position.x, -lim, lim)


func _resolve_player() -> Node2D:
	if is_instance_valid(_player):
		return _player
	var n := get_tree().get_first_node_in_group("local_player")
	if n is Node2D:
		_player = n
	return _player
