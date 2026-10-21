extends SceneTree

var checks := 0
var failures: Array[String] = []
var app: Control

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func swipe(from: Vector2, to: Vector2) -> void:
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = root.get_final_transform() * from
	Input.parse_input_event(down)
	await process_frame
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = root.get_final_transform() * to
	Input.parse_input_event(up)
	await create_timer(0.18).timeout

func run() -> void:
	var save = root.get_node("Save")
	save.folder = "user://qa-integration-" + str(int(Time.get_unix_time_from_system() * 1000000)) + "-" + str(OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(save.folder)
	save.data = save.defaults()
	save.data.settings.music = false
	root.get_node("Sound").apply_settings()
	app = load("res://scenes/app/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.open_game(2, true)
	app.resume()
	await process_frame
	var cake = app.game
	check(cake != null and cake.layers.size() == 1, "Cake starts with base layer")
	# Exercise the actual placement path, then a reachable miss.
	cake.moving_x = cake.layers[-1].x
	cake.press(Vector2(300, 300))
	check(cake.tier == 1 and cake.combo == 1 and cake.score == 2, "Cake perfect first input")
	app.show_pause()
	var before: float = cake.moving_time
	await create_timer(0.06).timeout
	check(cake.moving_time == before and cake.suspended, "Cake pause freezes movement")
	app.resume()
	var entering := Node.new()
	entering.tree_entered.connect(func(): app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT))
	app.add_child(entering)
	await process_frame
	check(cake.suspended and is_instance_valid(app.overlay) and app.overlay.is_inside_tree(), "Focus loss during child setup creates recoverable pause")
	app.resume()
	check(not cake.suspended and not is_instance_valid(app.overlay), "Lifecycle pause resumes after nested notification")
	entering.queue_free()
	cake.moving_x = cake.layers[-1].x + cake.layers[-1].w + 1
	cake.press(Vector2(300, 300))
	check(cake.stopped and is_instance_valid(app.overlay), "Cake miss shows result")
	app.restart()
	check(not app.game.stopped and app.game.tier == 0, "Cake immediate restart")
	app.leave_game()
	check(app.page == "home" and app.game == null, "Cake leaves without orphan scene")
	app.open_game(6, true)
	app.resume()
	await process_frame
	var bloom = app.game
	bloom.board = [2, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	var board_before: Array = bloom.board.duplicate()
	var rng_before: int = bloom.rng.state
	bloom.press(Vector2(500, 300))
	bloom.release(Vector2(100, 300))
	check(bloom.score == 8 and bloom.board.count(0) == 13, "2048 actual swipe merges then spawns once")
	var once: Array = bloom.board.duplicate()
	bloom.slide(1)
	check(bloom.board == once, "2048 ignores reentry during transition")
	bloom.action("undo")
	check(bloom.board == board_before and bloom.score == 0 and bloom.rng.state == rng_before, "2048 undo restores RNG and score")
	bloom.slide(0)
	check(bloom.board == once, "2048 undo replay is deterministic")
	bloom.animation = 1
	var resumed: Array = bloom.board.duplicate()
	app.leave_game()
	app.open_game(6)
	app.resume()
	check(app.game.board == resumed and app.game.score == 8, "2048 resumes saved board")
	app.game.board = [2, 2, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	app.game.score = 0
	app.game.animation = 1
	await swipe(app.play_rect.position + Vector2(500, 200), app.play_rect.position + Vector2(100, 200))
	check(app.game.score == 4 and app.active_pointer == -2, "Shell routes actual mouse press/release and clears ownership")
	await swipe(app.play_rect.position + Vector2(200, 500), app.play_rect.position + Vector2(200, 100))
	check(app.active_pointer == -2 and not app.game.holding, "Consecutive shell gestures remain usable")
	app.game.board = [2, 4, 2, 4, 4, 2, 4, 2, 2, 4, 2, 4, 4, 2, 4, 2]
	app.game.slide(0)
	check(app.game.stopped and is_instance_valid(app.overlay), "2048 terminal board results")
	for i in range(30):
		app.show_home()
		app.open_game(2 if i % 2 == 0 else 6, true)
		app.resume()
		await process_frame
		check(app.game != null and not app.game.suspended, "Scene switch " + str(i))
	app.show_home()
	await process_frame
	check(app.get_child_count() == 1, "No orphan games after 30 switches")
	var report := {"suite": "vertical-slice integration", "checks": checks, "failures": failures, "status": "PASS" if failures.is_empty() else "FAIL", "note": "Injected Godot inputs/state fixtures; not Android touch evidence."}
	print(JSON.stringify(report))
	var file := FileAccess.open("res://docs/evidence/vertical-slices.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	app.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
