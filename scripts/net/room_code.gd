extends RefCounted

const CODE_LEN := 6
const ALPHABET := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

static func generate() -> String:
	var out := ""
	for i in CODE_LEN:
		out += ALPHABET[randi() % ALPHABET.length()]
	return out


static func normalize(raw: String) -> String:
	var s := raw.strip_edges().to_upper()
	var cleaned := ""
	for ch in s:
		if ch == " " or ch == "-" or ch == "_":
			continue
		cleaned += ch
	return cleaned


static func is_valid(code: String) -> bool:
	var c := normalize(code)
	if c.length() != CODE_LEN:
		return false
	for ch in c:
		if not ALPHABET.contains(ch):
			return false
	return true
