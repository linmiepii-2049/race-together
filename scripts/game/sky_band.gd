extends Sprite2D

## 只使用原圖「上方」一條當遠景天空，避免整張等距賽道與無盡霓虹帶衝突。
@export var sky_fraction: float = 0.3
@export var parallax_factor: float = 0.06
@export var tint: Color = Color(0.42, 0.52, 0.68, 0.92)

var _scroll: Node


func _ready() -> void:
	modulate = tint
	if texture == null:
		return
	var sz: Vector2 = texture.get_size()
	var strip_h: float = maxf(8.0, sz.y * sky_fraction)
	region_enabled = true
	region_rect = Rect2(0.0, 0.0, sz.x, strip_h)
	centered = true
	scale = Vector2(1.25, 1.25)
	position = Vector2(0.0, -140.0)
	_scroll = get_node_or_null("../../ScrollController") as Node


func _physics_process(delta: float) -> void:
	if _scroll == null or not GameManager.is_playing():
		return
	if not _scroll.has_method("get_scroll_speed"):
		return
	var spd: float = float(_scroll.call("get_scroll_speed"))
	position.y += spd * parallax_factor * delta
