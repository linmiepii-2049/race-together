extends RefCounted

const SKINS: Array = [
	{"id": "cyan", "name": "氰光", "cost": 0, "color": Color(0.62, 0.88, 1.0, 1.0)},
	{"id": "magenta", "name": "緋霓", "cost": 30, "color": Color(1.0, 0.35, 0.75, 1.0)},
	{"id": "lime", "name": "酸綠", "cost": 60, "color": Color(0.55, 1.0, 0.45, 1.0)},
	{"id": "gold", "name": "金焰", "cost": 100, "color": Color(1.0, 0.82, 0.28, 1.0)},
	{"id": "violet", "name": "電紫", "cost": 150, "color": Color(0.72, 0.45, 1.0, 1.0)},
]


static func all_skins() -> Array:
	return SKINS


static func color_of(skin_id: String) -> Color:
	for entry in SKINS:
		if str(entry["id"]) == skin_id:
			return entry["color"]
	return SKINS[0]["color"]
