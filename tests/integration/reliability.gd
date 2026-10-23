extends SceneTree

var failures: Array[String] = []
var checks := 0
var notifications: Array[int] = []

class ShortWriter extends "res://scripts/app/save_manager.gd":
	func write_temp(path: String, contents: String) -> Error:
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(contents.substr(0, 8))
		file.close()
		return ERR_FILE_CANT_WRITE # Deterministic disk-full/short-write fault.

class DeniedReader extends "res://scripts/app/save_manager.gd":
	func decode(path: String) -> Dictionary:
		if path.ends_with("/save.json"):
			read_error = ERR_FILE_NO_PERMISSION
			return {}
		return super.decode(path)

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func write(path: String, value: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(value)
	file.close()

func shot(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	await process_frame
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png("res://.local/iteration-1.1/" + name + ".png")

func run() -> void:
	var save = root.get_node("Save")
	save.folder = "user://qa-reliability-%s-%s" % [int(Time.get_unix_time_from_system() * 1000000), OS.get_process_id()]
	DirAccess.make_dir_recursive_absolute(save.folder)
	save.data = save.defaults()
	save.data.settings.music = false
	save.data.settings.sfx = false
	root.get_node("Sound").apply_settings()
	check(save.flush() == OK, "Initial isolated save succeeds")
	save.persistence_changed.connect(func(error): notifications.append(error))
	var primary: String = save.folder.path_join("save.json")
	var backup: String = save.folder.path_join("save.backup.json")
	var temp: String = save.folder.path_join("save.tmp")
	var original := FileAccess.get_file_as_bytes(primary)
	DirAccess.make_dir_absolute(temp)
	var result = save.record("number_bloom", 128)
	check(result != null and result != OK, "Record returns the actual write failure")
	check(save.get("dirty") == true and save.last_error != OK, "Failed progress remains explicitly pending in memory")
	check(save.best("number_bloom") == 128, "Failed disk write does not discard live progress")
	check(FileAccess.get_file_as_bytes(primary) == original, "Failed temp open preserves primary bytes")
	check(save.set_setting("language", "zh") != OK, "Settings propagate failed write")
	check(save.save_session("number_bloom", {}) != OK, "Session save propagates failed write")
	check(save.clear_session("number_bloom") != OK, "Session clear propagates failed write")
	check(notifications.size() == 1, "Repeated failures notify only once")
	save.data.settings.language = "en"
	# Remove only our deliberately created empty fault fixture.
	DirAccess.remove_absolute(temp)
	check(save.flush() == OK and save.get("dirty") == false, "Retry commits pending progress and clears dirty status")
	check(notifications.size() == 2 and notifications[-1] == OK, "Recovery notifies exactly once")
	save.load_save()
	check(save.best("number_bloom") == 128, "Retried progress survives restart")
	# Prevent backup replacement, then verify both old files survive.
	var backup_before := FileAccess.get_file_as_bytes(backup)
	DirAccess.make_dir_absolute(save.folder.path_join("save.backup.tmp"))
	result = save.set_setting("language", "zh")
	check(result != null and result != OK, "Backup staging failure is propagated")
	check(FileAccess.get_file_as_bytes(backup) == backup_before, "Backup staging failure preserves previous backup")
	check(save.decode(primary).settings.language == "en", "Backup failure does not commit primary")
	DirAccess.remove_absolute(save.folder.path_join("save.backup.tmp"))
	check(save.flush() == OK, "Backup failure is retryable")
	# A syntactically valid but damaged record must recover from its valid backup.
	save.record("number_bloom", 256)
	save.flush()
	var damaged: Dictionary = save.data.duplicate(true)
	damaged.records.number_bloom = "damaged"
	damaged.settings.language = []
	write(primary, JSON.stringify(damaged))
	save.load_save()
	check(save.best("number_bloom") == 256 and save.setting("language") == "zh", "Partial corruption recovers valid backup fields")
	check(save.recovered, "Partial backup recovery is reported")
	write(primary, "{broken")
	save.load_save()
	check(save.best("number_bloom") == 256 and save.recovered, "Broken JSON recovers backup without resetting records")
	check(save.flush() == OK, "Recovered data can be committed")
	check(save.decode(backup).records.number_bloom == 256, "Corrupt primary never replaces valid backup")
	var short_writer := ShortWriter.new()
	short_writer.folder = save.folder
	short_writer.data = save.data.duplicate(true)
	original = FileAccess.get_file_as_bytes(primary)
	backup_before = FileAccess.get_file_as_bytes(backup)
	check(short_writer.record("number_bloom", 512) == ERR_FILE_CANT_WRITE, "Short write propagates exact error")
	check(FileAccess.get_file_as_bytes(primary) == original and FileAccess.get_file_as_bytes(backup) == backup_before, "Partial temp write preserves both valid files")
	short_writer.free()
	var denied_reader := DeniedReader.new()
	denied_reader.folder = save.folder
	denied_reader.load_save()
	check(denied_reader.load_error == ERR_FILE_NO_PERMISSION, "Read failure remains distinct from corrupt or missing data")
	check(denied_reader.record("number_bloom", 9999) == ERR_FILE_NO_PERMISSION, "Unreadable primary blocks replacement with pending/default data")
	check(FileAccess.get_file_as_bytes(primary) == original and FileAccess.get_file_as_bytes(backup) == backup_before, "Read-denied path preserves both original files byte for byte")
	denied_reader.load_error = OK
	denied_reader.data = save.data.duplicate(true)
	check(denied_reader.record("number_bloom", 10000) == ERR_FILE_NO_PERMISSION, "Read access lost after loading also blocks replacement")
	check(FileAccess.get_file_as_bytes(primary) == original, "Mid-session read denial preserves old primary")
	denied_reader.free()
	# Deny primary rename with an empty directory at its destination.
	var held_primary: String = save.folder.path_join("held-primary.json")
	DirAccess.rename_absolute(primary, held_primary)
	DirAccess.make_dir_absolute(primary)
	check(save.flush() != OK and save.dirty, "Primary rename failure stays pending")
	check(FileAccess.get_file_as_bytes(backup) == backup_before, "Rename failure preserves backup")
	DirAccess.remove_absolute(primary)
	DirAccess.rename_absolute(held_primary, primary)
	check(save.flush() == OK, "Rename failure retries successfully")
	DirAccess.make_dir_absolute(temp)
	check(save.reset_records() != OK and save.decode(primary).records.number_bloom == 256, "Failed reset is explicit and does not erase disk records")
	DirAccess.remove_absolute(temp)
	save.load_save()
	save.data.settings.language = "en"
	var app = load("res://scenes/app/main.tscn").instantiate()
	root.add_child(app)
	app.open_game(6, true, 1100)
	app.resume()
	var saved_board: Array = save.session("number_bloom").board.duplicate()
	save.flush()
	damaged = save.data.duplicate(true)
	damaged.sessions.number_bloom.board[0] = {"broken": true}
	damaged.records.fruit_drop = 999
	write(primary, JSON.stringify(damaged))
	write(temp, JSON.stringify(save.defaults()))
	save.load_save()
	check(save.session("number_bloom").board.map(func(n): return int(n)) == saved_board and save.recovered, "Damaged nested session recovers from valid backup")
	check(save.best("fruit_drop") == 999, "Valid newer primary fields beat backup and uncommitted temp")
	var game = app.game
	var before := [2, 4, 8, 16, 4, 8, 16, 32, 8, 16, 32, 64, 2, 2, 8, 16]
	game.board = before.duplicate()
	game.score = 64
	var rng_before: int = game.rng.state
	game.press(Vector2(500, 300))
	game.release(Vector2(100, 300))
	await create_timer(0.3).timeout
	check(game.stopped and is_instance_valid(app.overlay), "Actual final legal swipe reaches results")
	var undo: Button
	for item in app.overlay.find_children("*", "Button", true, false):
		if item.text == "Undo last move":
			undo = item
	check(undo != null, "Number Bloom terminal sheet exposes Undo last move")
	await shot("terminal-undo-en")
	if undo != null:
		undo.pressed.emit()
		check(not game.stopped and not game.suspended and not is_instance_valid(app.overlay), "Result Undo resumes a playable round")
		check(game.board == before and game.score == 64 and game.rng.state == rng_before and game.undo_state.is_empty(), "Result Undo restores board score RNG and consumes snapshot")
		check(save.best("number_bloom") >= 68, "Undo retains earned best record")
		app.leave_game()
		save.load_save()
		app.open_game(6)
		app.resume()
		check(app.game.board == before and app.game.score == 64, "Undone terminal round survives close and reload")
		app.restart()
		check(app.game.score == 0 and app.game.undo_state.is_empty(), "Restart clears terminal Undo snapshot")
	# Failure feedback is deferred safely through settings rebuilds and lifecycle.
	DirAccess.make_dir_absolute(temp)
	app.exit_application()
	for item in app.overlay.find_children("*", "Button", true, false):
		if item.text == "Stay here":
			item.pressed.emit()
	check(not app.game.suspended and not app.exiting and not is_instance_valid(app.overlay), "Cancel failed exit resumes the active round")
	app.game.stopped = true
	app.exit_application()
	for item in app.overlay.find_children("*", "Button", true, false):
		if item.text == "Stay here":
			item.pressed.emit()
	check(is_instance_valid(app.overlay) and app.game.stopped and not app.exiting, "Cancel failed exit preserves terminal result actions")
	save.set_setting("language", "zh")
	app.show_settings()
	await process_frame
	await process_frame
	check(is_instance_valid(app.toast_label) and "无法保存" in app.toast_label.text, "Failure is visibly explained in selected language")
	await shot("save-failure-zh")
	app.exit_application()
	check(not app.exiting and is_instance_valid(app.overlay), "Failed save blocks normal quit with an explicit choice")
	await shot("save-exit-zh")
	DirAccess.remove_absolute(temp)
	app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	check(not save.dirty and save.decode(primary).settings.language == "zh", "Foreground retry saves pending settings")
	if DisplayServer.get_name() != "headless":
		for language in ["en", "zh"]:
			save.data.settings.language = language
			save.load_error = ERR_FILE_NO_PERMISSION
			app.show_settings()
			app._save_status(ERR_FILE_NO_PERMISSION)
			await shot("read-failure-" + language)
			app.exit_application()
			await shot("read-exit-" + language)
			save.load_error = OK
	var report := {"status": "PASS" if failures.is_empty() else "FAIL", "checks": checks, "failures": failures, "scope": "Isolated filesystem fault fixtures and actual terminal swipe; desktop, not Android"}
	DirAccess.make_dir_recursive_absolute("res://.local/iteration-1.1")
	write("res://.local/iteration-1.1/reliability.json", JSON.stringify(report, "  "))
	print(JSON.stringify(report))
	await root.get_node("Sound").shutdown()
	app.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
