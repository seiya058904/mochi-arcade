extends SceneTree
## Reproducible normal drop actions; never injects high tiers, score or a loss.
## --fixed-fps 60 speeds wall time while preserving the 60 Hz simulation step.
var app: Control

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(450, 800)
	var save = root.get_node("Save")
	save.folder = "user://qa-fruit-play-" + str(Time.get_ticks_msec())
	DirAccess.make_dir_recursive_absolute(save.folder)
	save.data = save.defaults()
	save.data.settings.music = false
	root.get_node("Sound").apply_settings()
	app = load("res://scenes/app/main.tscn").instantiate()
	root.add_child(app)
	app.open_game(0, true)
	app.resume()
	var game = app.game
	game.rng.seed = 817
	game.run_seed = 817
	game.next_level = game.rng.randi_range(0, 2)
	var input_rng := RandomNumberGenerator.new()
	input_rng.seed = 4182
	var drops := 0
	var peak_count := 0
	var highest_level := 0
	var nodes_before := get_node_count()
	var trail: Array = []
	var finished := false
	for tick in range(30000):
		if tick % 29 == 0 and not game.stopped:
			var x := input_rng.randf_range(42, game.area.x - 42)
			trail.append(snappedf(x, 0.01))
			game.press(Vector2(x, 300))
			game.release(Vector2(x, 300))
			drops += 1
		peak_count = maxi(peak_count, game.fruits.size())
		for fruit in game.fruits:
			highest_level = maxi(highest_level, fruit.level)
		await physics_frame
		if drops == 24 and tick % 29 == 28 and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/evidence/desktop-fruit-drop.png")
		if game.stopped:
			finished = true
			break
	var result := {"status": "PASS" if finished and highest_level >= 4 else "FAIL", "drops": drops, "score": game.score, "natural_failure": finished, "highest_level": highest_level, "peak_fruit_count": peak_count, "seed": 817, "input_seed": 4182, "drop_x": trail, "evidence": "Normal press/release drops in a fixed 60 Hz Godot physics simulation. No level/score/loss injection."}
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/evidence/desktop-fruit-result.png")
	app.restart()
	result["restart_empty"] = app.game.fruits.is_empty() and not app.game.stopped
	app.show_home()
	await process_frame
	result["nodes_after_unload"] = get_node_count()
	result["nodes_before_play"] = nodes_before
	var suffix := "headless" if DisplayServer.get_name() == "headless" else "rendered"
	result["backend"] = suffix
	var file := FileAccess.open("res://docs/evidence/fruit-playthrough-" + suffix + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  ") + "\n")
	result.erase("drop_x")
	print(JSON.stringify(result))
	await root.get_node("Sound").shutdown()
	app.queue_free()
	await process_frame
	quit(0 if result.status == "PASS" and result.restart_empty else 1)
