extends SceneTree
var app: Control
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in range(count):
		await process_frame

func mouse(point: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = root.get_final_transform() * point
	Input.parse_input_event(event)

func click(point: Vector2) -> void:
	mouse(point, true)
	mouse(point, false)

func capture(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/evidence/desktop-vertical-" + name + ".png")

func place_at(target: float) -> void:
	for i in range(900):
		if absf(app.game.moving_x - target) <= 4:
			click(app.play_rect.get_center())
			await frames(2)
			return
		await process_frame
	failures.append("A visible Cake target could not be reached in 900 frames")

func retry_button() -> void:
	for box in app.overlay.get_children():
		for child in box.get_children():
			if child is Button and child.text == "One more go":
				click(child.get_global_rect().get_center())
				await frames(2)
				return
	failures.append("No actual retry button")

func run() -> void:
	root.size = Vector2i(450, 800)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var save := root.get_node("Save")
	save.folder = "user://qa-vertical-play-" + str(int(Time.get_unix_time_from_system() * 1000000)) + "-" + str(OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(save.folder)
	save.data = save.defaults()
	save.data.settings.music = false
	root.get_node("Sound").apply_settings()
	app = load("res://scenes/app/main.tscn").instantiate()
	root.add_child(app)
	app.open_game(2, true, 812)
	app.resume()
	var cake = app.game
	for layer in range(60):
		await place_at(cake.layers[-1].x)
		if cake.stopped or cake.tier != layer + 1 or cake.layers.size() > 24:
			failures.append("Cake ordinary placement or retained-layer bound failed")
			break
	var cake_result := {"perfect_layers": cake.tier, "score_after_perfects": cake.score, "retained_layers": cake.layers.size()}
	await capture("cake-tall")
	for cut in range(3):
		var top: Dictionary = cake.layers[-1]
		var target: float = top.x + top.w * 0.4
		if target > cake.area.x - top.w - 12:
			target = top.x - top.w * 0.4
		await place_at(target)
	await capture("cake-trimmed")
	await place_at(12)
	cake_result["natural_miss"] = cake.stopped and is_instance_valid(app.overlay)
	cake_result["final_score"] = cake.score
	await capture("cake-results")
	if cake_result.natural_miss:
		await retry_button()
	cake_result["retry_playable"] = app.game != cake and app.game.score == 0 and not app.game.stopped
	app.leave_game()
	app.open_game(6, true, 2048)
	app.resume()
	var bloom = app.game
	var actions: Array[int] = []
	var input_rng := RandomNumberGenerator.new()
	input_rng.seed = 44
	for move in range(1500):
		if bloom.stopped:
			break
		var valid: Array[int] = []
		for direction in range(4):
			if bloom.RULES.move(bloom.board, direction).changed:
				valid.append(direction)
		if valid.is_empty():
			failures.append("No valid 2048 move without terminal state")
			break
		var direction: int = valid[input_rng.randi_range(0, valid.size() - 1)]
		var center: Vector2 = app.play_rect.get_center()
		var offset: Vector2 = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN][direction] * 180
		mouse(center - offset * 0.5, true)
		mouse(center + offset * 0.5, false)
		actions.append(direction)
		# The production end-of-round waits 0.22 s so its final move remains visible.
		await frames(16)
		if actions.size() == 64:
			await capture("bloom-midgame")
	var bloom_result := {"seed": 2048, "input_seed": 44, "moves": actions.size(), "directions": actions, "score": bloom.score, "highest_tile": bloom.board.max(), "natural_game_over": bloom.stopped and not bloom.RULES.can_move(bloom.board)}
	await capture("bloom-results")
	if bloom_result.natural_game_over:
		await retry_button()
	bloom_result["retry_playable"] = app.game != bloom and app.game.score == 0 and not app.game.stopped
	if not cake_result.natural_miss or not cake_result.retry_playable or not bloom_result.natural_game_over or not bloom_result.retry_playable:
		failures.append("Ordinary-action end/retry loop failed")
	var report := {"status": "PASS" if failures.is_empty() else "FAIL", "cake": cake_result, "bloom": bloom_result, "failures": failures, "scope": "Actual Godot mouse events; wait for moving cake positions, then ordinary placement. 2048 uses legal swipes. No injected board, score, positions or terminal flags; not Android proof."}
	var mode := "headless" if DisplayServer.get_name() == "headless" else "rendered"
	FileAccess.open("res://docs/evidence/vertical-playthrough-" + mode + ".json", FileAccess.WRITE).store_string(JSON.stringify(report, "  ") + "\n")
	print(JSON.stringify(report))
	await root.get_node("Sound").shutdown()
	app.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
