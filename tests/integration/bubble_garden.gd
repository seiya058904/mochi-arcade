extends SceneTree
const RULES := preload("res://scripts/games/bubble_rules.gd")
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
	save.folder = "user://qa-bubble-" + str(int(Time.get_unix_time_from_system() * 1000000)) + "-" + str(OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(save.folder)
	save.data = save.defaults()
	save.data.settings.music = false
	root.get_node("Sound").apply_settings()
	for row in range(RULES.ROWS):
		for col in range(RULES.COLS):
			var cell := Vector2i(col, row)
			for neighbor in RULES.neighbors(cell):
				check(cell in RULES.neighbors(neighbor), "Hex reciprocal adjacency " + str(cell))
	var grid := {Vector2i(3, 0): 0, Vector2i(4, 0): 0, Vector2i(3, 1): 0, Vector2i(3, 2): 1, Vector2i(4, 3): 2}
	check(RULES.cluster(grid, Vector2i(3, 0)).size() == 3, "Three-color cluster across staggered rows")
	check(RULES.floating(grid).size() == 1, "Detached branch is identified")
	grid.erase(Vector2i(3, 1))
	check(RULES.floating(grid).size() == 2, "Roof bridge removal drops disconnected colors")
	check(RULES.colors({Vector2i(0, 0): 4, Vector2i(1, 0): 4, Vector2i(2, 0): 1}) == [1, 4], "Shot pool contains only active colors")
	check(is_equal_approx(RULES.segment_circle(Vector2(-100, 0), Vector2(100, 0), Vector2.ZERO, 20), 0.4), "Continuous projectile cannot tunnel through bubble")
	check(RULES.segment_circle(Vector2(-100, 80), Vector2(100, 80), Vector2.ZERO, 20) == INF, "Swept miss is not a false collision")
	var app = load("res://scenes/app/main.tscn").instantiate()
	root.add_child(app)
	app.open_game(1, true)
	app.resume()
	var game = app.game
	check(game.grid.size() == 27 and RULES.floating(game.grid).is_empty(), "Opening garden is roof-connected")
	for row in range(RULES.ROWS):
		for col in range(RULES.COLS):
			var cell := Vector2i(col, row)
			for neighbor in RULES.neighbors(cell):
				check(absf(game.cell_position(cell).distance_to(game.cell_position(neighbor)) - 60) < 0.001, "Hex graphics agree with rules " + str(cell))
	# Send a real projectile through a fixture to verify snap + three-match.
	game.grid = {Vector2i(4, 0): 0, Vector2i(4, 1): 0}
	game.shot_color = 0
	game.next_color = 0
	game.aim = Vector2(0, -1)
	game.release(game.origin)
	await create_timer(0.8).timeout
	check(game.popped_count == 3 and game.score >= 130, "Direct shot attaches, matches three and awards clear bonus")
	check(game.stage == 2, "Cleared garden advances stage")
	await create_timer(0.75).timeout
	check(not game.grid.is_empty() and not game.flying, "Next stage is playable")
	game.grid = {Vector2i(0, 0): 1, Vector2i(1, 0): 1, Vector2i(2, 0): 1}
	game.shot_color = 1
	game.aim = Vector2(-0.88, -0.48).normalized()
	game.release(game.origin)
	# This shallow shot needs about 1.6 s to reach the roof, including rebounds.
	for _frame in range(240):
		if not game.flying:
			break
		await physics_frame
	check(game.bounce_count > 0 and not game.flying, "Wall-bounced projectile attaches without tunneling")
	if game.reload_time > 0:
		await create_timer(0.8).timeout
	game.refresh_colors(true)
	check(game.shot_color in RULES.colors(game.grid) and game.next_color in RULES.colors(game.grid), "Shots cannot retain vanished colors")
	var saved_grid: Dictionary = game.grid.duplicate()
	var saved_seed: int = game.run_seed
	game.checkpoint()
	app.leave_game()
	app.open_game(1)
	app.resume()
	check(app.game.grid == saved_grid, "Bubble grid survives scene reload")
	check(app.game.run_seed == saved_seed, "Recorded run seed survives scene reload")
	game = app.game
	game.set_physics_process(false)
	for hz in [30, 60, 120]:
		for angle in [-PI + 0.2, -2.3, -PI / 2, -0.8, -0.2]:
			game.stopped = false
			game.flying = false
			app.dismiss_overlay()
			game.grid.clear()
			for x in range(RULES.COLS):
				game.grid[Vector2i(x, 0)] = 0
			game.shot_color = 4
			game.aim = Vector2.from_angle(angle)
			var predicted: Vector2i = game.trace(game.aim).cell
			game.release(game.origin)
			for _frame in range(hz * 5):
				if not game.flying:
					break
				game._physics_process(1.0 / hz)
			check(not game.flying and game.grid.get(predicted, -1) == 4, "Aim and real swept shot agree at " + str(hz) + " Hz / " + str(angle))
	game.grid = {Vector2i(4, 11): 1}
	game.shot_color = 2
	game.attach(Vector2i(4, 12))
	check(game.stopped and is_instance_valid(app.overlay), "Bubble reaches loss boundary and results")
	app.restart()
	check(not app.game.stopped and app.game.grid.size() == 27, "Bubble retry restores playable first garden")
	app.show_home()
	await process_frame
	check(app.get_child_count() == 1, "Bubble unload removes entire state machine")
	var report := {"suite": "bubble-garden geometry and runtime", "checks": checks, "failures": failures, "status": "PASS" if failures.is_empty() else "FAIL"}
	print(JSON.stringify(report))
	var output := FileAccess.open("res://docs/evidence/bubble-garden-tests.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "  ") + "\n")
	app.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
