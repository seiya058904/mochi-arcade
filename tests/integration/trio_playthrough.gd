extends SceneTree
const RULES := preload("res://scripts/games/trio_rules.gd")
var app: Control

func _initialize() -> void:
	call_deferred("run")

func click(point: Vector2) -> void:
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		event.position = root.get_final_transform() * point
		Input.parse_input_event(event)

func capture(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/evidence/desktop-trio-" + name + ".png")

func settle(game: Node) -> void:
	for frame in range(90):
		await process_frame
		if game.animation.is_empty() and game.clear_time <= 0:
			break

func run() -> void:
	root.size = Vector2i(450, 800)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var save = root.get_node("Save")
	save.folder = "user://qa-trio-play-" + str(int(Time.get_unix_time_from_system() * 1000000)) + "-" + str(OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(save.folder)
	save.data = save.defaults()
	save.data.settings.music = false
	root.get_node("Sound").apply_settings()
	app = load("res://scenes/app/main.tscn").instantiate()
	root.add_child(app)
	app.open_game(4, true, 701)
	app.resume()
	var game = app.game
	await process_frame
	await capture("opening")
	var trace: Array = []
	var error := ""
	for step in range(180):
		game.action("hint")
		if game.hint_status != "SOLVED" or game.hint_id < 0:
			error = "No safe hint at pick " + str(step)
			break
		var id: int = game.hint_id
		trace.append({"stage": game.stage, "id": id})
		if step == 0:
			await capture("hint")
		click(game.to_global(game.tile_rect(id).get_center()))
		await settle(game)
		if step == 7:
			await capture("play")
		if game.stopped:
			error = "Hinted path lost at pick " + str(step)
			break
	var cleared: int = game.stage - 1
	var clear_score: int = game.score
	# Continue with legal low-match choices until the seven-slot tray fills.
	for step in range(60):
		if game.stopped:
			break
		var counts := PackedInt32Array()
		counts.resize(8)
		for id in game.tray:
			counts[game.tiles[id].kind] += 1
		var choices := RULES.available(game.tiles, game.mask)
		choices.sort_custom(func(a: int, b: int): return counts[game.tiles[a].kind] < counts[game.tiles[b].kind])
		var id: int = choices[0]
		trace.append({"stage": game.stage, "id": id})
		click(game.to_global(game.tile_rect(id).get_center()))
		await settle(game)
	await capture("result")
	var natural_loss: bool = game.stopped and game.tray.size() == 7
	var recovered := false
	if natural_loss:
		for box in app.overlay.get_children():
			for child in box.get_children():
				if child is Button and child.text == "Undo last tile":
					click(child.get_global_rect().get_center())
					break
		# GUI button activation is dispatched on the next scene iteration.
		await process_frame
		await process_frame
		recovered = not game.stopped and game.tray.size() == 6 and not is_instance_valid(app.overlay)
	await capture("recovered")
	var report := {"seed": 701, "stages_cleared": cleared, "clear_score": clear_score,
		"picks": game.picks, "natural_full_tray": natural_loss, "result_undo_recovers": recovered,
		"error": error, "input_trace": trace,
		"evidence": "Godot mouse events at actual visible tile centers and result button. Free hints choose legal moves; low-match picks cause real tray overflow."}
	app.restart()
	report["retry_playable"] = app.game.stage == 1 and app.game.mask == RULES.all_mask() and not app.game.stopped
	report["status"] = "PASS" if cleared == 5 and clear_score == 2100 and natural_loss and recovered and error.is_empty() and report.retry_playable else "FAIL"
	var backend := "headless" if DisplayServer.get_name() == "headless" else "rendered"
	var output := FileAccess.open("res://docs/evidence/trio-playthrough-" + backend + ".json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "  ") + "\n")
	report.erase("input_trace")
	print(JSON.stringify(report))
	await root.get_node("Sound").shutdown()
	app.queue_free()
	await process_frame
	quit(0 if report.status == "PASS" else 1)
