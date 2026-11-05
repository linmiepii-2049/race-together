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
signal run_speed_changed(speed: float)
signal run_distance_changed(distance: float)
signal near_miss(points: int, combo: int)
signal combo_changed(combo: int)
signal nitro_changed(charge: float, boosting: bool)
signal coins_changed(run_coins: int)
signal chapter_progress(distance: float, goal: float, title: String)
signal tutorial_hint(text: String)
signal run_finished(victory: bool, reason: String)
signal story_run_started
signal story_chapter_advanced
signal story_lines_requested(lines: Array, kind: String)
signal wave_set_requested(set_name: String)
signal shield_changed(current: int, maximum: int)
signal run_player_damaged(remaining_shield: int, maximum_shield: int)
signal run_peer_player_damaged(peer_id: int, remaining_shield: int, maximum_shield: int)
## 連線對局全員護盾摘要（空字串表示隱藏／重置）。
signal multiplayer_peers_hud(line: String)
signal pickup_invulnerability_started(duration_sec: float)
signal pickup_invulnerability_for_peer(peer_id: int, duration_sec: float)
signal run_game_over(reason: String)
