extends RefCounted


static func button(b: Button) -> void:
	var normal := _box(Color(0.08, 0.05, 0.14, 0.94), Color(0.3, 1.0, 0.95, 0.9))
	var hover := _box(Color(0.2, 0.07, 0.18, 0.96), Color(1.0, 0.32, 0.75, 1.0))
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("focus", hover)
	b.add_theme_stylebox_override("disabled", _box(Color(0.08, 0.08, 0.1, 0.7), Color(0.3, 0.3, 0.35, 0.5)))
	b.add_theme_color_override("font_color", Color(0.92, 1.0, 1.0))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 1.0))
	b.add_theme_font_size_override("font_size", 22)


static func panel() -> StyleBoxFlat:
	return _box(Color(0.04, 0.02, 0.09, 0.92), Color(0.35, 1.0, 0.95, 0.75))


static func _box(bg: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(8)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	return box
