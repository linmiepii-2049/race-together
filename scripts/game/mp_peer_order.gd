extends RefCounted


static func sorted_peer_ids(unique_id: int, remote_peers: PackedInt32Array) -> Array[int]:
	var ids: Array[int] = [unique_id]
	for p in remote_peers:
		if not ids.has(p):
			ids.append(p)
	ids.sort()
	return ids
