extends Node

var balance: Resource

## 單人模式用；連線時護盾改存 _peer_shields。
var score: int = 0
var shield: int = 3
var _invulnerable_until_usec: int = 0
var _is_game_over: bool = false

var _mp_peer_order: Array[int] = []
var _peer_shields: Dictionary = {}
var _peer_invuln_usec: Dictionary = {}
var _peer_eliminated: Dictionary = {}


func setup(p_balance: Resource) -> void:
	balance = p_balance
	_clear_multiplayer_state()
	shield = balance.shield_max
	score = 0
	_is_game_over = false
	_invulnerable_until_usec = 0
	_emit_shield_changed()
	EventBus.run_score_changed.emit(score)


func _clear_multiplayer_state() -> void:
	_mp_peer_order.clear()
	_peer_shields.clear()
	_peer_invuln_usec.clear()
	_peer_eliminated.clear()


func init_peers_for_multiplayer(peer_ids: Array[int]) -> void:
	_clear_multiplayer_state()
	_mp_peer_order = peer_ids.duplicate()
	for pid in peer_ids:
		_peer_shields[pid] = balance.shield_max
		_peer_invuln_usec[pid] = 0
		_peer_eliminated[pid] = false
	score = 0
	_is_game_over = false
	_emit_shield_changed()
	_emit_multiplayer_peers_hud()


func get_ordered_peer_ids() -> PackedInt32Array:
	var out := PackedInt32Array()
	for id in _mp_peer_order:
		out.append(id)
	return out


func build_shield_packed() -> PackedInt32Array:
	var out := PackedInt32Array()
	for id in _mp_peer_order:
		out.append(int(_peer_shields.get(id, 0)))
	return out


func build_invuln_packed() -> PackedInt32Array:
	var out := PackedInt32Array()
	for id in _mp_peer_order:
		out.append(int(_peer_invuln_usec.get(id, 0)))
	return out


func build_elim_packed() -> PackedInt32Array:
	var out := PackedInt32Array()
	for id in _mp_peer_order:
		out.append(1 if bool(_peer_eliminated.get(id, false)) else 0)
	return out


func is_invulnerable() -> bool:
	return Time.get_ticks_usec() < _invulnerable_until_usec


func is_invulnerable_for_peer(peer_id: int) -> bool:
	if not multiplayer.has_multiplayer_peer():
		return is_invulnerable()
	var u: int = int(_peer_invuln_usec.get(peer_id, 0))
	return Time.get_ticks_usec() < u


func is_game_over() -> bool:
	return _is_game_over


func is_peer_out(peer_id: int) -> bool:
	if not multiplayer.has_multiplayer_peer():
		return _is_game_over
	return bool(_peer_eliminated.get(peer_id, false))


func get_invulnerable_until_usec() -> int:
	return _invulnerable_until_usec


func get_invulnerable_until_usec_for_peer(peer_id: int) -> int:
	if not multiplayer.has_multiplayer_peer():
		return _invulnerable_until_usec
	return int(_peer_invuln_usec.get(peer_id, 0))


func sync_from_host(
	p_score: int,
	peer_ids: PackedInt32Array,
	shields: PackedInt32Array,
	invulns: PackedInt32Array,
	elims: PackedInt32Array,
	p_game_over: bool,
) -> void:
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		return
	score = p_score
	_mp_peer_order.clear()
	_peer_shields.clear()
	_peer_invuln_usec.clear()
	_peer_eliminated.clear()
	var n: int = mini(peer_ids.size(), shields.size())
	n = mini(n, invulns.size())
	n = mini(n, elims.size())
	for i in n:
		var pid := int(peer_ids[i])
		_mp_peer_order.append(pid)
		_peer_shields[pid] = int(shields[i])
		_peer_invuln_usec[pid] = int(invulns[i])
		_peer_eliminated[pid] = elims[i] != 0
	if p_game_over and not _is_game_over:
		_is_game_over = true
		EventBus.run_game_over.emit("network")
		GameManager.change_state(GameManager.GameState.GAME_OVER)
	EventBus.run_score_changed.emit(score)
	_emit_shield_changed()
	_emit_multiplayer_peers_hud()


func add_score(delta: int) -> void:
	if _is_game_over:
		return
	score = maxi(0, score + delta)
	EventBus.run_score_changed.emit(score)


func apply_pickup_shield() -> void:
	if _is_game_over or balance == null:
		return
	shield = mini(balance.shield_pickup_cap, shield + 1)
	_emit_shield_changed()


func apply_pickup_invulnerable() -> void:
	if _is_game_over or balance == null:
		return
	_invulnerable_until_usec = Time.get_ticks_usec() + int(balance.invulnerable_pickup_sec * 1_000_000.0)
	EventBus.pickup_invulnerability_started.emit(balance.invulnerable_pickup_sec)


