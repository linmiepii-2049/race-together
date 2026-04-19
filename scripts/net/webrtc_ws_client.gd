extends Node

const _SP = preload("res://scripts/net/signaling_protocol.gd")

@export var autojoin: bool = true
@export var lobby: String = ""
@export var mesh: bool = true

var ws := WebSocketPeer.new()
var close_code := 1000
var close_reason: String = "Unknown"
var old_state := WebSocketPeer.STATE_CLOSED

signal lobby_joined(lobby_name: String)
signal connected(id: int, use_mesh: bool)
signal disconnected()
signal peer_connected(id: int)
signal peer_disconnected(id: int)
signal offer_received(id: int, offer: String)
signal answer_received(id: int, answer: String)
signal candidate_received(id: int, mid: String, index: int, sdp: String)
signal lobby_sealed()


func connect_to_url(url: String) -> void:
	close()
	close_code = 1000
	close_reason = "Unknown"
	ws.connect_to_url(url)


func close() -> void:
	ws.close()


func _process(_delta: float) -> void:
	ws.poll()
	var state := ws.get_ready_state()
	if state != old_state and state == WebSocketPeer.STATE_OPEN and autojoin:
		join_lobby(lobby)
	while state == WebSocketPeer.STATE_OPEN and ws.get_available_packet_count():
		if not _parse_msg():
			push_error("Error parsing message from signaling server.")
	if state != old_state and state == WebSocketPeer.STATE_CLOSED:
		close_code = ws.get_close_code()
		close_reason = ws.get_close_reason()
		disconnected.emit()
	old_state = state


func _parse_msg() -> bool:
	var parsed: Dictionary = _SP.parse_json(ws.get_packet().get_string_from_utf8())
	if not parsed.get("ok", false):
		return false
	var msg_type: int = parsed.type
	var src_id: int = parsed.id
	var data: String = parsed.data

	if msg_type == _SP.Message.ID:
		connected.emit(src_id, data == "true")
	elif msg_type == _SP.Message.JOIN:
		lobby_joined.emit(data)
	elif msg_type == _SP.Message.SEAL:
		lobby_sealed.emit()
	elif msg_type == _SP.Message.PEER_CONNECT:
		peer_connected.emit(src_id)
	elif msg_type == _SP.Message.PEER_DISCONNECT:
		peer_disconnected.emit(src_id)
	elif msg_type == _SP.Message.OFFER:
		offer_received.emit(src_id, data)
	elif msg_type == _SP.Message.ANSWER:
		answer_received.emit(src_id, data)
	elif msg_type == _SP.Message.CANDIDATE:
		var cand: Dictionary = _SP.parse_candidate_lines(data)
		if not cand.get("ok", false):
			return false
		candidate_received.emit(src_id, cand.mid, cand.index, cand.sdp)
	else:
		return false

	return true


func join_lobby(lobby_name: String) -> Error:
	return _send_msg(_SP.Message.JOIN, 0 if mesh else 1, lobby_name)


func seal_lobby() -> Error:
	return _send_msg(_SP.Message.SEAL, 0)


func send_candidate(id: int, mid: String, index: int, sdp: String) -> Error:
	return _send_msg(_SP.Message.CANDIDATE, id, "\n%s\n%d\n%s" % [mid, index, sdp])


func send_offer(id: int, offer: String) -> Error:
	return _send_msg(_SP.Message.OFFER, id, offer)


func send_answer(id: int, answer: String) -> Error:
	return _send_msg(_SP.Message.ANSWER, id, answer)


func _send_msg(msg_type: int, id: int, data: String = "") -> Error:
	return ws.send_text(_SP.build_json(msg_type, id, data))
