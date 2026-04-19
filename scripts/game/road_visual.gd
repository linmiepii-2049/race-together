extends Node2D

## 俯視道路貼圖：垂直無縫拼接，寬度對齊可玩區（half_lane_width * 2）。

const TILE_COUNT := 4

@export_file("*.png") var road_texture_path: String = "res://assets/backgrounds/road_tile_topdown.png"
## 道路在畫面上相對「左右邊界 half_lane_width」的寬度比例（0~1）
@export var road_width_ratio: float = 0.88

var balance: Resource
var _scroll: Node
var _scroll_accum: float = 0.0
var _tile_h: float = 0.0
var _tiles: Array[Sprite2D] = []


func setup(p_balance: Resource, p_scroll: Node) -> void:
	balance = p_balance
	_scroll = p_scroll
	z_index = -12
	_build_tiles()


func _build_tiles() -> void:
	for t in _tiles:
		if is_instance_valid(t):
			t.queue_free()
	_tiles.clear()
	for c in get_children():
		c.queue_free()
	if balance == null:
		return
	var tex: Texture2D = load(road_texture_path) as Texture2D
	if tex == null:
		var abs_path := ProjectSettings.globalize_path(road_texture_path)
		if FileAccess.file_exists(abs_path):
			var img := Image.load_from_file(abs_path)
			if img != null and img.get_width() > 0:
				tex = ImageTexture.create_from_image(img)
	if tex == null:
		push_warning("[RoadVisual] Missing texture: %s" % road_texture_path)
		return
	var sz: Vector2 = tex.get_size()
	if sz.x < 1.0 or sz.y < 1.0:
		return
	var play_w: float = balance.half_lane_width * 2.0 * clampf(road_width_ratio, 0.2, 1.0)
	var s: float = play_w / sz.x
	_tile_h = sz.y * s
	for i in TILE_COUNT:
		var sp := Sprite2D.new()
		sp.texture = tex
		sp.centered = true
		sp.scale = Vector2(s, s)
		add_child(sp)
		_tiles.append(sp)
	_relayout_tiles()


func _relayout_tiles() -> void:
	if _tiles.is_empty() or _tile_h < 1.0:
		return
	var wrap: float = fposmod(_scroll_accum, _tile_h)
	for i in _tiles.size():
		var y: float = (float(i) - 1.0) * _tile_h - wrap
		_tiles[i].position = Vector2(0.0, y)


func _physics_process(delta: float) -> void:
	if _scroll == null or not _scroll.has_method("get_scroll_speed"):
		return
	if not GameManager.is_playing():
		return
	if _tiles.is_empty():
		return
	var spd: float = float(_scroll.call("get_scroll_speed"))
	_scroll_accum += spd * delta
	_relayout_tiles()
