extends Control

@export var fill: Color = Color(0.25, 1.0, 0.95, 1.0)

var ratio: float = 0.0


func set_ratio(v: float) -> void:
	ratio = clampf(v, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.02, 0.05, 0.72))
	draw_rect(Rect2(0, 0, size.x * ratio, size.y), fill)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.3, 1.0, 0.95, 0.35), false, 1.0)
