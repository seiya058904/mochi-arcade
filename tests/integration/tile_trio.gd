extends SceneTree
const RULES := preload("res://scripts/games/trio_rules.gd")
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

func fresh() -> Node:
	app.open_game(4, true, 701)
	app.resume()
	app.game.set_process(false)
	return app.game

func pick(game: Node, id: int) -> void:
	game.press(game.tile_rect(id).get_center())
	game._process(0.2)

func run() -> void:
	root.size = Vector2i(450, 800)
	var save = root.get_node("Save")
	save.folder = "user://qa-trio-" + str(int(Time.get_unix_time_from_system() * 1000000)) + "-" + str(OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(save.folder)
	save.data = save.defaults()
	save.data.settings.music = false
	root.get_node("Sound").apply_settings()
	app = load("res://scenes/app/main.tscn").instantiate()
	root.add_child(app)
	var game := fresh()
	check(game.tiles.size() == 36 and game.mask == RULES.all_mask(), "Fresh layered board is complete")
	var original: int = game.mask
	game.press(game.tile_rect(0).position + Vector2(2, 2))
	check(game.mask == original and game.tray.is_empty(), "Visible corner of covered tile remains unavailable")
	var id: int = RULES.available(game.tiles, game.mask)[0]
	game.press(game.tile_rect(id).get_center())
	game.press(game.tile_rect(id).get_center())
	check(game.tray == [id] and game.history.size() == 1, "Rapid double tap cannot duplicate a tile")
	game._process(0.05)
	var animation_time: float = game.animation.time
	game.set_suspended(true)
	game._process(1)
	check(game.animation.time == animation_time, "Pause freezes tile motion")
	game.set_suspended(false)
	game.set_process(false)
	game.action("undo")
	check(game.mask == original and game.tray.is_empty() and game.animation.is_empty(), "Undo during transit restores the tile atomically")
	game.action("undo")
	check(game.mask == original and game.history.is_empty(), "Empty undo is harmless")
	# The independent solver may mix motifs before matching; this legal constructed
	# triple specifically exercises the atomic three-tile animation and undo path.
	var match_path: Array = RULES.generate(701, 1).witness.slice(0, 3)
	for tile_id in match_path:
		pick(game, tile_id)
	check(game.tray.is_empty() and game.score == 30 and game.matches == 1, "Three same motifs clear and score once")
	game.action("undo")
	check(game.tray.size() == 2 and game.score == 0, "Undo restores both companions removed by a match")
	pick(game, match_path[2])
	check(game.score == 30 and game.tray.is_empty(), "Replaying after undo does not inflate score")
	var saved_mask: int = game.mask
	var saved_history: int = game.history.size()
	app.leave_game()
	app.open_game(4)
	app.resume()
	game = app.game
	game.set_process(false)
	check(game.mask == saved_mask and game.score == 30 and game.history.size() == saved_history, "Mask, score and undo history survive reload")
	check(game.run_seed == 701, "Original level seed survives reload")
	game.action("undo")
	check(game.tray.size() == 2 and game.score == 0, "Restored undo snapshot is usable")
	game.action("hint")
	check(game.hint_status == "SOLVED" and RULES.selectable(game.tiles, game.mask, game.hint_id), "Free hint points to a solver-confirmed available tile")
	check(game.tray.size() == 2 and game.score == 0, "A hint never plays or scores for the player")
	game = fresh()
	# Legal poor choices minimize matches, producing a natural full tray.
	for step in range(36):
		if game.stopped:
			break
		var counts := PackedInt32Array()
		counts.resize(8)
		for item in game.tray:
			counts[game.tiles[item].kind] += 1
		var choices := RULES.available(game.tiles, game.mask)
		choices.sort_custom(func(a: int, b: int): return counts[game.tiles[a].kind] < counts[game.tiles[b].kind])
		pick(game, choices[0])
	check(game.stopped and game.tray.size() == 7 and is_instance_valid(app.overlay), "Seven unmatched tray tiles naturally end the round")
	var undo_button: Button
	for box in app.overlay.get_children():
		for child in box.get_children():
			if child is Button and child.text == "Undo last tile":
				undo_button = child
	check(is_instance_valid(undo_button), "Full-tray results offer free undo")
	if is_instance_valid(undo_button):
		undo_button.pressed.emit()
	game.set_process(false)
	check(not game.stopped and game.tray.size() == 6 and not is_instance_valid(app.overlay), "Result undo recovers the same board")
	game.action("hint")
	for step in range(36):
		if game.hint_status == "SOLVED":
			break
		game.action("undo")
		game.action("hint")
	check(game.hint_status == "SOLVED", "Repeated free undo recovers a provably solvable position")
	var solution := RULES.solve(game.tiles, game.mask, game.tray)
	for tile_id in solution.path:
		pick(game, tile_id)
	check(game.mask == 0 and game.tray.is_empty() and game.clear_time > 0, "Complete board has a clear celebration state")
	game._process(1)
	check(game.stage == 2 and game.mask == RULES.all_mask() and game.history.is_empty(), "Next level is fresh with no stale undo")
	check(save.best("tile_trio") >= 420, "Completed level records its score")
	app.restart()
	check(app.game.stage == 1 and app.game.score == 0 and not app.game.stopped, "Restart returns to a valid first level")
	app.show_home()
	await process_frame
	check(app.get_child_count() == 1, "Tile scene and temporary state unload fully")
	var report := {"suite": "Tile Trio runtime and recovery", "seed": 701, "checks": checks,
		"failures": failures, "status": "PASS" if failures.is_empty() else "FAIL",
		"evidence": "Actual scene with legal tile clicks and button signals; no injected loss or victory flags."}
	var output := FileAccess.open("res://docs/evidence/tile-trio-tests.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "  ") + "\n")
	print(JSON.stringify(report))
	app.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
