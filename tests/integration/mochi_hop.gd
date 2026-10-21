extends SceneTree
const RULES := preload("res://scripts/games/hop_rules.gd")
var GAME: Script
var checks := 0
var failures: Array[String] = []
var app: Control

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func advance(game: Node, seconds: float, hz: int = 60) -> void:
	var left := seconds
	while left > 0.00000001:
		var step := minf(left, 1.0 / hz)
		game._process(step)
		left -= step

func fresh(seed_value: int = 1729) -> Node:
	app.open_game(5, true, seed_value)
	app.resume()
	app.game.set_process(false)
	return app.game

func touch(index: int, pressed: bool, canceled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.pressed = pressed
	event.canceled = canceled
	event.position = app.play_rect.get_center()
	if pressed:
		app._unhandled_input(event)
	else:
		app._input(event)

func run() -> void:
	# Load after autoload initialization; the scene script uses Save and Sound.
	GAME = load("res://scripts/games/mochi_hop.gd")
	root.size = Vector2i(450, 800)
	var save = root.get_node("Save")
	save.folder = "user://qa-hop-" + str(int(Time.get_unix_time_from_system() * 1000000)) + "-" + str(OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(save.folder)
	save.data = save.defaults()
	save.data.settings.music = false
	root.get_node("Sound").apply_settings()
	app = load("res://scenes/app/main.tscn").instantiate()
	root.add_child(app)
	var endpoints: Array = []
	for hz in [30, 60, 120]:
		var game := fresh()
		var target: Vector2 = game.target.center
		game.press(Vector2.ZERO)
		advance(game, RULES.hold_for_distance(game.foot.distance_to(target)), hz)
		game.release(Vector2.ZERO)
		endpoints.append([game.jump_to.x, game.jump_to.y])
		check(game.jump_to.distance_to(target) < 0.001, "Center hold maps to exact foot at " + str(hz) + " Hz")
		game.press(Vector2.ZERO)
		game.release(Vector2.ZERO)
		check(game.jumps == 1, "Airborne repeat input cannot launch twice")
		advance(game, 0.12, hz)
		var elapsed: float = game.jump_elapsed
		game.set_suspended(true)
		advance(game, 3, hz)
		check(game.jump_elapsed == elapsed and game.state == GAME.State.AIRBORNE, "Pause freezes flight")
		game.set_suspended(false)
		game.set_process(false)
		advance(game, 1, hz)
		check(game.landed == 1 and game.score == 3 and game.last_result.perfect, "First center landing and three-point score")
		game.press(Vector2.ZERO)
		advance(game, RULES.hold_for_distance(game.foot.distance_to(game.target.center)), hz)
		game.release(Vector2.ZERO)
		advance(game, 1, hz)
		check(game.landed == 2 and game.combo == 2 and game.score == 7, "Second perfect adds four and advances camera")
		advance(game, 0.65, hz)
		check(game.camera.distance_to(game.camera_target) < 2, "Camera follows the new platform pair")
		game.press(Vector2.ZERO)
		var edge_distance: float = game.foot.distance_to(game.target.center) + game.target.radius + 3
		advance(game, RULES.hold_for_distance(edge_distance), hz)
		game.release(Vector2.ZERO)
		advance(game, 1.2, hz)
		check(game.landed == 3 and game.score == 8 and game.combo == 0, "Forgiving edge succeeds and resets perfect streak")
		check(game.foot.distance_to(game.current.center) <= game.current.radius - 3.99, "Edge landing snaps visibly inside top surface")
	check(endpoints[0] == endpoints[1] and endpoints[1] == endpoints[2], "30/60/120 Hz same hold yields identical endpoint")
	check(save.best("mochi_hop") >= 8, "Hop high score is persisted")
	for dimensions in [Vector2i(360, 640), Vector2i(360, 800), Vector2i(640, 800)]:
		root.size = dimensions
		await process_frame
		var resized_game := fresh()
		var platform_point: Vector2 = resized_game.screen_point(resized_game.target.center)
		check(Rect2(90, 100, resized_game.area.x - 180, resized_game.area.y - 250).has_point(platform_point), "Next platform stays visible at " + str(dimensions))
		resized_game.press(Vector2.ZERO)
		advance(resized_game, RULES.hold_for_distance(resized_game.foot.distance_to(resized_game.target.center)))
		resized_game.release(Vector2.ZERO)
		check(resized_game.jump_to.distance_to(Vector2(endpoints[0][0], endpoints[0][1])) < 0.001, "Viewport cannot alter hold distance")
	root.size = Vector2i(450, 800)
	await process_frame
	var game := fresh()
	game.press(Vector2.ZERO)
	advance(game, 4)
	check(game.state == GAME.State.CHARGING and game.jumps == 0 and game.held == 1.2, "Long hold caps, never auto-launches")
	game.release(Vector2.ZERO)
	check(is_equal_approx(game.jump_from.distance_to(game.jump_to), 350), "Long release distance is bounded")
	advance(game, 2)
	check(game.stopped and is_instance_valid(app.overlay), "Overshoot falls and shows immediate retry")
	game = fresh()
	game.press(Vector2.ZERO)
	game.release(Vector2.ZERO)
	advance(game, 2)
	check(game.stopped and game.score == 0, "Very short tap naturally misses")
	game = fresh()
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	mouse.position = app.play_rect.get_center()
	app._unhandled_input(mouse)
	advance(game, 0.2)
	mouse.button_index = MOUSE_BUTTON_RIGHT
	mouse.pressed = false
	app._input(mouse)
	check(game.state == GAME.State.CHARGING and app.active_pointer == -1, "Right button cannot terminate left-button hold")
	app.pause_game(true)
	app.resume()
	game.set_process(false)
	check(game.state == GAME.State.READY, "Mouse charge cancels on pause")
	touch(0, true)
	advance(game, 0.3)
	touch(1, true)
	touch(1, false)
	check(game.state == GAME.State.CHARGING and app.active_pointer == 0, "Second finger cannot release primary charge")
	touch(0, false, true)
	check(game.state == GAME.State.READY and game.jumps == 0 and app.active_pointer == -2, "System-canceled touch never launches")
	game = fresh()
	touch(0, true)
	advance(game, 0.4)
	app.show_pause()
	check(game.state == GAME.State.READY and game.held == 0 and app.active_pointer == -2, "Pause cancels held charge")
	app.resume()
	game.set_process(false)
	touch(0, false)
	check(game.jumps == 0, "Late release after pause cannot launch")
	game.press(Vector2.ZERO)
	advance(game, 0.6)
	game.release(Vector2.ZERO)
	advance(game, 0.1)
	var safe_foot: Vector2 = game.foot
	var safe_target: Dictionary = game.target.duplicate()
	game.checkpoint()
	app.leave_game()
	app.open_game(5)
	app.resume()
	game = app.game
	game.set_process(false)
	check(game.state == GAME.State.READY and game.foot == safe_foot and game.target == safe_target, "Process-style reload restores safe foot and same target")
	check(game.run_seed == 1729, "Replay seed restored")
	touch(0, true)
	advance(game, 0.25)
	app._notification(Control.NOTIFICATION_APPLICATION_PAUSED)
	await process_frame
	check(game.state == GAME.State.READY and game.suspended and is_instance_valid(app.overlay), "Background notification cancels charge and keeps recovery UI")
	app.restart()
	check(not app.game.stopped and app.game.score == 0, "Immediate restart is playable")
	app.show_home()
	await process_frame
	check(app.get_child_count() == 1, "Leaving Hop removes scene and overlays")
	var report := {"suite": "Mochi Hop runtime and input lifecycle", "checks": checks, "failures": failures,
		"fps": [30, 60, 120], "endpoints": endpoints, "seed": 1729,
		"evidence": "Real scene/state machine with simulated deltas and Godot touch-event handlers; not Android touch proof.",
		"status": "PASS" if failures.is_empty() else "FAIL"}
	var output := FileAccess.open("res://docs/evidence/mochi-hop-tests.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "  ") + "\n")
	print(JSON.stringify(report))
	app.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
