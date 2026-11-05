extends RefCounted

const KIND_COIN := -1
const KIND_MAGNET := -2
const KIND_SHIELD := -3
const KIND_INVULN := -4

const SET_TUTORIAL := "tutorial"
const SET_CITY := "city"
const SET_BOSS := "boss"

var _set_name: String = SET_CITY
var _wave_index: int = 0
var _step: int = 0
var _time: float = 0.0


func set_set(set_name: String) -> void:
	_set_name = set_name
	_wave_index = 0
	_step = 0
	_time = 0.0


func advance(delta: float, gap: float) -> Array:
	_time += delta
	var waves: Array = _waves_for(_set_name)
	var wave: Array = waves[_wave_index % waves.size()]
	var out: Array = []
	while _step < wave.size():
		var ev: Dictionary = wave[_step]
		if _time + 0.0001 < float(ev["t"]):
			break
		out.append(ev)
		_step += 1
	if _step >= wave.size():
		var end_t := 0.0
		if not wave.is_empty():
			end_t = float(wave[wave.size() - 1]["t"])
		if _time >= end_t + gap:
			_wave_index += 1
			_step = 0
			_time = 0.0
	return out


func lane_x(lane: int, half_width: float) -> float:
	var x := float(lane) * half_width * 0.55
	var limit := maxf(0.0, half_width - 48.0)
	return clampf(x, -limit, limit)


func _waves_for(set_name: String) -> Array:
	match set_name:
		SET_TUTORIAL:
			return _TUTORIAL
		SET_BOSS:
			return _BOSS
		_:
			return _CITY


const _TUTORIAL: Array = [
	[
		{"t": 0.0, "kind": 0, "lane": -1},
		{"t": 0.9, "kind": 0, "lane": 1},
		{"t": 1.6, "kind": KIND_COIN, "lane": 0},
	],
	[
		{"t": 0.0, "kind": 0, "lane": 0},
		{"t": 1.0, "kind": KIND_SHIELD, "lane": -1},
		{"t": 1.8, "kind": 1, "lane": 1},
	],
]

const _CITY: Array = [
	[
		{"t": 0.0, "kind": 0, "lane": -1},
		{"t": 0.55, "kind": 1, "lane": 1},
		{"t": 1.2, "kind": KIND_COIN, "lane": 0},
	],
	[
		{"t": 0.0, "kind": 2, "lane": 0},
		{"t": 0.7, "kind": 0, "lane": -1},
		{"t": 1.3, "kind": KIND_MAGNET, "lane": 1},
	],
	[
		{"t": 0.0, "kind": 1, "lane": -1},
		{"t": 0.45, "kind": 1, "lane": 1},
		{"t": 1.1, "kind": 0, "lane": 0},
		{"t": 1.6, "kind": KIND_COIN, "lane": -1},
	],
]

const _BOSS: Array = [
	[
		{"t": 0.2, "kind": KIND_COIN, "lane": 0},
		{"t": 1.1, "kind": 0, "lane": -1},
	],
	[
		{"t": 0.3, "kind": 1, "lane": 1},
		{"t": 1.2, "kind": KIND_SHIELD, "lane": 0},
		{"t": 1.8, "kind": KIND_COIN, "lane": -1},
	],
]
