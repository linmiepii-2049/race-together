extends RefCounted

const DEFAULT_PATH := "user://profile.cfg"
const SKIN_DEFAULT := "cyan"

var coins: int = 0
var selected_skin: String = SKIN_DEFAULT
var unlocked: Dictionary = {}
var best_story: int = 0
var best_endless: int = 0
var best_online: int = 0
var volume: float = 0.8
var path: String = DEFAULT_PATH


func _init() -> void:
	unlocked[SKIN_DEFAULT] = true


func load_from(p_path: String) -> void:
	path = p_path
	var cf := ConfigFile.new()
	if cf.load(path) != OK:
		return
	coins = int(cf.get_value("profile", "coins", 0))
	selected_skin = str(cf.get_value("profile", "skin", SKIN_DEFAULT))
	best_story = int(cf.get_value("profile", "best_story", 0))
	best_endless = int(cf.get_value("profile", "best_endless", 0))
	best_online = int(cf.get_value("profile", "best_online", 0))
	volume = float(cf.get_value("profile", "volume", 0.8))
	unlocked.clear()
	unlocked[SKIN_DEFAULT] = true
	var raw := str(cf.get_value("profile", "unlocked", SKIN_DEFAULT))
	for part in raw.split(",", false):
		unlocked[part] = true
	if not is_unlocked(selected_skin):
		selected_skin = SKIN_DEFAULT


func save() -> void:
	var cf := ConfigFile.new()
	cf.set_value("profile", "coins", coins)
	cf.set_value("profile", "skin", selected_skin)
	cf.set_value("profile", "best_story", best_story)
	cf.set_value("profile", "best_endless", best_endless)
	cf.set_value("profile", "best_online", best_online)
	cf.set_value("profile", "volume", volume)
	var ids := PackedStringArray()
	for key in unlocked.keys():
		if bool(unlocked[key]):
			ids.append(str(key))
	cf.set_value("profile", "unlocked", ",".join(ids))
	cf.save(path)


func is_unlocked(skin_id: String) -> bool:
	return bool(unlocked.get(skin_id, false))


func best_for(mode_key: String) -> int:
	match mode_key:
		"story":
			return best_story
		"online":
			return best_online
		_:
			return best_endless


func commit_run(mode_key: String, score: int, earned: int) -> Dictionary:
	var prev := best_for(mode_key)
	var is_new := score > prev
	if is_new:
		match mode_key:
			"story":
				best_story = score
			"online":
				best_online = score
			_:
				best_endless = score
	var gained := maxi(0, earned)
	coins += gained
	save()
	return {
		"best": best_for(mode_key),
		"is_new_record": is_new,
		"coins": coins,
		"earned": gained,
		"score": score,
	}


func try_unlock(skin_id: String, cost: int) -> bool:
	if is_unlocked(skin_id):
		selected_skin = skin_id
		save()
		return true
	if coins < cost:
		return false
	coins -= cost
	unlocked[skin_id] = true
	selected_skin = skin_id
	save()
	return true
