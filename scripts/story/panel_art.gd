extends Control

var panel_index: int = 0

const _BG := Color(0.04, 0.03, 0.09, 1)
const _CYAN := Color(0.35, 1.0, 0.95)
const _MAGENTA := Color(1.0, 0.28, 0.72)
const _AMBER := Color(1.0, 0.78, 0.28)
const _VIOLET := Color(0.62, 0.4, 1.0)
const _ROAD := Color(0.08, 0.09, 0.12)


func set_panel(index: int) -> void:
	panel_index = index
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), _BG)
	match panel_index:
		0:
			_city()
		1:
			_fox()
		2:
			_baron()
		_:
			_hawk()
	draw_rect(Rect2(Vector2.ZERO, size), _CYAN, false, 2.0)


func _city() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(0, h * 0.55, w, h * 0.45), _ROAD)
	draw_line(Vector2(w * 0.5, h * 0.55), Vector2(w * 0.5, h), _AMBER, 3.0)
	for i in 6:
		var x := 40.0 + float(i) * (w - 80.0) / 5.0
		var bh := 36.0 + float((i * 37) % 70)
		draw_rect(Rect2(x, h * 0.55 - bh, 28, bh), Color(0.1, 0.12, 0.2))
		var win := _CYAN if i % 2 == 0 else _MAGENTA
		draw_rect(Rect2(x + 4, h * 0.55 - bh + 6, 8, 6), win)
	draw_circle(Vector2(w * 0.82, h * 0.22), 18, _MAGENTA)
	draw_line(Vector2(w * 0.15, h * 0.72), Vector2(w * 0.85, h * 0.72), _CYAN, 2.0)


func _fox() -> void:
	var c := size * 0.45
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(0, -70),
		c + Vector2(46, 50),
		c + Vector2(-46, 50),
	]), Color(1.0, 0.45, 0.55))
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-30, -40),
		c + Vector2(-10, -78),
		c + Vector2(-4, -36),
	]), _MAGENTA)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(30, -40),
		c + Vector2(10, -78),
		c + Vector2(4, -36),
	]), _MAGENTA)
	draw_circle(c + Vector2(-14, -8), 4, Color.WHITE)
	draw_circle(c + Vector2(14, -8), 4, Color.WHITE)
	for i in 3:
		draw_rect(Rect2(size.x * 0.72, 40.0 + float(i) * 32.0, 52, 18), _CYAN)


func _baron() -> void:
	var h := size.y
	var w := size.x
	for i in 4:
		var y := 28.0 + float(i) * (h * 0.2)
		draw_line(Vector2(20, y), Vector2(w - 20, y), Color(0.45, 0.5, 0.58), 4.0)
	draw_rect(Rect2(w * 0.42, h * 0.22, 74, 120), Color(0.16, 0.18, 0.22))
	draw_rect(Rect2(w * 0.42, h * 0.22, 74, 14), _AMBER)
	draw_circle(Vector2(w * 0.42 + 37, h * 0.22 + 46), 16, Color(0.75, 0.78, 0.84))


func _hawk() -> void:
	var c := Vector2(size.x * 0.62, size.y * 0.4)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-90, 12),
		c + Vector2(0, -30),
		c + Vector2(90, 12),
		c + Vector2(0, 2),
	]), _VIOLET)
	draw_circle(c, 12, _MAGENTA)
	var car := Vector2(size.x * 0.22, size.y * 0.62)
	draw_rect(Rect2(car.x, car.y, 40, 64), _CYAN)
	draw_rect(Rect2(car.x + 8, car.y + 10, 24, 18), Color(0.08, 0.16, 0.22))
	draw_line(car + Vector2(20, 0), c, _AMBER, 2.0)
