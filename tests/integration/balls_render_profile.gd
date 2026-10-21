extends SceneTree

# Optional real-renderer diagnostic. These are synthetic static pools, not
# ordinary gameplay or Android timing measurements. Headless is unsupported.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(720, 1280)
	var save = root.get_node("Save")
	save.folder = "user://qa-balls-render-" + str(int(Time.get_unix_time_from_system() * 1000000)) + "-" + str(OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(save.folder)
	save.data = save.defaults()
	save.data.settings.music = false
	save.data.settings.sfx = false
	root.get_node("Sound").apply_settings()
	var app = load("res://scenes/app/main.tscn").instantiate()
	root.add_child(app)
	app.open_game(3, true, 640012)
	app.resume()
	var game = app.game
	game.set_physics_process(false)
	for i in range(64):
		game.pool[i].p = Vector2((0.14 + (i % 8) * 0.1) * game.area.x, (0.49 + (i / 8) * 0.025) * game.area.y)
		game.pool[i].v = Vector2(140 if i % 2 else -140, -380)
	var report = {"scope": "Desktop draw submissions; synthetic static pools, not phone FPS", "gpu": RenderingServer.get_video_adapter_name(), "samples": []}
	for reduced in [false, true]:
		game.reduced_motion = reduced
		for count in [1, 64]:
			for i in range(64):
				game.pool[i].active = i < count
			for frame in range(15):
				game.queue_redraw()
				await process_frame
				await RenderingServer.frame_post_draw
			var samples: Array[float] = []
			for frame in range(60):
				game.queue_redraw()
				await process_frame
				await RenderingServer.frame_post_draw
				samples.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
			samples.sort()
			report.samples.append({"balls": count, "reduced_motion": reduced, "frames": 60, "draw_calls_min": samples[0], "draw_calls_p50": samples[30], "draw_calls_max": samples[59]})
			root.get_texture().get_image().save_png("res://.local/balls-render-" + str(count) + "-" + str(reduced) + ".png")
	report["status"] = "PASS" if report.samples[0].draw_calls_p50 > 0 and report.samples[1].draw_calls_p50 <= report.samples[0].draw_calls_p50 + 4 and report.samples[3].draw_calls_p50 <= report.samples[2].draw_calls_p50 + 4 else "FAIL"
	FileAccess.open("res://.local/balls-render-profile.json", FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print(JSON.stringify(report))
	await root.get_node("Sound").shutdown()
	app.queue_free()
	await process_frame
	quit(0 if report.status == "PASS" else 1)
