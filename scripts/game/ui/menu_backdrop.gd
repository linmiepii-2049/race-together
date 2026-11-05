extends Control

const _BG := Color(0.03, 0.02, 0.07, 1.0)
const _CYAN := Color(0.25, 0.95, 1.0, 0.85)
const _MAGENTA := Color(1.0, 0.25, 0.7, 0.55)
const _ROAD := Color(0.07, 0.08, 0.11, 1.0)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), _BG)
	var mid := size.x * 0.5
	var top := size.y * 0.18
	draw_colored_polygon(PackedVector2Array([
		Vector2(mid - 28, top),
		Vector2(mid + 28, top),
		Vector2(mid + size.x * 0.22, size.y),
		Vector2(mid - size.x * 0.22, size.y),
	]), _ROAD)
	draw_line(Vector2(mid - 28, top), Vector2(mid - size.x * 0.22, size.y), _CYAN, 3.0)
	draw_line(Vector2(mid + 28, top), Vector2(mid + size.x * 0.22, size.y), _CYAN, 3.0)
	draw_line(Vector2(mid, top), Vector2(mid, size.y), Color(1.0, 0.72, 0.2, 0.8), 2.0)
	for i in 5:
		var y := top + 70.0 + float(i) * 90.0
		draw_rect(Rect2(40.0 + float(i) * 18.0, y * 0.15, 26, 50 + float(i) * 12.0), _MAGENTA)
		draw_rect(Rect2(size.x - 90.0 - float(i) * 16.0, y * 0.12, 22, 40 + float(i) * 10.0), _CYAN)
