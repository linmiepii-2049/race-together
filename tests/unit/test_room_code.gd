extends GutTest

const _RC = preload("res://scripts/net/room_code.gd")

func test_normalize_strips_and_uppercases() -> void:
	assert_eq(_RC.normalize("  ab-cd12  "), "ABCD12")


func test_is_valid_accepts_generated() -> void:
	var c: String = _RC.generate()
	assert_true(_RC.is_valid(c), "generated should validate: %s" % c)


func test_is_valid_rejects_wrong_length() -> void:
	assert_false(_RC.is_valid("ABC"))
	assert_false(_RC.is_valid("ABCDEFGH"))


func test_is_valid_rejects_disallowed_chars() -> void:
	assert_false(_RC.is_valid("ABCD1O")) # 1 and O not in alphabet
	assert_false(_RC.is_valid("ABCDI0")) # I and 0 not in alphabet
