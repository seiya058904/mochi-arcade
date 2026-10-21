extends SceneTree
var app: Control

func _initialize() -> void:
	call_deferred("run")

func mouse(point: Vector2, type: String) -> void:
	var event: InputEvent
	if type == "move":
		event = InputEventMouseMotion.new()
		event.button_mask = MOUSE_BUTTON_MASK_LEFT
	else:
		event = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = type == "down"
	event.position = root.get_final_transform() * point
	Input.parse_input_event(event)

func click(point: Vector2) -> void:
	mouse(point, "down")
	mouse(point, "up")

func capture(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/evidence/desktop-jelly-" + name + ".png")

func run() -> void:
	root.size = Vector2i(450, 800)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var save = root.get_node("Save")
	save.folder = "user://qa-jelly-play-" + str(Time.get_ticks_msec())
	DirAccess.make_dir_recursive_absolute(save.folder)
	save.data = save.defaults()
	save.data.settings.music = false
	root.get_node("Sound").apply_settings()
	app = load("res://scenes/app/main.tscn").instantiate()
	root.add_child(app)
	app.open_game(7, true, 2047)
	app.resume()
	var game = app.game
	var trace: Array = []
	var sliced_capture := false
	var combo_capture := false
	for frame in range(3600):
		if frame == 60:
			await capture("whole-fruit")
		# The first six seconds deliberately leave natural misses; Zen must continue.
		if frame >= 360 and frame % 9 == 0:
			var target := -1
			var oldest := 0.0
			for i in range(game.fruit.size()):
				var item: Dictionary = game.fruit[i]
				if item.active and item.p.y > 140 and item.p.y < game.area.y - 130 and item.age > oldest:
					target = i
					oldest = item.age
			if target >= 0:
				var y: float = game.fruit[target].p.y
				trace.append({"frame": frame, "y": snappedf(y, 0.01), "serial": game.fruit[target].serial})
				mouse(game.to_global(Vector2(12, y)), "down")
				mouse(game.to_global(Vector2(game.area.x - 12, y)), "move")
				mouse(game.to_global(Vector2(game.area.x - 12, y)), "up")
				if not sliced_capture and game.active_count(game.halves) >= 2:
					sliced_capture = true
					await capture("cut-halves")
				if not combo_capture and game.combo >= 4:
					combo_capture = true
					await capture("combo")
		await process_frame
	var report := {"seed": 2047, "simulated_seconds": 60, "sliced": game.sliced, "missed": game.missed, "launched": game.launched,
		"score": game.score, "still_playable_after_misses": not game.stopped, "max_fruit": game.max_fruit, "max_halves": game.max_halves,
		"input_trace": trace, "evidence": "Real scene spawning and Godot mouse down/move/up. First six seconds deliberately miss. Every cut is a full-width visible swipe; no injected fruit, score or terminal flags."}
	for child in app.ui.get_children():
		if child is Button and child.text == "Finish break":
			click(child.get_global_rect().get_center())
			break
	await process_frame
	await process_frame
	report["finish_results"] = game.stopped and is_instance_valid(app.overlay)
	await capture("results")
	if is_instance_valid(app.overlay):
		for box in app.overlay.get_children():
			for child in box.get_children():
				if child is Button and child.text == "One more go":
					click(child.get_global_rect().get_center())
					break
	await process_frame
	await process_frame
	report["retry_playable"] = app.game != game and app.game.sliced == 0 and app.game.score == 0 and not app.game.stopped
	report["status"] = "PASS" if report.sliced >= 100 and report.missed > 0 and report.still_playable_after_misses and report.finish_results and report.retry_playable else "FAIL"
	var backend := "headless" if DisplayServer.get_name() == "headless" else "rendered"
	var output := FileAccess.open("res://docs/evidence/jelly-playthrough-" + backend + ".json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "  ") + "\n")
	report.erase("input_trace")
	print(JSON.stringify(report))
	await root.get_node("Sound").shutdown()
	app.queue_free()
	await process_frame
	quit(0 if report.status == "PASS" else 1)
