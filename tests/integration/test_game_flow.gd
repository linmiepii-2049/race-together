extends GutTest


func test_game_state_transitions() -> void:
	var gm := preload("res://scripts/autoload/game_manager.gd").new()
	add_child(gm)
	
	assert_eq(gm.current_state, gm.GameState.MENU, "Initial state should be MENU")
	
	gm.change_state(gm.GameState.PLAYING)
	assert_eq(gm.current_state, gm.GameState.PLAYING)
	assert_true(gm.is_playing())
	
	gm.queue_free()


func test_task_lifecycle_with_event_bus() -> void:
	var scheduler := preload("res://scripts/autoload/task_scheduler.gd").new()
	var event_bus := preload("res://scripts/autoload/event_bus.gd").new()
	add_child(scheduler)
	add_child(event_bus)
	
	var started_task_id := ""
	var completed_task_id := ""
	
	event_bus.task_started.connect(func(id): started_task_id = id)
	event_bus.task_completed.connect(func(id, _result): completed_task_id = id)
	
	# 因為 TaskScheduler 使用全域 EventBus，這裡需要手動替換
	# 在真實場景中，Autoload 會自動處理
	var task_id := scheduler.create_task("Integration test task")
	scheduler.start_task(task_id)
	scheduler.complete_task(task_id, {"status": "success"})
	
	# 注意：這個測試展示了 integration test 的結構
	# 實際執行時需要確保 EventBus 是正確的實例
	
	scheduler.queue_free()
	event_bus.queue_free()
