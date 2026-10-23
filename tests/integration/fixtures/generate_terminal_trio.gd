extends SceneTree
const RULES = preload("res://scripts/games/trio_rules.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(720, 1280)
	var save = root.get_node("Save")
	save.folder = "user://qa-terminal-export-%s" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(save.folder)
	save.data = save.defaults()
	var app = load("res://scenes/app/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.open_game(4, true, 701)
	app.resume()
	await process_frame
	var game = app.game
	var initial: Dictionary = save.session("tile_trio").duplicate(true)
	var taps: Array = []
	var before_last: Dictionary
	for step in range(7):
		var counts := PackedInt32Array()
		counts.resize(8)
		for id in game.tray:
			counts[game.tiles[id].kind] += 1
		var choices := RULES.available(game.tiles, game.mask)
		choices.sort_custom(func(a, b): return counts[game.tiles[a].kind] < counts[game.tiles[b].kind])
		var point: Vector2 = game.to_global(game.tile_rect(choices[0]).get_center())
		taps.append([point.x, point.y])
		before_last = save.session("tile_trio").duplicate(true)
		game.press(game.tile_rect(choices[0]).get_center())
		await create_timer(0.3).timeout
	assert(game.stopped and before_last.tray.size() == 6)
	var output := {"source": "Production generator seed 701, real selectable tile choices; Android must execute all seven native taps", "viewport": [720, 1280], "initial": initial, "taps": taps, "before_last": before_last}
	FileAccess.open("res://tests/integration/fixtures/terminal-trio.json", FileAccess.WRITE).store_string(JSON.stringify(output, "  ") + "\n")
	quit()
