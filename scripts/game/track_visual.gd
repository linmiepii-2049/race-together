extends Node2D

var _balance: Resource
var _scroll: Node


func setup(p_balance: Resource, p_scroll: Node) -> void:
	_balance = p_balance
	_scroll = p_scroll
	_build_grid()


func _build_grid() -> void:
	for c in get_children():
		c.queue_free()
	var half: float = _balance.half_lane_width if _balance else 420.0
	var spacing: float = 64.0
	var x: float = -half
	while x <= half:
		var ln := Line2D.new()
		ln.width = 2.0
		ln.default_color = Color(0.2, 0.95, 1.0, 0.4)
		ln.points = PackedVector2Array([Vector2(x, -120), Vector2(x, 820)])
		add_child(ln)
		x += spacing
