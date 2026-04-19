extends RefCounted

enum Message {
	JOIN = 0,
	ID = 1,
	PEER_CONNECT = 2,
	PEER_DISCONNECT = 3,
	OFFER = 4,
	ANSWER = 5,
	CANDIDATE = 6,
	SEAL = 7,
}


static func build_json(msg_type: int, id: int, data: String = "") -> String:
	return JSON.stringify({"type": msg_type, "id": id, "data": data})


static func parse_json(text: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"ok": false, "error": "not_object"}
	var d: Dictionary = parsed
	if not d.has("type") or not d.has("id") or not d.has("data"):
		return {"ok": false, "error": "missing_keys"}
	if typeof(d["type"]) != TYPE_INT and typeof(d["type"]) != TYPE_FLOAT:
		return {"ok": false, "error": "bad_type"}
	if typeof(d["id"]) != TYPE_INT and typeof(d["id"]) != TYPE_FLOAT:
		return {"ok": false, "error": "bad_id"}
	if typeof(d["data"]) != TYPE_STRING:
		return {"ok": false, "error": "bad_data"}
	return {
		"ok": true,
		"type": int(d["type"]),
		"id": int(d["id"]),
		"data": str(d["data"]),
	}


static func parse_candidate_lines(data: String) -> Dictionary:
	var parts: PackedStringArray = data.split("\n", false)
	if parts.size() != 3:
		return {"ok": false}
	if not parts[1].is_valid_int():
		return {"ok": false}
	return {"ok": true, "mid": parts[0], "index": parts[1].to_int(), "sdp": parts[2]}
