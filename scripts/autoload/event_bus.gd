extends Node

signal task_assigned(task_id: String, task_data: Dictionary)
signal task_started(task_id: String)
signal task_completed(task_id: String, result: Dictionary)
signal task_failed(task_id: String, reason: String)
signal task_cancelled(task_id: String)

signal worker_available(worker_id: String)
signal worker_busy(worker_id: String, task_id: String)

signal schedule_updated(schedule: Array)
signal priority_changed(task_id: String, new_priority: int)

signal run_score_changed(score: int)
signal shield_changed(current: int, maximum: int)
signal run_player_damaged(remaining_shield: int, maximum_shield: int)
signal run_peer_player_damaged(peer_id: int, remaining_shield: int, maximum_shield: int)
## 連線對局全員護盾摘要（空字串表示隱藏／重置）。
signal multiplayer_peers_hud(line: String)
signal pickup_invulnerability_started(duration_sec: float)
signal pickup_invulnerability_for_peer(peer_id: int, duration_sec: float)
signal run_game_over(reason: String)
