extends Control

var ratio: float = 0.0


func set_ratio(v: float) -> void:
	ratio = clampf(v, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var c := Vector2(size.x * 0.5, size.y * 0.72)
	var radius := minf(size.x, size.y) * 0.42
	draw_arc(c, radius, PI, TAU, 28, Color(0.15, 0.18, 0.22), 6.0, true)
	var angle := PI + PI * ratio
	if ratio > 0.01:
		draw_arc(c, radius, PI, angle, 28, Color(0.3, 1.0, 0.9), 6.0, true)
	draw_line(c, c + Vector2(cos(angle), sin(angle)) * (radius - 2.0), Color(1, 0.85, 0.4), 2.0)
