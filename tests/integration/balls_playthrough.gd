extends SceneTree
var app: Control

func _initialize() -> void:
	call_deferred("run")

func pointer(point: Vector2, down: bool = false) -> void:
	var event: InputEvent
	if down:
		event = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = true
	else:
		event = InputEventMouseMotion.new()
		event.button_mask = MOUSE_BUTTON_MASK_LEFT
	event.position = root.get_final_transform() * point
	Input.parse_input_event(event)

func capture(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/evidence/desktop-balls-" + name + ".png")

func landing_x(game: Node, ball: Dictionary) -> float:
	var t := maxf(0, (game.paddle_y() - game.RADIUS - ball.p.y) / ball.v.y)
	var left: float = 18 + game.RADIUS
	var width: float = game.area.x - 2 * left
	var unfolded: float = ball.p.x + ball.v.x * t - left
	return left + width - absf(fposmod(unfolded, 2 * width) - width)

func run() -> void:
	root.size = Vector2i(450, 800)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var save = root.get_node("Save")
	save.folder = "user://qa-balls-play-" + str(Time.get_ticks_msec())
	DirAccess.make_dir_recursive_absolute(save.folder)
	save.data = save.defaults()
	save.data.settings.music = false
	root.get_node("Sound").apply_settings()
	app = load("res://scenes/app/main.tscn").instantiate()
	root.add_child(app)
	app.open_game(3, true, 881)
	app.resume()
	var game = app.game
	await capture("opening")
	pointer(game.to_global(Vector2(game.paddle_x, game.paddle_y())), true)
	var trace: Array = []
	var crowd := false
	var full_pool := false
	var next_wave := false
	var frames := 0
	for frame in range(36000):
		frames = frame
		if game.stopped:
			break
		var closest := INF
		var intercept: float = game.area.x / 2
		for ball in game.pool:
			if ball.active and ball.v.y > 0 and ball.p.y < game.paddle_y():
				var t: float = (game.paddle_y() - ball.p.y) / ball.v.y
				if t < closest:
					closest = t
					intercept = landing_x(game, ball)
		var target: float
		if game.wave <= 3:
			# Vary contact offset so the visible paddle steers into different columns.
			target = intercept - sin(game.catches * 1.731) * 53
		else:
			# Deliberately miss via ordinary input; never delete balls or force loss.
			target = 0 if intercept > game.area.x / 2 else game.area.x
		pointer(game.to_global(Vector2(target, game.paddle_y())))
		if frame % 60 == 0:
			trace.append({"frame": frame, "x": snappedf(target, 0.01), "wave": game.wave, "balls": game.active_count(), "bricks": game.bricks_left()})
		await process_frame
		if game.active_count() >= 6 and not crowd:
			crowd = true
			await capture("multiball")
		if game.active_count() == 64 and not full_pool:
			full_pool = true
			await capture("full-pool")
		if game.wave >= 2 and not next_wave:
			next_wave = true
			await capture("next-wave")
	await capture("result")
	var report := {"seed": 881, "frames": frames, "waves_cleared": game.wave - 1, "score": game.score,
		"max_balls": game.max_active, "catches": game.catches, "brick_hits": game.brick_hits, "bumper_hits": game.bumper_hits,
		"gate_passes": game.gate_passes.duplicate(), "recycled": game.recycled, "collision_limit_hits": game.collision_limit_hits,
		"natural_loss": game.stopped and game.active_count() == 0, "input_trace": trace,
		"evidence": "Actual Godot mouse press/drag events drive only the paddle. Predictive catches clear waves; deliberate misses cause natural loss. No score/ball/brick injection."}
	app.restart()
	report["retry_playable"] = app.game.wave == 1 and app.game.active_count() == 1 and app.game.score == 0
	report["status"] = "PASS" if report.waves_cleared >= 3 and report.natural_loss and report.retry_playable and report.gate_passes[0] > 0 and report.gate_passes[1] > 0 and report.collision_limit_hits == 0 else "FAIL"
	var backend := "headless" if DisplayServer.get_name() == "headless" else "rendered"
	var output := FileAccess.open("res://docs/evidence/balls-playthrough-" + backend + ".json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "  ") + "\n")
	report.erase("input_trace")
	print(JSON.stringify(report))
	await root.get_node("Sound").shutdown()
	app.queue_free()
	await process_frame
	quit(0 if report.status == "PASS" else 1)
