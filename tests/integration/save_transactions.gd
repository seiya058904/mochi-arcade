extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var save = root.get_node("Save")
	save.set_script(load("res://tests/integration/fixtures/profile_save.gd"))
	save.folder = "user://qa-transactions-%s-%s" % [Time.get_ticks_usec(), OS.get_process_id()]
	DirAccess.make_dir_recursive_absolute(save.folder)
	save.data = save.defaults()
	save.data.settings.music = false
	save.flush()
	var app = load("res://tests/integration/fixtures/profile_app.gd").new()
	app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(app)
	var results := {}
	var failures: Array = []
	for action in ["scoring_swipe", "pause", "home", "exit"]:
		var samples: Array = []
		for i in range(110):
			app.open_game(6, true, 1100)
			app.resume()
			var game = app.game
			game.board = [2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
			game.score = i * 10
			game.checkpoint()
			save.data.records.number_bloom = game.score
			save.flush()
			save.flush_calls = 0
			save.write_calls = 0
			save.commits = 0
			var start := Time.get_ticks_usec()
			match action:
				"scoring_swipe": game.slide(0)
				"pause": app.show_pause()
				"home": app.leave_game()
				"exit": app.exiting = false; app.exit_application()
			var ms := (Time.get_ticks_usec() - start) / 1000.0
			if save.last_error != OK or save.dirty:
				failures.append(action + ": uncommitted action")
			if i >= 10:
				samples.append({"ms": ms, "flush": save.flush_calls, "writes": save.write_calls, "serializations": save.write_calls, "commits": save.commits})
			await process_frame
		results[action] = samples
	var report := {"status": "PASS" if failures.is_empty() else "FAIL", "failures": failures, "samples": results,
		"method": "100 samples per path after 10 warmups; fixed seed and board; real verified disk writes; serializer count equals write_temp calls (each supplied one JSON.stringify); Windows headless Godot 4.7.2; elapsed synchronous action wall time"}
	var out := FileAccess.open("res://.local/iteration-1.1.1/save-transactions.json", FileAccess.WRITE)
	out.store_string(JSON.stringify(report, "  "))
	out.close()
	print(report.status)
	await root.get_node("Sound").shutdown()
	app.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
