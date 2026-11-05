extends Control

var current: int = 3
var maximum: int = 3


func set_shields(c: int, m: int) -> void:
	current = maxi(c, 0)
	maximum = maxi(m, 1)
	queue_redraw()


func _draw() -> void:
	for i in maximum:
		var x := float(i) * 26.0
		var col := Color(0.35, 0.95, 1.0) if i < current else Color(0.22, 0.24, 0.28)
		draw_colored_polygon(PackedVector2Array([
			Vector2(x + 10, 2),
			Vector2(x + 20, 11),
			Vector2(x + 10, 22),
			Vector2(x, 11),
		]), col)
