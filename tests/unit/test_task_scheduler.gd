extends GutTest


var scheduler: Node


func before_each() -> void:
	scheduler = preload("res://scripts/autoload/task_scheduler.gd").new()
	add_child(scheduler)


func after_each() -> void:
	scheduler.queue_free()


func test_create_task_returns_unique_id() -> void:
	var id1 := scheduler.create_task("Task 1")
	var id2 := scheduler.create_task("Task 2")
	
	assert_ne(id1, id2, "Task IDs should be unique")
	assert_true(id1.begins_with("task_"), "Task ID should have prefix")


func test_create_task_adds_to_pending() -> void:
	scheduler.create_task("Test task")
	
	var pending := scheduler.get_pending_tasks()
	assert_eq(pending.size(), 1)
	assert_eq(pending[0]["description"], "Test task")
	assert_eq(pending[0]["status"], scheduler.TaskStatus.PENDING)


func test_start_task_moves_to_active() -> void:
	var task_id := scheduler.create_task("Test task")
	
	var success := scheduler.start_task(task_id)
	
	assert_true(success)
	assert_eq(scheduler.get_pending_tasks().size(), 0)
	assert_eq(scheduler.get_active_tasks().size(), 1)


func test_complete_task_removes_from_active() -> void:
	var task_id := scheduler.create_task("Test task")
	scheduler.start_task(task_id)
	
	scheduler.complete_task(task_id, {"result": "done"})
	
	assert_eq(scheduler.get_active_tasks().size(), 0)


func test_priority_sorting() -> void:
	scheduler.create_task("Low", scheduler.TaskPriority.LOW)
	scheduler.create_task("Urgent", scheduler.TaskPriority.URGENT)
	scheduler.create_task("Normal", scheduler.TaskPriority.NORMAL)
	
	var next := scheduler.get_next_task()
	
	assert_eq(next["description"], "Urgent", "Highest priority task should be first")


func test_cancel_pending_task() -> void:
	var task_id := scheduler.create_task("To cancel")
	
	scheduler.cancel_task(task_id)
	
	assert_eq(scheduler.get_pending_tasks().size(), 0)
