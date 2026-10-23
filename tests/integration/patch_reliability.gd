extends SceneTree
## Boundary fixtures are explicitly synthetic; contacts/playthroughs have separate suites.
const TRIO := preload("res://scripts/games/trio_rules.gd")
var failures: Array[String] = []
var checks := 0
var app: Control
var save: Node

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func write(path: String, value: Variant) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(value if value is String else JSON.stringify(value))
	file.close()

func click(point: Vector2) -> void:
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		event.position = root.get_final_transform() * point
		Input.parse_input_event(event)
	await process_frame
	await process_frame

func button(text: String) -> void:
	var found: Button
	if is_instance_valid(app.overlay):
		for item in app.overlay.find_children("*", "Button", true, false):
			if item.text == text:
				found = item
	check(found != null, "Actual button exists: " + text)
	if found != null:
		await click(found.get_global_rect().get_center())

func shot(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		await process_frame
		RenderingServer.force_draw(false)
		root.get_texture().get_image().save_png("res://.local/iteration-1.1.1/" + name + ".png")

func fruit_value(fruit: Array) -> int:
	var total := 0
	for item in fruit:
		total += 1 << int(item.level)
	return total

func fresh_fruit() -> Node:
	var game = load("res://tests/integration/fixtures/observed_fruit.gd").new()
	game.setup("fruit_drop", Vector2(648, 850), app.font, 117)
	root.add_child(game)
	return game

func fruit_boundaries() -> void:
	save.data.sessions.erase("fruit_drop")
	var game = fresh_fruit()
	var a = game.spawn_fruit(0, Vector2(200, 600))
	var b = game.spawn_fruit(0, Vector2(240, 600))
	var rng_before: int = game.rng.state
	var next_before: int = game.next_level
	game.contact(a, b) # deterministic callback boundary, before idle deferred queue
	game.set_suspended(true)
	game.checkpoint()
	var frozen := FileAccess.get_file_as_string(save.folder.path_join("save.json"))
	var frozen_state: Dictionary = JSON.parse_string(frozen).sessions.fruit_drop
	check(fruit_value(frozen_state.fruit) == 2 and frozen_state.score == 0, "F3 claimed pair is preserved in successful paused snapshot")
	await process_frame
	await process_frame
	check(game.score == 0 and game.fruits.size() == 2, "F3 pending merge cannot change a suspended round")
	game.set_suspended(false)
	await create_timer(0.35).timeout
	check(game.score == 20 and game.fruits.size() == 1 and save.session("fruit_drop").score == 20, "F3 resume commits deferred merge exactly once")
	game.free()
	save.data.sessions.erase("fruit_drop")
	game = fresh_fruit()
	for x in [260, 300, 340]:
		game.spawn_fruit(0, Vector2(x, game.floor_y - 24))
	await create_timer(0.5).timeout
	check(game.merge_count == 1 and game.fruits.size() == 2 and game.score == 20, "F3 real triple contact never consumes a fruit twice")
	var merged = game.fruits.filter(func(f): return f.level == 1)[0]
	game.spawn_fruit(1, merged.position + Vector2(0, -45))
	await create_timer(0.5).timeout
	check(game.merge_count == 2 and game.score == 60, "F3 real chain contact preserves scoring")
	game.set_suspended(true)
	game.checkpoint()
	game.free()
	write(save.folder.path_join("save.json"), frozen)
	save.load_save()
	game = fresh_fruit()
	check(game.fruits.size() == 2 and game.rng.state == rng_before and game.next_level == next_before, "F3 new instance restores pre-merge fruit next and RNG")
	await create_timer(0.45).timeout
	check(game.score == 20 and game.merge_count == 1 and game.fruits.size() == 1, "F3 restored real contact scores exactly once")
	game.free()
	save.data.sessions.erase("fruit_drop")
	game = fresh_fruit()
	a = game.spawn_fruit(0, Vector2(160, 600))
	b = game.spawn_fruit(0, Vector2(200, 600))
	var c = game.spawn_fruit(1, Vector2(430, 600))
	var d = game.spawn_fruit(1, Vector2(480, 600))
	game.contact(a, b)
	game.contact(c, d)
	await process_frame
	check(game.snapshots.size() >= 2, "F3 both deferred merges reached actual checkpoint")
	if game.snapshots.size() >= 2:
		var first: String = game.snapshots[0]
		var state: Dictionary = JSON.parse_string(first).sessions.fruit_drop
		check(state.fruit.size() == 3 and fruit_value(state.fruit) == 6 and state.score == 20, "F3 first merge commit preserves independent pending pair and value")
		game.free()
		write(save.folder.path_join("save.json"), first)
		save.load_save()
		game = fresh_fruit()
		check(game.fruits.size() == 3 and game.score == 20, "F3 intermediate file restores coherent prefix of completed merges")
		await create_timer(0.45).timeout
		check(game.score == 60 and game.fruits.size() == 2, "F3 restored second pair scores once without replaying first merge")
	game.free()

func section_matrix() -> void:
	var primary: String = save.folder.path_join("save.json")
	var backup: String = save.folder.path_join("save.backup.json")
	var old: Dictionary = save.defaults()
	old.records.number_bloom = 100
	old.sessions.fruit_drop = {"fruit": [], "score": 10, "seed": 1}
	old.seen.fruit_drop = false
	var newer: Dictionary = old.duplicate(true)
	newer.settings.language = "zh"
	newer.records.number_bloom = 9999
	newer.sessions.fruit_drop.score = 900
	newer.seen.fruit_drop = true
	for section in ["settings", "records", "sessions", "seen"]:
		var damaged := newer.duplicate(true)
		damaged[section] = []
		write(primary, damaged)
		write(backup, old)
		save.load_save()
		for other in ["settings", "records", "sessions", "seen"]:
			check(save.data[other] == JSON.parse_string(JSON.stringify(old[other] if other == section else newer[other])), "F2 damaged %s preserves/restores %s only" % [section, other])
		check(save.flush() == OK, "F2 repaired section commits")
		var repaired: Dictionary = save.data.duplicate(true)
		save.load_save()
		check(JSON.stringify(save.data) == JSON.stringify(repaired), "F2 repaired section survives new read")
	var cleared := newer.duplicate(true)
	cleared.records = {}
	cleared.sessions = {}
	write(primary, cleared)
	write(backup, old)
	save.load_save()
	check(save.data.records.is_empty() and save.data.sessions.is_empty(), "F2 explicit empty sections never resurrect old progress")
	cleared = newer.duplicate(true)
	cleared.sessions.erase("fruit_drop")
	write(primary, cleared)
	save.load_save()
	check(not save.data.sessions.has("fruit_drop"), "F2 deleted individual session stays deleted")
	var damaged := newer.duplicate(true)
	damaged.settings.language = []
	old.settings.language = []
	write(primary, damaged)
	write(backup, old)
	save.load_save()
	check(save.setting("language") == "en" and save.best("number_bloom") == 9999, "F2 same bad field in both files defaults only that field")
	damaged = newer.duplicate(true)
	damaged.version = 2
	write(primary, damaged)
	var unknown := FileAccess.get_file_as_bytes(primary)
	save.load_save()
	check(save.flush() != OK and FileAccess.get_file_as_bytes(primary) == unknown, "F2 unsupported version cannot be silently downgraded on write")
	write(primary, newer)
	write(backup, newer)
	save.load_save()

func terminal_case(index: int, language: String, lifecycle: bool) -> void:
	save.data.settings.language = language
	save.data.settings.music = true
	root.get_node("Sound").apply_settings()
	app.open_game(index, true, 1100 if index == 6 else 701)
	app.resume()
	await process_frame
	var game = app.game
	var expected: Dictionary
	if index == 6:
		# Legal near-terminal board fixture followed by a real swipe and result tween.
		game.board = [2, 4, 8, 16, 4, 8, 16, 32, 8, 16, 32, 64, 2, 2, 8, 16]
		game.score = 64
		expected = {"board": game.board.duplicate(), "score": 64, "rng": game.rng.state, "won": game.won}
		game.press(Vector2(500, 300))
		game.release(Vector2(100, 300))
		await create_timer(0.3).timeout
	else:
		# Pick actual selectable tiles from a generated board until naturally full.
		for step in range(60):
			if game.stopped:
				break
			var counts := PackedInt32Array()
			counts.resize(8)
			for id in game.tray:
				counts[game.tiles[id].kind] += 1
			var choices := TRIO.available(game.tiles, game.mask)
			choices.sort_custom(func(a, b): return counts[game.tiles[a].kind] < counts[game.tiles[b].kind])
			expected = {"mask": game.mask, "tray": game.tray.duplicate(), "score": game.score, "history": game.history.duplicate(true)}
			await click(game.to_global(game.tile_rect(choices[0]).get_center()))
			await create_timer(0.2).timeout
	check(game.stopped and is_instance_valid(app.overlay), "F1 real terminal reached %s/%s" % [index, language])
	var best: int = save.best(game.game_id)
	var temp: String = save.folder.path_join("save.tmp")
	if lifecycle:
		app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		await process_frame
		app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	else:
		DirAccess.make_dir_absolute(temp)
		app._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await shot("exit-%s-%s" % [index, language])
		await button("Stay here" if language == "en" else "留在这里")
		check(save.dirty and save.last_error != OK, "F1 failed exit stays explicitly unsaved")
		check(game.stopped and is_instance_valid(app.overlay), "F1 cancel preserves result without restarting")
	await shot("terminal-%s-%s-%s" % [index, language, lifecycle])
	await button(("Undo last move" if index == 6 else "Undo last tile") if language == "en" else ("撤回最后一步" if index == 6 else "撤回最后一块"))
	check(not game.stopped and not game.suspended and game.process_mode == Node.PROCESS_MODE_INHERIT and not is_instance_valid(app.overlay), "F1 actual result Undo restores interactive lifecycle state")
	check(not root.get_node("Sound").music.stream_paused, "F1 terminal recovery resumes music")
	if index == 6:
		check(game.board == expected.board and game.score == expected.score and game.rng.state == expected.rng and game.won == expected.won and game.undo_state.is_empty(), "F1 Bloom Undo restores board score RNG won and consumes history")
	else:
		check(game.mask == expected.mask and game.tray == expected.tray and game.score == expected.score and game.history == expected.history, "F1 Trio Undo restores mask tray score and history")
	check(save.best(game.game_id) == best, "F1 earned best survives Undo")
	await shot("undone-%s-%s-%s" % [index, language, lifecycle])
	if not lifecycle:
		DirAccess.remove_absolute(temp) # Only the empty fixture created in this case.
		check(save.flush() == OK and not save.dirty, "F1 repaired storage commits pending Undo")
	if not game.stopped:
		var id: String = game.game_id
		game.checkpoint()
		var saved: Dictionary = save.session(id)
		app.leave_game()
		save.load_save()
		app.open_game(index)
		app.resume()
		check(save.session(id) == saved, "F1 recovered round survives restart")
		game = app.game
		if index == 6:
			game.press(Vector2(500, 300))
			game.release(Vector2(100, 300))
			check(game.score == 68, "F1 next actual Bloom swipe works")
		else:
			await click(game.to_global(game.tile_rect(TRIO.available(game.tiles, game.mask)[0]).get_center()))
			check(game.history.size() == expected.history.size() + 1, "F1 next actual Trio tile input works")
	app.leave_game()
	await process_frame

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.local/iteration-1.1.1")
	save = root.get_node("Save")
	save.folder = "user://qa-patch-%s-%s" % [Time.get_ticks_usec(), OS.get_process_id()]
	DirAccess.make_dir_recursive_absolute(save.folder)
	save.data = save.defaults()
	save.flush()
	app = load("res://scenes/app/main.tscn").instantiate()
	root.add_child(app)
	await fruit_boundaries()
	section_matrix()
	for language in ["en", "zh"]:
		for index in [6, 4]:
			await terminal_case(index, language, false)
			await terminal_case(index, language, true)
	app.queue_free()
	await process_frame
	# Run the real exit decisions with only the final process termination replaced
	# by an observable flag. The main terminal tests above use the real shell.
	app = load("res://tests/integration/fixtures/profile_app.gd").new()
	app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(app)
	save.data.settings.language = "en"
	app.open_game(6, true, 1100)
	app.resume()
	app._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	check(app.exiting and not save.dirty, "F1 normal close reaches quit only after successful commit")
	app.exiting = false
	app.resume()
	var temp: String = save.folder.path_join("save.tmp")
	DirAccess.make_dir_absolute(temp)
	app.exit_application()
	await button("Retry saving")
	check(not app.exiting and save.dirty, "F1 failed retry retains explicit choice and pending state")
	DirAccess.remove_absolute(temp)
	await button("Retry saving")
	check(app.exiting and not save.dirty, "F1 repaired retry commits before quit")
	app.exiting = false
	app.resume()
	var original := FileAccess.get_file_as_bytes(save.folder.path_join("save.json"))
	DirAccess.make_dir_absolute(temp)
	app.exit_application()
	await button("Close without saving")
	check(app.exiting and save.dirty and FileAccess.get_file_as_bytes(save.folder.path_join("save.json")) == original, "F1 explicit unsaved exit preserves last successful disk state")
	DirAccess.remove_absolute(temp)
	var report := {"status": "PASS" if failures.is_empty() else "FAIL", "checks": checks, "failures": failures, "scope": "Desktop boundary fixtures and real GUI Undo; not Android evidence"}
	write("res://.local/iteration-1.1.1/patch-reliability.json", report)
	print(JSON.stringify(report))
	await root.get_node("Sound").shutdown()
	app.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
