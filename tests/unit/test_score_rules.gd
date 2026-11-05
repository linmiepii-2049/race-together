extends GutTest

const _Rules := preload("res://scripts/game/score_rules.gd")
const _Waves := preload("res://scripts/game/wave_script.gd")
const _Profile := preload("res://scripts/game/player_profile.gd")
const _Story := preload("res://scripts/story/story_script.gd")

var _rules: RefCounted
var _balance: Resource
var _profile_path: String = ""


func before_each() -> void:
	_balance = (load("res://resources/game/game_balance.tres") as Resource).duplicate(true)
	_rules = _Rules.new()
	_profile_path = "user://score_rules_%d.cfg" % Time.get_ticks_usec()


func after_each() -> void:
	var abs_path := ProjectSettings.globalize_path(_profile_path)
	if FileAccess.file_exists(_profile_path):
		DirAccess.remove_absolute(abs_path)


func test_near_miss_requires_crossing_outside_hit_band() -> void:
	var player := Vector2(0, 100)
	assert_false(_Rules.is_near_miss(player, Vector2(80, 95), 90, 54, 128))
	assert_false(_Rules.is_near_miss(player, Vector2(40, 120), 90, 54, 128))
	assert_false(_Rules.is_near_miss(player, Vector2(200, 120), 90, 54, 128))
	assert_true(_Rules.is_near_miss(player, Vector2(80, 120), 90, 54, 128))


func test_combo_multiplies_then_resets() -> void:
	_balance.near_miss_base_points = 10
	_balance.combo_max = 4
	_balance.combo_window_sec = 2.0
	assert_eq(_rules.register_near_miss(_balance), 10)
	assert_eq(_rules.combo, 1)
	assert_eq(_rules.register_near_miss(_balance), 20)
	assert_eq(_rules.combo, 2)
	_rules.tick(2.1, _balance)
	assert_eq(_rules.combo, 0)
	assert_eq(_rules.register_near_miss(_balance), 10)


func test_combo_caps() -> void:
	_balance.near_miss_base_points = 5
	_balance.combo_max = 3
	_balance.combo_window_sec = 5.0
	_rules.register_near_miss(_balance)
	_rules.register_near_miss(_balance)
	_rules.register_near_miss(_balance)
	assert_eq(_rules.register_near_miss(_balance), 15)
	assert_eq(_rules.combo, 3)


func test_nitro_charges_only_while_drifting_and_spends_when_full() -> void:
	_balance.nitro_charge_per_sec = 1.0
	_rules.charge_nitro(0.25, false, _balance)
	assert_true(absf(_rules.nitro) < 0.001)
	_rules.charge_nitro(0.25, true, _balance)
	assert_true(absf(_rules.nitro - 0.25) < 0.001)
	assert_false(_rules.try_start_boost())
	_rules.charge_nitro(0.75, true, _balance)
	assert_true(_rules.try_start_boost())
	assert_true(absf(_rules.nitro) < 0.001)
	assert_false(_rules.try_start_boost())


func test_new_record_and_chapter_goal() -> void:
	assert_true(_Rules.is_new_record(10, 0))
	assert_false(_Rules.is_new_record(10, 10))
	assert_false(_Rules.chapter_reached(100.0, 7200.0))
	assert_true(_Rules.chapter_reached(7200.0, 7200.0))


func test_story_has_three_chapters_and_rivals() -> void:
	assert_eq(_Story.chapter_count(), 3)
	assert_eq(_Story.opening_lines().size(), 4)
	assert_true(str(_Story.opening_lines()[1]["speaker"]).contains("霓虹狐"))
	assert_true(str(_Story.opening_lines()[2]["speaker"]).contains("鐵軌男爵"))
	assert_true(str(_Story.opening_lines()[3]["speaker"]).contains("電壓鷹"))
	assert_true(bool(_Story.chapter(2)["boss"]))
	assert_false(bool(_Story.chapter(0)["boss"]))


func test_wave_emits_tutorial_steps_in_order() -> void:
	var waves := _Waves.new()
	waves.set_set(_Waves.SET_TUTORIAL)
	var first: Array = waves.advance(0.0, 1.0)
	assert_eq(first.size(), 1)
	assert_eq(int(first[0]["kind"]), 0)
	assert_eq(int(first[0]["lane"]), -1)
	var early: Array = waves.advance(0.2, 1.0)
	assert_eq(early.size(), 0)
	var second: Array = waves.advance(0.8, 1.0)
	assert_eq(second.size(), 1)
	assert_eq(int(second[0]["lane"]), 1)
	var half: float = 400.0
	assert_true(waves.lane_x(-1, half) < 0.0)
	assert_eq(waves.lane_x(0, half), 0.0)
	assert_true(waves.lane_x(1, half) > 0.0)


func test_profile_persists_coins_record_and_unlock() -> void:
	var profile: RefCounted = _Profile.new()
	profile.load_from(_profile_path)
	assert_eq(profile.coins, 0)
	assert_false(profile.call("try_unlock", "gold", 100))
	var summary: Dictionary = profile.call("commit_run", "story", 80, 3)
	assert_true(bool(summary["is_new_record"]))
	assert_eq(int(summary["best"]), 80)
	assert_eq(int(summary["coins"]), 3)
	profile.coins = 100
	profile.save()
	assert_true(bool(profile.call("try_unlock", "gold", 100)))
	assert_eq(profile.selected_skin, "gold")
	assert_eq(profile.coins, 0)
	var loaded: RefCounted = _Profile.new()
	loaded.load_from(_profile_path)
	assert_eq(loaded.coins, 0)
	assert_eq(loaded.selected_skin, "gold")
	assert_eq(loaded.best_story, 80)
	assert_true(bool(loaded.call("is_unlocked", "gold")))
	assert_true(bool(loaded.call("is_unlocked", "cyan")))
	var again: Dictionary = loaded.call("commit_run", "story", 40, 1)
	assert_false(bool(again["is_new_record"]))
	assert_eq(int(again["best"]), 80)
	assert_eq(loaded.best_endless, 0)