func apply_pickup_shield_for_peer(peer_id: int) -> void:
	if not multiplayer.has_multiplayer_peer() or not multiplayer.is_server():
		return
	if _is_game_over or balance == null:
		return
	if bool(_peer_eliminated.get(peer_id, false)):
		return
	var sh: int = int(_peer_shields.get(peer_id, balance.shield_max))
	sh = mini(balance.shield_pickup_cap, sh + 1)
	_peer_shields[peer_id] = sh
	if peer_id == multiplayer.get_unique_id():
		_emit_shield_changed()
	_emit_multiplayer_peers_hud()


func apply_pickup_invulnerable_for_peer(peer_id: int) -> void:
	if not multiplayer.has_multiplayer_peer() or not multiplayer.is_server():
		return
	if _is_game_over or balance == null:
		return
	if bool(_peer_eliminated.get(peer_id, false)):
		return
	_peer_invuln_usec[peer_id] = Time.get_ticks_usec() + int(balance.invulnerable_pickup_sec * 1_000_000.0)


func register_hit_from_obstacle() -> void:
	# 連線對局以 init_peers_for_multiplayer 為準；僅有 peer 時才禁止此路徑。
	if multiplayer.has_multiplayer_peer() and not _mp_peer_order.is_empty():
		return
	if _is_game_over or balance == null:
		return
	if is_invulnerable():
		return
	shield -= 1
	EventBus.run_player_damaged.emit(shield, balance.shield_max)
	_emit_shield_changed()
	_invulnerable_until_usec = Time.get_ticks_usec() + int(balance.invulnerable_after_hit_sec * 1_000_000.0)
	if shield <= 0:
		_trigger_game_over("shields_depleted")


func register_hit_for_peer(peer_id: int) -> void:
	if not multiplayer.has_multiplayer_peer() or not multiplayer.is_server():
		return
	if _is_game_over or balance == null:
		return
	if bool(_peer_eliminated.get(peer_id, false)):
		return
	if is_invulnerable_for_peer(peer_id):
		return
	var sh: int = int(_peer_shields.get(peer_id, balance.shield_max)) - 1
	_peer_shields[peer_id] = sh
	var tr := get_tree()
	if tr != null:
		var coord := tr.get_first_node_in_group("multiplayer_coordinator") as Node
		if coord != null and coord.has_method("rpc_peer_damage_feedback"):
			coord.rpc_peer_damage_feedback.rpc(peer_id, sh, balance.shield_max)
		else:
			EventBus.run_peer_player_damaged.emit(peer_id, sh, balance.shield_max)
	if peer_id == multiplayer.get_unique_id():
		_emit_shield_changed()
	_peer_invuln_usec[peer_id] = Time.get_ticks_usec() + int(balance.invulnerable_after_hit_sec * 1_000_000.0)
	if sh <= 0:
		_peer_eliminated[peer_id] = true
	_emit_multiplayer_peers_hud()
	_check_all_peers_eliminated()


func _check_all_peers_eliminated() -> void:
	if _mp_peer_order.is_empty():
		return
	for pid in _mp_peer_order:
		if not bool(_peer_eliminated.get(pid, false)):
			return
	_trigger_game_over("all_players_out")


func _trigger_game_over(reason: String) -> void:
	if _is_game_over:
		return
	_is_game_over = true
	EventBus.run_game_over.emit(reason)
	GameManager.change_state(GameManager.GameState.GAME_OVER)


func reset_session() -> void:
	if balance == null:
		return
	_clear_multiplayer_state()
	shield = balance.shield_max
	score = 0
	_is_game_over = false
	_invulnerable_until_usec = 0
	_emit_shield_changed()
	EventBus.run_score_changed.emit(score)
	EventBus.multiplayer_peers_hud.emit("")


func _emit_multiplayer_peers_hud() -> void:
	if balance == null or not multiplayer.has_multiplayer_peer() or _mp_peer_order.is_empty():
		return
	var mx: int = balance.shield_max
	var segs: PackedStringArray = PackedStringArray()
	var my_id: int = multiplayer.get_unique_id()
	for pid in _mp_peer_order:
		var sh: int = int(_peer_shields.get(pid, mx))
		var out: bool = bool(_peer_eliminated.get(pid, false))
		var tag: String = "你" if pid == my_id else str(pid)
		if out:
			segs.append("%s 出局" % tag)
		else:
			segs.append("%s %d/%d" % [tag, sh, mx])
	EventBus.multiplayer_peers_hud.emit(" | ".join(segs))


func _emit_shield_changed() -> void:
	if balance == null:
		return
	if multiplayer.has_multiplayer_peer():
		var my_id := multiplayer.get_unique_id()
		var cur: int = int(_peer_shields.get(my_id, balance.shield_max))
		var display_max: int = maxi(balance.shield_max, cur)
		EventBus.shield_changed.emit(cur, display_max)
	else:
		var display_max_solo: int = maxi(balance.shield_max, shield)
		EventBus.shield_changed.emit(shield, display_max_solo)
