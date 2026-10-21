extends SceneTree
## Only ordinary aim/release and the player's free hint, from a fresh seeded garden.
var app: Control

func _initialize() -> void:
	call_deferred("run")

func capture(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/evidence/desktop-bubble-" + name + ".png")

func settle(game: Node) -> bool:
	for _frame in range(300):
		if not game.flying and game.reload_time <= 0:
			return true
		await physics_frame
	return false

func run() -> void:
	root.size = Vector2i(450, 800)
	var save = root.get_node("Save")
	save.folder = "user://qa-bubble-play-" + str(Time.get_ticks_msec())
	DirAccess.make_dir_recursive_absolute(save.folder)
	save.data = save.defaults()
	save.data.settings.music = false
	root.get_node("Sound").apply_settings()
	app = load("res://scenes/app/main.tscn").instantiate()
	root.add_child(app)
	app.open_game(1, true, 5402)
	app.resume()
	var game = app.game
	await capture("opening")
	var trail: Array = []
	var timed_out := false
	while game.stage < 6 and not game.stopped and game.shots < 120:
		game.action("hint")
		trail.append({"stage": game.stage, "color": game.shot_color, "angle": game.aim.angle()})
		game.press(game.origin)
		game.release(game.origin)
		if not await settle(game):
			timed_out = true
			break
		if game.shots == 7:
			await capture("play")
	var reached: int = game.stage
	var helpful_shots: int = game.shots
	# Poor but legal shots are allowed to build a natural losing board.
	var input_rng := RandomNumberGenerator.new()
	input_rng.seed = 3029
	while not game.stopped and game.shots < 300 and not timed_out:
		var point: Vector2 = game.origin + Vector2.from_angle(input_rng.randf_range(-PI + 0.25, -0.25)) * 700
		game.press(point)
		trail.append({"stage": game.stage, "color": game.shot_color, "angle": game.aim.angle()})
		game.release(point)
		if not await settle(game):
			timed_out = true
	await capture("result")
	var report := {"seed": 5402, "random_input_seed": 3029, "stages_cleared_with_hints": reached - 1,
		"hint_shots": helpful_shots, "shots": game.shots, "popped": game.popped_count,
		"fallen": game.dropped_count, "wall_bounces": game.bounce_count,
		"natural_failure": game.stopped, "timed_out": timed_out, "score": game.score,
		"input_trace": trail, "evidence": "Fresh garden, ordinary aim/release + built-in hint. No grid, score or terminal-state injection."}
	app.restart()
	report["retry_playable"] = not app.game.stopped and app.game.grid.size() == 27
	report["status"] = "PASS" if reached >= 6 and report.natural_failure and not timed_out and report.retry_playable else "FAIL"
	var backend := "headless" if DisplayServer.get_name() == "headless" else "rendered"
	var output := FileAccess.open("res://docs/evidence/bubble-playthrough-" + backend + ".json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "  ") + "\n")
	report.erase("input_trace")
	print(JSON.stringify(report))
	app.queue_free()
	await process_frame
	quit(0 if report.status == "PASS" else 1)
