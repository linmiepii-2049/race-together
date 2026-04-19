extends "res://scripts/net/webrtc_ws_client.gd"

var rtc_mp := WebRTCMultiplayerPeer.new()
var sealed: bool = false


func _init() -> void:
	connected.connect(_on_connected)
	disconnected.connect(_on_disconnected)
	offer_received.connect(_on_offer_received)
	answer_received.connect(_on_answer_received)
	candidate_received.connect(_on_candidate_received)
	lobby_joined.connect(_on_lobby_joined)
	lobby_sealed.connect(_on_lobby_sealed)
	peer_connected.connect(_on_peer_connected)
	peer_disconnected.connect(_on_peer_disconnected)


func start(url: String, lobby_name: String = "", use_mesh: bool = true) -> void:
	stop()
	sealed = false
	mesh = use_mesh
	lobby = lobby_name
	connect_to_url(url)


func stop() -> void:
	multiplayer.multiplayer_peer = null
	rtc_mp.close()
	close()


func _create_peer(id: int) -> WebRTCPeerConnection:
	var peer := WebRTCPeerConnection.new()
	peer.initialize({
		"iceServers": [{"urls": ["stun:stun.l.google.com:19302"]}],
	})
	peer.session_description_created.connect(_on_offer_created.bind(id))
	peer.ice_candidate_created.connect(_on_new_ice_candidate.bind(id))
	rtc_mp.add_peer(peer, id)
	if id < rtc_mp.get_unique_id():
		peer.create_offer()
	return peer


func _on_new_ice_candidate(mid_name: String, index_name: int, sdp_name: String, id: int) -> void:
	send_candidate(id, mid_name, index_name, sdp_name)


func _on_offer_created(type: String, data: String, id: int) -> void:
	if not rtc_mp.has_peer(id):
		return
	rtc_mp.get_peer(id).connection.set_local_description(type, data)
	if type == "offer":
		send_offer(id, data)
	else:
		send_answer(id, data)


func _on_connected(id: int, use_mesh: bool) -> void:
	if use_mesh:
		rtc_mp.create_mesh(id)
	elif id == 1:
		rtc_mp.create_server()
	else:
		rtc_mp.create_client(id)
	multiplayer.multiplayer_peer = rtc_mp


func _on_lobby_joined(_lobby: String) -> void:
	lobby = _lobby


func _on_lobby_sealed() -> void:
	sealed = true


func _on_disconnected() -> void:
	if not sealed:
		stop()


func _on_peer_connected(id: int) -> void:
	_create_peer(id)


func _on_peer_disconnected(id: int) -> void:
	if rtc_mp.has_peer(id):
		rtc_mp.remove_peer(id)


func _on_offer_received(id: int, offer: String) -> void:
	if rtc_mp.has_peer(id):
		rtc_mp.get_peer(id).connection.set_remote_description("offer", offer)


func _on_answer_received(id: int, answer: String) -> void:
	if rtc_mp.has_peer(id):
		rtc_mp.get_peer(id).connection.set_remote_description("answer", answer)


func _on_candidate_received(id: int, mid: String, index: int, sdp: String) -> void:
	if rtc_mp.has_peer(id):
		rtc_mp.get_peer(id).connection.add_ice_candidate(mid, index, sdp)


func _process(delta: float) -> void:
	super._process(delta)
	if rtc_mp:
		rtc_mp.poll()
