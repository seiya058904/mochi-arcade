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
		push_error(message)

func run() -> void:
	root.size = Vector2i(450, 800)
	var save = root.get_node("Save")
	save.folder = "user://qa-collection-" + str(int(Time.get_unix_time_from_system() * 1000000)) + "-" + str(OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(save.folder)
	save.data = save.defaults()
	save.data.settings.music = false
	save.data.settings.sfx = false
	root.get_node("Sound").apply_settings()
	app = load("res://scenes/app/main.tscn").instantiate()
	root.add_child(app)
	var schema = load("res://scripts/app/save_schema.gd")
	for cycle in range(40):
		var index := cycle % 8
		app.open_game(index, true, 3000 + cycle)
		app.resume()
		await process_frame
		check(app.game.game_id == app.C.GAMES[index][0] and not app.game.stopped, "All-game switch initializes live scene " + str(cycle))
		app.game.checkpoint()
		var valid_session: Dictionary = save.session(app.game.game_id)
		check(not valid_session.is_empty() and schema.session(app.game.game_id, JSON.parse_string(JSON.stringify(valid_session))), "Valid saved round survives JSON schema check " + str(cycle))
		for key in ["score", "seed"]:
			for bad in [null, {}, [], "not a number", INF, -1]:
				var mutated := valid_session.duplicate(true)
				mutated[key] = bad
				check(not schema.session(app.game.game_id, mutated), "Reject malformed numeric field " + key + " " + str(cycle))
		if index == 2:
			app.game.moving_x = app.game.layers[-1].x # Valid placement for the lifecycle fixture.
		var down := InputEventScreenTouch.new()
		down.position = app.play_rect.get_center()
		down.index = 0
		down.pressed = true
		app._unhandled_input(down)
		app._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
		await process_frame
		check(app.game.suspended and is_instance_valid(app.overlay) and app.active_pointer == -2, "Background cancels owned gesture and creates recoverable pause " + str(cycle))
		var time_before: float = app.game.game_time
		await process_frame
		await process_frame
		check(app.game.game_time == time_before, "Paused world has no advancing effects " + str(cycle))
		app.resume()
		app.back()
		check(app.game.suspended and is_instance_valid(app.overlay), "Back opens pause " + str(cycle))
		app.back()
		check(not app.game.suspended and not is_instance_valid(app.overlay), "Back from pause resumes " + str(cycle))
		app.restart()
		check(not app.game.stopped and app.game.score == 0, "Restart resets each game's round " + str(cycle))
		app.leave_game()
		await process_frame
		check(app.get_child_count() == 1 and app.game == null and app.game_clip == null, "Switch removes all game/clip nodes " + str(cycle))
	# A valid JSON document can still contain a structurally damaged round.
	save.data.records.cake_stack = 28
	save.data.sessions.cake_stack = {"layers": [{}], "score": 5}
	app.open_game(2)
	app.resume()
	check(app.game.layers.size() == 1 and app.game.layers[0].has_all(["x", "w", "tier"]) and app.game.score == 0, "Damaged cake layer schema recovers a playable fresh round")
	check(save.best("cake_stack") == 28, "Rejecting one damaged round preserves its best record")
	app.leave_game()
	for malformed in [[], "wrong type", {"board": []}, {"board": [2], "undo": []}]:
		check(not schema.session("number_bloom", malformed), "2048 malformed nested structures are rejected")
	save.data.records.number_bloom = []
	save.data.settings.music = {"invalid": true}
	save.data.settings.language = "unknown"
	save.data.seen.number_bloom = [true]
	save.flush()
	save.load_save()
	check(save.best("number_bloom") == 0 and save.setting("music") == true and save.setting("language") == "en" and not save.data.seen.has("number_bloom"), "Malformed record/settings/seen values recover defaults without invalid casts")
	save.data.settings.music = false
	var board: Array = []
	board.resize(16)
	board.fill(0)
	board[0] = {"unexpected": true}
	save.data.sessions.number_bloom = {"board": board}
	app.open_game(6)
	app.resume()
	check(app.game.board.count(0) == 14, "Non-numeric 2048 cell recovers a fresh playable board")
	app.leave_game()
	for dimensions in [Vector2i(360, 640), Vector2i(360, 800), Vector2i(640, 800)]:
		root.size = dimensions
		await process_frame
		for index in range(8):
			app.open_game(index, true, 4000 + index)
			app.resume()
			check(app.play_rect.size.x > 0 and app.play_rect.size.y > 0 and app.game_clip.clip_contents, "Positive clipped play area " + str(index) + " " + str(dimensions))
			for child in app.ui.get_children():
				if child is Button:
					check(Rect2(Vector2.ZERO, app.size).encloses(child.get_global_rect()), "Touch button remains on screen " + child.text + " " + str(dimensions))
			if index == 6:
				var last_tile: Vector2 = app.game.tile_position(15) + Vector2.ONE * (app.game.cell - 2)
				check(last_tile.x <= app.game.area.x and last_tile.y <= app.game.area.y - 100, "2048 full board and footer fit aspect " + str(dimensions))
			app.leave_game()
			await process_frame
	var report := {"status": "PASS" if failures.is_empty() else "FAIL", "checks": checks, "failures": failures, "switches": 40, "viewports": [[360, 640], [360, 800], [640, 800]], "preserved_baseline_failures": ["Cake layers=[{}] accesses missing width and breaks round", "2048 non-numeric cell produces an invalid int cast", "640x800 portrait clips the bottom of the 2048 board"], "scope": "Full collection desktop lifecycle/geometry; not Android proof"}
	var output := FileAccess.open("res://docs/evidence/collection-audit.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "  ") + "\n")
	print(JSON.stringify(report))
	await root.get_node("Sound").shutdown()
	app.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
