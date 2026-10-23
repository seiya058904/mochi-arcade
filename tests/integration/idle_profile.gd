extends SceneTree

# Same seeded static scenes and real renderer before/after. Draw signals count
# GDScript canvas rebuilds, not GPU presentation or battery consumption.
var draws := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(450, 800)
	var save = root.get_node("Save")
	save.folder = "user://qa-idle-%s-%s" % [int(Time.get_unix_time_from_system() * 1000000), OS.get_process_id()]
	DirAccess.make_dir_recursive_absolute(save.folder)
	save.data = save.defaults()
	save.data.settings.music = false
	save.data.settings.sfx = false
	root.get_node("Sound").apply_settings()
	var app = load("res://scenes/app/main.tscn").instantiate()
	root.add_child(app)
	var output := OS.get_environment("MOCHI_IDLE_OUTPUT")
	if output.is_empty():
		output = "res://.local/iteration-1.1/idle"
	DirAccess.make_dir_recursive_absolute(output)
	var report := {"gpu": RenderingServer.get_video_adapter_name(), "scope": "Desktop real renderer; 180 idle frames after 90 settle frames; not Android power or FPS", "samples": []}
	for index in [-1, 6, 4, 1, 5]:
		if index >= 0:
			app.open_game(index, true, 1100 + index)
			app.resume()
		var item: CanvasItem = app if index < 0 else app.game
		item.draw.connect(func(): draws += 1)
		for frame in range(90):
			await process_frame
		draws = 0
		var id: String = "home" if index < 0 else app.game.game_id
		print("SAMPLE_BEGIN " + id)
		var times: Array[float] = []
		var intervals: Array[float] = []
		var submissions: Array[float] = []
		var previous := Time.get_ticks_usec()
		for frame in range(180):
			await process_frame
			var now := Time.get_ticks_usec()
			intervals.append((now - previous) / 1000.0)
			previous = now
			times.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000)
			submissions.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		times.sort()
		intervals.sort()
		submissions.sort()
		print("SAMPLE_END " + id)
		root.get_texture().get_image().save_png(output.path_join(id + ".png"))
		report.samples.append({"scene": id, "canvas_rebuilds": draws, "engine_process_monitor_ms_p50": times[90], "engine_process_monitor_ms_p95": times[171], "frame_interval_ms_p50": intervals[90], "frame_interval_ms_p95": intervals[171], "gpu_draw_calls_p50": submissions[90]})
	var file := FileAccess.open(output.path_join("report.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	print(JSON.stringify(report))
	await root.get_node("Sound").shutdown()
	app.queue_free()
	await process_frame
	quit()
