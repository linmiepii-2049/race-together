extends RefCounted

var combo: int = 0
var combo_time_left: float = 0.0
var nitro: float = 0.0


func tick(delta: float, _balance: Resource) -> void:
	if combo_time_left <= 0.0:
		return
	combo_time_left = maxf(0.0, combo_time_left - delta)
	if combo_time_left <= 0.0:
		combo = 0


func register_near_miss(balance: Resource) -> int:
	combo = mini(combo + 1, balance.combo_max)
	combo_time_left = balance.combo_window_sec
	return balance.near_miss_base_points * combo


static func is_near_miss(
	player_pos: Vector2,
	obs_pos: Vector2,
	prev_obs_y: float,
	hit_half: float,
	near_half: float,
) -> bool:
	var crossed := prev_obs_y < player_pos.y and obs_pos.y >= player_pos.y
	if not crossed:
		return false
	var dx := absf(player_pos.x - obs_pos.x)
	return dx > hit_half and dx <= near_half


func charge_nitro(delta: float, drifting: bool, balance: Resource) -> void:
	if balance == null or not drifting:
		return
	nitro = minf(1.0, nitro + balance.nitro_charge_per_sec * delta)


func try_start_boost() -> bool:
	if nitro < 1.0:
		return false
	nitro = 0.0
	return true


static func is_new_record(score: int, best: int) -> bool:
	return score > best


static func chapter_reached(distance: float, goal: float) -> bool:
	return distance >= goal
