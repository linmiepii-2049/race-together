extends GutTest

const _SP = preload("res://scripts/net/signaling_protocol.gd")

func test_build_and_parse_roundtrip() -> void:
	var s: String = _SP.build_json(_SP.Message.JOIN, 0, "ROOM1")
	var p: Dictionary = _SP.parse_json(s)
	assert_true(p.get("ok", false))
	assert_eq(p.type, _SP.Message.JOIN)
	assert_eq(p.id, 0)
	assert_eq(p.data, "ROOM1")


func test_parse_rejects_non_object() -> void:
	var p: Dictionary = _SP.parse_json("[]")
	assert_false(p.get("ok", false))


func test_parse_candidate_lines() -> void:
	var d: Dictionary = _SP.parse_candidate_lines("\nmid\n3\nsdpbody")
	assert_true(d.ok)
	assert_eq(d.mid, "mid")
	assert_eq(d.index, 3)
	assert_eq(d.sdp, "sdpbody")
