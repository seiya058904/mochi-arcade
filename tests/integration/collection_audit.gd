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

func click_ui(point: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = root.get_final_transform() * point
		Input.parse_input_event(event)
		await process_frame
	await process_frame

func edge_targets(dimensions: Vector2i) -> void:
	root.size = dimensions
	app.show_home()
	await process_frame
	var settings: Button = app.ui.find_children("*", "Button", false, false)[0]
	await click_ui(settings.position + Vector2(-6, settings.size.y * 0.5))
	check(app.page == "settings", "Settings opens from outside the painted left edge " + str(dimensions))
	if app.page != "settings":
		app.show_settings() # Continue collecting baseline failures without hiding them.
	var buttons: Array[Node] = app.ui.find_children("*", "Button", false, false)
	var music: Button = buttons[1]
	var was_music: bool = root.get_node("Save").setting("music")
	await click_ui(music.position + Vector2(music.size.x * 0.5, -6))
	check(root.get_node("Save").setting("music") != was_music, "Setting toggles above its painted edge " + str(dimensions))
	var back_button: Button = app.ui.find_children("*", "Button", false, false)[0]
	await click_ui(back_button.position + Vector2(-6, back_button.size.y * 0.5))
	check(app.page == "home", "Back works beyond its painted left edge " + str(dimensions))
	app.open_game(2, true, 4800)
	app.resume()
	await process_frame
	var help: Button = app.ui.find_children("*", "Button", false, false)[2]
	await click_ui(help.position + Vector2(help.size.x * 0.5, -6))
	check(is_instance_valid(app.overlay) and app.game.suspended, "Help opens above its painted footer edge " + str(dimensions))
	if not is_instance_valid(app.overlay):
		app.show_help()
	var resume_button: Button = app.overlay.find_children("*", "Button", true, false)[0]
	await click_ui(resume_button.global_position + Vector2(resume_button.size.x * 0.5, -6))
	check(not is_instance_valid(app.overlay) and not app.game.suspended, "Dialog action works above its painted edge " + str(dimensions))
	app.leave_game()
	root.get_node("Save").set_setting("music", false)
	root.get_node("Sound").apply_settings()

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
	check(not quit_on_go_back, "Android system Back must not request automatic engine exit")
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
		if index == 2:
			app.game.moving_time = 0.375 # The live clock differs from its last input checkpoint.
			app.game.update_moving()
		app._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
		check(app.game.suspended and app.active_pointer == -2, "Lifecycle notification freezes input and simulation before another frame " + str(cycle))
		if index == 2:
			check(is_equal_approx(float(save.session("cake_stack").time), 0.375), "Lifecycle notification persists the live clock before another frame " + str(cycle))
		await process_frame
		check(app.game.suspended and is_instance_valid(app.overlay) and app.active_pointer == -2, "Background cancels owned gesture and creates recoverable pause " + str(cycle))
		var time_before: float = app.game.game_time
		await process_frame
		await process_frame
		check(app.game.game_time == time_before, "Paused world has no advancing effects " + str(cycle))
		app.resume()
		root.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		if not quit_on_go_back:
			root.go_back_requested.emit()
		await process_frame
		check(app.game.suspended and is_instance_valid(app.overlay) and app.overlay.is_inside_tree(), "System Back opens a visible pause without engine exit " + str(cycle))
		root.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		if not quit_on_go_back:
			root.go_back_requested.emit()
		await process_frame
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
	var recovery_backup: Dictionary = save.decode(save.folder.path_join("save.backup.json"))
	save.load_save()
	check(save.best("number_bloom") == int(recovery_backup.records.get("number_bloom", 0)) and save.setting("music") == recovery_backup.settings.music and save.setting("language") == recovery_backup.settings.language and save.data.seen.get("number_bloom", false) == recovery_backup.seen.get("number_bloom", false), "Malformed fields recover exact valid backup values without invalid casts")
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
	save.data.settings.reduced_motion = true
	for dimensions in [Vector2i(360, 640), Vector2i(360, 800), Vector2i(640, 800)]:
		await edge_targets(dimensions)
	var report := {"status": "PASS" if failures.is_empty() else "FAIL", "checks": checks, "failures": failures, "switches": 40, "viewports": [[360, 640], [360, 800], [640, 800]], "preserved_baseline_failures": ["Cake layers=[{}] accesses missing width and breaks round", "2048 non-numeric cell produces an invalid int cast", "640x800 portrait clips the bottom of the 2048 board"], "scope": "Full collection desktop lifecycle/geometry; not Android proof"}
	var output := FileAccess.open("res://docs/evidence/collection-audit.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "  ") + "\n")
	print(JSON.stringify(report))
	await root.get_node("Sound").shutdown()
	app.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
