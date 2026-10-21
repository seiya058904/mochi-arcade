extends SceneTree
var checks := 0
var failures: Array[String] = []
var app: Control

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		if failures.size() <= 15:
			push_error(message)

func fresh() -> Node:
	app.open_game(7, true, 2047)
	app.resume()
	app.game.set_physics_process(false)
	return app.game

func touch(game: Node, index: int, point: Vector2, pressed: bool, canceled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = game.to_global(point)
	event.pressed = pressed
	event.canceled = canceled
	if pressed:
		app._unhandled_input(event)
	else:
		app._input(event)

func run() -> void:
	root.size = Vector2i(450, 800)
	var save = root.get_node("Save")
	save.folder = "user://qa-jelly-" + str(Time.get_ticks_msec())
	DirAccess.make_dir_recursive_absolute(save.folder)
	save.data = save.defaults()
	save.data.settings.music = false
	save.data.settings.sfx = false
	root.get_node("Sound").apply_settings()
	app = load("res://scenes/app/main.tscn").instantiate()
	root.add_child(app)
	var game := fresh()
	check(game.sprites.size() == 12 and game.fruit.size() == 12 and game.halves.size() == 32, "Four whole/left/right art sets and fixed fruit/half pools load")
	check(app.game_clip.clip_contents and game.get_parent() == app.game_clip, "Fruit and fragments are clipped inside the gameplay area")
	var id: int = game.spawn_one(0, Vector2(300, 350), Vector2.ZERO)
	game.press(Vector2(20, 350))
	game.drag(Vector2(620, 350))
	check(game.sliced == 1 and game.score == 10 and not game.fruit[id].active and game.active_count(game.halves) == 2, "One 600px sample gap slices once and creates two actual halves")
	game.drag(Vector2(20, 350))
	game.slice_one(id, Vector2.RIGHT)
	check(game.sliced == 1 and game.score == 10, "Overlapping/re-entrant paths cannot collect an already claimed fruit")
	game.release(Vector2(620, 350))
	for i in range(3):
		game.spawn_one(i, Vector2(160 + 150 * i, 350), Vector2.ZERO)
	game.press(Vector2(0, 350))
	game.release(Vector2(640, 350))
	check(game.sliced == 4 and game.score == 70 and game.combo == 4, "A release segment cuts three fruit in path order with 15/20/25 combo points")
	game.spawn_time = 100
	game._physics_process(0.7)
	game.spawn_one(3, Vector2(300, 350), Vector2.ZERO)
	game.press(Vector2(0, 350))
	game.drag(Vector2(640, 350))
	check(game.combo == 1 and game.score == 80, "Combo expires after 0.65 seconds and returns to ten points")
	game = fresh()
	for i in range(6):
		game.spawn_one(i % 4, Vector2(90 + 90 * i, 350), Vector2.ZERO)
	game.press(Vector2(0, 350))
	game.drag(Vector2(640, 350))
	check(game.combo == 5 and game.sliced == 6 and game.score == 130, "Long combo caps at x5 and thirty points per additional fruit")
	game.drag(Vector2(NAN, 350))
	check(game.score == 130 and game.last_point.is_finite(), "Invalid coordinates cannot poison the blade or score")
	game = fresh()
	game.spawn_one(0, Vector2(300, 350), Vector2.ZERO)
	game.press(Vector2(300, 350))
	game.drag(Vector2(300.5, 350))
	check(game.sliced == 0, "A stationary finger or sub-two-pixel jitter is not a slice")
	game.release(Vector2(300.5, 350))
	game.press(Vector2(600, 350))
	game.drag(Vector2(610, 350))
	check(game.sliced == 0, "A new gesture never bridges from the previous release")
	game.cancel_pointer()
	game.drag(Vector2.ZERO)
	check(game.sliced == 0 and not game.stroke and game.trail.is_empty(), "Canceled gesture clears trail and cannot slice from stale coordinates")
	touch(game, 0, Vector2(50, 350), true)
	touch(game, 1, Vector2(600, 350), true)
	touch(game, 1, Vector2(600, 350), false)
	check(game.stroke and app.active_pointer == 0 and game.sliced == 0, "Secondary finger cannot end or take over the owned stroke")
	touch(game, 0, Vector2(600, 350), false, true)
	check(not game.stroke and game.sliced == 0 and app.active_pointer == -2, "Canceled primary touch does not cut the release segment")
	game.press(Vector2(0, 350))
	game.set_suspended(true)
	var position: Vector2 = game.fruit[0].p
	game._physics_process(20)
	game.drag(Vector2(640, 350))
	check(game.fruit[0].p == position and game.sliced == 0 and not game.stroke, "Pause freezes fruit and cancels held blade without catch-up")
	game.set_suspended(false)
	game.set_physics_process(false)
	game.press(Vector2(0, 350))
	game.drag(Vector2(640, 350))
	check(game.sliced == 1, "A new post-resume gesture remains playable")
	game = fresh()
	game.spawn_time = 100
	game.spawn_one(2, Vector2(250, 400), Vector2(40, -200))
	game._physics_process(0.4)
	position = game.fruit[0].p
	game.checkpoint()
	var saved: Dictionary = save.session("jelly_slice")
	app.leave_game()
	app.open_game(7)
	app.resume()
	game = app.game
	game.set_physics_process(false)
	check(game.fruit[0].p.distance_to(position) < 0.001 and not game.stroke and game.combo == 0 and str(game.rng.state) == saved.rng, "Reload restores projectile position and RNG but never a held blade/combo")
	game.spawn_time = 100
	game._physics_process(0.2)
	var expected := Vector2(250, 400) + Vector2(40, -200) * 0.6 + Vector2(0, game.GRAVITY * 0.6 * 0.6 / 2)
	check(game.fruit[0].p.distance_to(expected) < 0.01, "Restored projectile preserves its analytic trajectory")
	var endpoints: Array[Vector2] = []
	for fps in [30, 60, 120]:
		game = fresh()
		game.spawn_time = 100
		game.spawn_one(1, Vector2(300, 500), Vector2(30, -200))
		for frame in range(fps / 2):
			game._physics_process(1.0 / fps)
		endpoints.append(game.fruit[0].p)
	check(endpoints[0].distance_to(endpoints[1]) < 0.001 and endpoints[0].distance_to(endpoints[2]) < 0.001, "Analytic fruit flight agrees at 30/60/120 Hz")
	game = fresh()
	game.spawn_time = 100
	game.spawn_one(0, Vector2(100, game.area.y + 100), Vector2.DOWN * 500)
	game._physics_process(0.1)
	check(game.missed == 1 and game.score == 0 and not game.stopped and game.active_count(game.fruit) == 0, "Missing fruit recycles it without penalty or a forced Zen ending")
	game = fresh()
	var random := RandomNumberGenerator.new()
	random.seed = 882
	await process_frame
	var node_count := get_node_count()
	var timings: Array[int] = []
	var slow_samples: Array = []
	# 60-second synthetic saturation fixture is distinct from ordinary input replay.
	for frame in range(3600):
		while game.active_count(game.fruit) < 12:
			game.spawn_one(frame % 4, Vector2(random.randf_range(60, game.area.x - 60), 250 + (frame % 6) * 70), Vector2(20, -40))
		var start := Time.get_ticks_usec()
		var is_checkpoint: bool = game.save_time + 1.0 / 60 >= 2
		game.press(Vector2(0, 250 + (frame % 6) * 70))
		for sample in range(30):
			game.drag(Vector2(game.area.x * ((sample % 2) as float), 250 + (frame % 6) * 70))
		var after_input := Time.get_ticks_usec()
		game._physics_process(1.0 / 60)
		var after_physics := Time.get_ticks_usec()
		timings.append(after_physics - start)
		if after_physics - start > 16667:
			slow_samples.append({"frame": frame, "checkpoint": is_checkpoint, "input_us": after_input - start, "physics_us": after_physics - after_input})
		check(game.fruit.size() == 12 and game.halves.size() == 32 and game.trail.size() <= 24 and game.particles.size() <= 64, "Saturated fruit/halves/trail/particle pools stay bounded " + str(frame))
		check(not game.stopped and game.sliced + game.missed + game.active_count(game.fruit) == game.launched, "Every launched fruit has exactly one lifecycle outcome " + str(frame))
		if frame % 30 == 0:
			await process_frame
	timings.sort()
	check(get_node_count() == node_count and game.max_fruit == 12 and game.max_halves == 32, "High-rate swipe saturation creates no nodes and reaches exact pool caps")
	var stress := {"simulated_seconds": 60, "swipe_events": 108000, "max_fruit": game.max_fruit, "max_halves": game.max_halves, "physics_and_swipes_us_p50": timings[1800], "physics_and_swipes_us_p95": timings[3420], "physics_and_swipes_us_max": timings.back(), "slow_samples": slow_samples, "prior_max_us": [321749, 208727], "scope": "Windows headless synthetic load; not Android rendering FPS"}
	game.action("finish")
	check(game.stopped and is_instance_valid(app.overlay) and save.session("jelly_slice").is_empty(), "Explicit Finish break shows results and closes the saved round")
	app.restart()
	game = app.game
	game.set_physics_process(false)
	check(game.score == 0 and not game.stopped and game.sliced == 0, "Retry immediately starts a new Zen round")
	game.reduced_motion = true
	game.spawn_one(0, Vector2(300, 350), Vector2.ZERO)
	game.press(Vector2(0, 350))
	game.drag(Vector2(640, 350))
	check(game.sliced == 1 and game.trail.is_empty() and game.particles.is_empty() and game.active_count(game.halves) == 2, "Reduced motion preserves slices/halves while suppressing trails and particles")
	app.leave_game()
	await process_frame
	check(app.get_child_count() == 1, "Scene exit frees fruit, halves, clipping container and overlays")
	var report := {"status": "PASS" if failures.is_empty() else "FAIL", "checks": checks, "failures": failures, "seed": 2047, "stress": stress}
	var output := FileAccess.open("res://docs/evidence/jelly-slice-tests.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "  ") + "\n")
	print(JSON.stringify(report))
	await root.get_node("Sound").shutdown()
	app.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
