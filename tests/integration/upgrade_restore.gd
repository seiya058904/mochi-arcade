extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var save = root.get_node("Save")
	save.folder = "user://qa-upgrade-restore-%s-%s" % [Time.get_ticks_usec(), OS.get_process_id()]
	DirAccess.make_dir_recursive_absolute(save.folder)
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/integration/fixtures/upgrade-v1.0.0.json"))
	save.data = fixture.save.duplicate(true)
	save.data.settings.music = false
	save.flush()
	root.size = Vector2i(720, 1280)
	var app = load("res://scenes/app/main.tscn").instantiate()
	root.add_child(app)
	# Desktop geometry differs from Android's safe insets; instantiate at the
	# source Android dimensions and call real restore/checkpoint before a tick.
	var results := {}
	for id in fixture.save.sessions:
		var game = load("res://scenes/games/" + id + ".tscn").instantiate()
		game.setup(id, Vector2(648, 894), app.font)
		root.add_child(game)
		game.set_suspended(true)
		game.checkpoint()
		results[id] = save.session(id)
		game.free()
	DirAccess.make_dir_recursive_absolute("res://.local/iteration-1.1.1")
	var out := FileAccess.open("res://.local/iteration-1.1.1/upgrade-restore.json", FileAccess.WRITE)
	out.store_string(JSON.stringify(results, "  "))
	out.close()
	await root.get_node("Sound").shutdown()
	app.queue_free()
	await process_frame
	quit()
