extends SceneTree
var app: Control
var captures: Array = []

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in range(count):
		await process_frame

func shot(name: String) -> void:
	await frames(2)
	await RenderingServer.frame_post_draw
	var path := "res://docs/evidence/matrix-" + name + ".png"
	root.get_texture().get_image().save_png(path)
	captures.append(path)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Visual matrix requires the actual renderer")
		quit(1)
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var save = root.get_node("Save")
	save.folder = "user://qa-matrix-" + str(int(Time.get_unix_time_from_system() * 1000000)) + "-" + str(OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(save.folder)
	save.data = save.defaults()
	save.data.settings.music = false
	root.get_node("Sound").apply_settings()
	app = load("res://scenes/app/main.tscn").instantiate()
	root.add_child(app)
	for profile in [[Vector2i(450, 800), "phone", "en"], [Vector2i(360, 800), "tall", "zh"], [Vector2i(640, 800), "wide", "en"]]:
		root.size = profile[0]
		save.data.settings.language = profile[2]
		await frames(2)
		app.show_home()
		await shot(profile[1] + "-home")
		app.show_settings()
		await shot(profile[1] + "-settings")
		for index in range(8):
			app.open_game(index, true, 2047 + index)
			app.resume()
			var game = app.game
			match index:
				0:
					for x in [0.35, 0.6, 0.45]:
						game.press(Vector2(game.area.x * x, 220))
						game.release(Vector2(game.area.x * x, 220))
						await frames(35)
				1:
					game.action("hint")
				2:
					await frames(75)
				3:
					await frames(80)
				4:
					game.action("hint")
					game.press(game.tile_rect(game.hint_id).get_center())
					await frames(15)
				5:
					game.press(Vector2.ZERO)
					await frames(34)
					game.release(Vector2.ZERO)
					await frames(18)
				6:
					var captured_merge := false
					for direction in [0, 2, 1, 3, 0, 2, 0, 3]:
						var before: int = game.score
						game.slide(direction)
						await frames(8)
						if game.score > before and not captured_merge and profile[1] == "phone":
							game.set_suspended(true)
							await shot("phone-number-merge")
							game.set_suspended(false)
							captured_merge = true
						await frames(4)
				7:
					await frames(65)
			game.set_suspended(true) # Freeze the actual simulated state for layout inspection.
			await shot(profile[1] + "-" + app.C.GAMES[index][0])
			if index == 6 and profile[1] == "phone":
				app.show_pause()
				await shot("phone-pause")
				app.resume()
				app.show_help()
				await shot("phone-help")
			app.leave_game()
	var report := {"status": "CAPTURED_REQUIRES_VISUAL_REVIEW", "viewports": [[450, 800], [360, 800], [640, 800]], "languages": ["en", "zh"], "screenshots": captures, "scope": "Actual Compatibility renderer. Worlds frozen after normal actions for layout inspection; not Android screenshots."}
	var output := FileAccess.open("res://docs/evidence/visual-matrix.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "  ") + "\n")
	print("Captured ", captures.size(), " actual viewport screens")
	await root.get_node("Sound").shutdown()
	app.queue_free()
	await process_frame
	quit()
