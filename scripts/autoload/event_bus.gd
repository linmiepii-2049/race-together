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
