extends SceneTree

const RULES := preload("res://scripts/games/fruit_rules.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func run() -> void:
	var save = root.get_node("Save")
	save.folder = "user://qa-fruit-" + str(int(Time.get_unix_time_from_system() * 1000000)) + "-" + str(OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(save.folder)
	save.data = save.defaults()
	save.data.settings.music = false
	root.get_node("Sound").apply_settings()
	var claimed: Dictionary = {}
	check(RULES.claim(1, 2, 0, 0, claimed), "First collision claims both fruit")
	check(not RULES.claim(2, 1, 0, 0, claimed), "Reverse collision cannot duplicate merge")
	check(not RULES.claim(1, 3, 0, 0, claimed), "Triple contact cannot consume same fruit twice")
	check(not RULES.claim(4, 5, 0, 1, claimed), "Different levels cannot merge")
	check(not RULES.claim(6, 6, 0, 0, claimed), "Fruit cannot merge with itself")
	check(not RULES.overflow(160, 0, 1.0, 180), "Newly dropped fruit has overflow grace")
	check(not RULES.overflow(160, 200, 3.0, 180), "Falling fruit is not resting overflow")
	check(RULES.overflow(160, 0, 3.0, 180), "Settled old fruit beyond line triggers overflow")
	var app = load("res://scenes/app/main.tscn").instantiate()
	root.add_child(app)
	app.open_game(0, true)
	app.resume()
	await process_frame
	var game = app.game
	game.rng.seed = 817
	game.spawn_fruit(0, Vector2(290, game.floor_y - 30))
	game.spawn_fruit(0, Vector2(330, game.floor_y - 30))
	await create_timer(0.8).timeout
	check(game.merge_count == 1 and game.score == 20, "Actual RigidBody contact produces one merge and score")
	check(game.fruits.size() == 1 and game.fruits[0].level == 1, "Two physics bodies become exactly one next-level fruit")
	var before: Vector2 = game.fruits[0].position
	app.show_pause()
	await create_timer(0.15).timeout
	check(game.fruits[0].position.distance_to(before) < 0.01, "Fruit physics freezes during pause")
	app.resume()
	game.checkpoint()
	app.leave_game()
	app.open_game(0)
	app.resume()
	game = app.game
	check(game.score == 20 and game.fruits.size() == 1 and game.fruits[0].level == 1, "Fruit run survives scene reload")
	# Exercise real contact chains at every stage, including max-tier clearance.
	for level in range(1, 8):
		app.open_game(0, true)
		app.resume()
		game = app.game
		var radius: float = RULES.RADII[level]
		game.spawn_fruit(level, Vector2(324 - radius + 2, game.floor_y - radius - 3))
		game.spawn_fruit(level, Vector2(324 + radius - 2, game.floor_y - radius - 3))
		await create_timer(0.25).timeout
		check(game.merge_count == 1 and game.score == RULES.merge_score(level), "Actual contact merge stage " + str(level))
		check(game.fruits.size() == (0 if level == 7 else 1), "Bounded max-stage replacement " + str(level))
	app.open_game(0, true)
	app.resume()
	game = app.game
	# Explicit boundary fixture; separate from natural player-reached failure.
	var top = game.spawn_fruit(2, Vector2(324, 170))
	top.freeze = true
	top.age = 3
	await create_timer(1.5).timeout
	check(game.stopped and is_instance_valid(app.overlay), "Overflow grace expires into recoverable result")
	app.restart()
	check(not app.game.stopped and app.game.fruits.is_empty(), "Fruit immediate restart clears all physics bodies")
	app.show_home()
	await process_frame
	check(app.get_child_count() == 1, "Fruit scene unload has no orphan physics subtree")
	var report := {"suite": "fruit-drop physics and rules", "checks": checks, "failures": failures, "status": "PASS" if failures.is_empty() else "FAIL", "seed": 817, "note": "Real Godot 2D contacts; forced overflow fixture is not natural-failure play evidence."}
	print(JSON.stringify(report))
	var output := FileAccess.open("res://docs/evidence/fruit-drop-tests.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "  ") + "\n")
	app.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
