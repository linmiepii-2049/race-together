extends GutTest

const _PO := preload("res://scripts/game/mp_peer_order.gd")


func test_sorted_peer_ids_orders_and_dedupes() -> void:
	var peers := PackedInt32Array([3, 1])
	var out: Array[int] = _PO.sorted_peer_ids(2, peers)
	assert_eq(out.size(), 3)
	assert_eq(out[0], 1)
	assert_eq(out[1], 2)
	assert_eq(out[2], 3)


func test_sorted_single_peer() -> void:
	var empty := PackedInt32Array()
	var out: Array[int] = _PO.sorted_peer_ids(7, empty)
	assert_eq(out.size(), 1)
	assert_eq(out[0], 7)
