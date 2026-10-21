extends SceneTree
const RULES := preload("res://scripts/games/hop_rules.gd")
var app: Control

func _initialize() -> void:
	call_deferred("run")

func click_state(pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = root.get_final_transform() * app.play_rect.get_center()
	Input.parse_input_event(event)

func capture(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/evidence/desktop-hop-" + name + ".png")

func run() -> void:
	root.size = Vector2i(450, 800)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var save = root.get_node("Save")
	save.folder = "user://qa-hop-play-" + str(int(Time.get_unix_time_from_system() * 1000000)) + "-" + str(OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(save.folder)
	save.data = save.defaults()
	save.data.settings.music = false
	root.get_node("Sound").apply_settings()
	app = load("res://scenes/app/main.tscn").instantiate()
	root.add_child(app)
	app.open_game(5, true, 1729)
	app.resume()
	var game = app.game
	await process_frame
	await capture("opening")
	var input_trace: Array = []
	var timed_out := false
	for step in range(40):
		var desired_distance: float = game.foot.distance_to(game.target.center)
		if step % 4 == 3:
			desired_distance += game.target.radius * 0.55
		var frames := roundi(RULES.hold_for_distance(desired_distance) * 60)
		click_state(true)
		for frame in range(frames):
			await process_frame
			if step == 0 and frame == frames - 2:
				await capture("charge")
		input_trace.append({"step": step, "frames": frames, "held": game.held,
			"from": [game.foot.x, game.foot.y], "target": [game.target.center.x, game.target.center.y]})
		click_state(false)
		for frame in range(150):
			await process_frame
			if step == 0 and frame == 19:
				await capture("airborne")
			if game.state == game.State.READY or game.stopped:
				break
			if frame == 149:
				timed_out = true
		if step == 11:
			await capture("play")
		if game.stopped or timed_out:
			break
	var landed: int = game.landed
	var earned: int = game.score
	# A legal near-zero hold creates an actual miss, never a forced terminal flag.
	if not game.stopped:
		click_state(true)
		await process_frame
		click_state(false)
		for frame in range(150):
			await process_frame
			if game.stopped:
				break
	await capture("result")
	var report := {"seed": 1729, "landed": landed, "score": earned,
		"natural_failure": game.stopped, "timed_out": timed_out, "input_trace": input_trace,
		"evidence": "Godot mouse-down/up input through shared shell, holds measured in 60 Hz frames; no score, foot, success or failure injection."}
	app.restart()
	report["retry_playable"] = not app.game.stopped and app.game.state == app.game.State.READY and app.game.score == 0
	report["status"] = "PASS" if landed == 40 and report.natural_failure and not timed_out and report.retry_playable else "FAIL"
	var backend := "headless" if DisplayServer.get_name() == "headless" else "rendered"
	var output := FileAccess.open("res://docs/evidence/hop-playthrough-" + backend + ".json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "  ") + "\n")
	report.erase("input_trace")
	print(JSON.stringify(report))
	await root.get_node("Sound").shutdown()
	app.queue_free()
	await process_frame
	quit(0 if report.status == "PASS" else 1)
