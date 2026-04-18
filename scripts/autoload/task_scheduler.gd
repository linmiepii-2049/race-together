extends Node

enum TaskPriority { LOW, NORMAL, HIGH, URGENT }
enum TaskStatus { PENDING, IN_PROGRESS, COMPLETED, FAILED, CANCELLED }

var _task_queue: Array[Dictionary] = []
var _active_tasks: Dictionary = {}  # task_id -> task_data
var _next_task_id: int = 0


func create_task(description: String, priority: TaskPriority = TaskPriority.NORMAL, metadata: Dictionary = {}) -> String:
	var task_id := "task_%d" % _next_task_id
	_next_task_id += 1
	
	var task := {
		"id": task_id,
		"description": description,
		"priority": priority,
		"status": TaskStatus.PENDING,
		"metadata": metadata,
		"created_at": Time.get_ticks_msec(),
	}
	
	_task_queue.append(task)
	_sort_queue_by_priority()
	EventBus.schedule_updated.emit(get_pending_tasks())
	
	return task_id


func start_task(task_id: String) -> bool:
	var task := _find_task_in_queue(task_id)
	if task.is_empty():
		push_warning("[TaskScheduler] Task not found: %s" % task_id)
		return false
	
	_task_queue.erase(task)
	task["status"] = TaskStatus.IN_PROGRESS
	task["started_at"] = Time.get_ticks_msec()
	_active_tasks[task_id] = task
	
	EventBus.task_started.emit(task_id)
	return true


func complete_task(task_id: String, result: Dictionary = {}) -> void:
	if not _active_tasks.has(task_id):
		push_warning("[TaskScheduler] Active task not found: %s" % task_id)
		return
	
	var task: Dictionary = _active_tasks[task_id]
	task["status"] = TaskStatus.COMPLETED
	task["completed_at"] = Time.get_ticks_msec()
	task["result"] = result
	
	_active_tasks.erase(task_id)
	EventBus.task_completed.emit(task_id, result)


func fail_task(task_id: String, reason: String) -> void:
	if not _active_tasks.has(task_id):
		push_warning("[TaskScheduler] Active task not found: %s" % task_id)
		return
	
	var task: Dictionary = _active_tasks[task_id]
	task["status"] = TaskStatus.FAILED
	task["failed_at"] = Time.get_ticks_msec()
	task["failure_reason"] = reason
	
	_active_tasks.erase(task_id)
	EventBus.task_failed.emit(task_id, reason)


func cancel_task(task_id: String) -> void:
	var task := _find_task_in_queue(task_id)
	if not task.is_empty():
		_task_queue.erase(task)
		EventBus.task_cancelled.emit(task_id)
		return
	
	if _active_tasks.has(task_id):
		_active_tasks.erase(task_id)
		EventBus.task_cancelled.emit(task_id)


func get_next_task() -> Dictionary:
	if _task_queue.is_empty():
		return {}
	return _task_queue[0]


func get_pending_tasks() -> Array[Dictionary]:
	return _task_queue.duplicate()


func get_active_tasks() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for task in _active_tasks.values():
		result.append(task)
	return result


func set_priority(task_id: String, new_priority: TaskPriority) -> void:
	var task := _find_task_in_queue(task_id)
	if task.is_empty():
		return
	
	task["priority"] = new_priority
	_sort_queue_by_priority()
	EventBus.priority_changed.emit(task_id, new_priority)
	EventBus.schedule_updated.emit(get_pending_tasks())


func _find_task_in_queue(task_id: String) -> Dictionary:
	for task in _task_queue:
		if task["id"] == task_id:
			return task
	return {}


func _sort_queue_by_priority() -> void:
	_task_queue.sort_custom(func(a, b): return a["priority"] > b["priority"])
