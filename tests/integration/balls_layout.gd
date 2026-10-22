extends SceneTree
## Measured before/after layout evidence for Bouncy Balls at the 720x1280 design
## aspect. Rendered desktop captures only; Android 720x1280 captures come from
## the installed development APK in CI, never from this script.
##
## Set MOCHI_LAYOUT_TAG=before|after (default before). Writes
## docs/evidence/bouncy-balls-<tag>-{opening,gate,full-pool}.png and
## docs/evidence/bouncy-balls-layout-<tag>.json.

var app: Control
var tag := "before"

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in range(count):
		await process_frame

func shot(name: String) -> void:
	await frames(2)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/bouncy-balls-" + tag + "-" + name + ".png")

func empty_pool(game: Node) -> void:
	for ball in game.pool:
		ball.active = false

func metrics(game: Node) -> Dictionary:
	var constants: Dictionary = game.get_script().get_script_constant_map()
	var ball_diameter: float = float(constants.get("RADIUS", 11.0)) * 2.0
	var bumper_diameter: float = float(constants.get("BUMPER_RADIUS", 27.0)) * 2.0
	var first: Rect2 = game.bricks[0].rect
	var second: Rect2 = game.bricks[1].rect
	var column_positions := {}
	var row_positions := {}
	for brick in game.bricks:
		column_positions[brick.rect.position.x] = true
		row_positions[brick.rect.position.y] = true
	var columns: int = column_positions.size()
	var rows: int = row_positions.size()
	var bottom := first.position.y
	for brick in game.bricks:
		bottom = maxf(bottom, brick.rect.end.y)
	var screen_width := float(ProjectSettings.get_setting("display/window/size/viewport_width"))
	var gates: Array = []
	for gate in game.gates:
		gates.append({"width": gate.size.x, "height": gate.size.y, "center": [snappedf(gate.get_center().x, 0.1), snappedf(gate.get_center().y, 0.1)]})
	var bumpers: Array = []
	for point in game.bumpers:
		bumpers.append([snappedf(point.x, 0.1), snappedf(point.y, 0.1)])
	return {
		"tag": tag,
		"area": [game.area.x, game.area.y],
		"screen_width": screen_width,
		"ball_diameter": ball_diameter,
		"ball_percent_area_width": snappedf(ball_diameter / game.area.x * 100.0, 0.01),
		"ball_percent_screen_width": snappedf(ball_diameter / screen_width * 100.0, 0.01),
		"paddle": {"width": game.paddle_rect().size.x, "height": game.paddle_rect().size.y,
			"percent_area_width": snappedf(game.paddle_rect().size.x / game.area.x * 100.0, 0.01)},
		"bricks": {"count": game.bricks.size(), "columns": columns, "rows": rows,
			"width": snappedf(first.size.x, 0.01), "height": snappedf(first.size.y, 0.01),
			"gap_x": snappedf(second.position.x - first.end.x, 0.01),
			"percent_area_width": snappedf(first.size.x / game.area.x * 100.0, 0.01),
			"top": snappedf(first.position.y, 0.01), "bottom": snappedf(bottom, 0.01),
			"wall_percent_area_height": snappedf((bottom - first.position.y) / game.area.y * 100.0, 0.01)},
		"gates": gates,
		"gate0_percent_area_width": snappedf(game.gates[0].size.x / game.area.x * 100.0, 0.01),
		"bumper_diameter": bumper_diameter,
		"bumper_percent_area_width": snappedf(bumper_diameter / game.area.x * 100.0, 0.01),
		"bumper_centers": bumpers,
		"paddle_y": snappedf(game.paddle_y(), 0.01),
		"scope": "Desktop Compatibility renderer; production constants and live brick/gate geometry. Not Android evidence.",
	}

func write_metrics(game: Node) -> void:
	var output := FileAccess.open("res://docs/evidence/bouncy-balls-layout-" + tag + ".json", FileAccess.WRITE)
	output.store_string(JSON.stringify(metrics(game), "  ") + "\n")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Bouncy Balls layout evidence requires the actual renderer")
		quit(1)
		return
	tag = OS.get_environment("MOCHI_LAYOUT_TAG")
	if tag == "":
		tag = "before"
	root.size = Vector2i(450, 800)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var save = root.get_node("Save")
	save.folder = "user://qa-layout-" + str(int(Time.get_unix_time_from_system() * 1000000)) + "-" + str(OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(save.folder)
	save.data = save.defaults()
	save.data.settings.music = false
	save.data.settings.sfx = false
	root.get_node("Sound").apply_settings()
	app = load("res://scenes/app/main.tscn").instantiate()
	root.add_child(app)
	app.open_game(3, true, 881)
	app.resume()
	var game = app.game
	await frames(30)
	await shot("opening")
	# Drive one real ball through the x2 gate, then two through the x3 gate.
	game.set_physics_process(false)
	empty_pool(game)
	game.spawn(game.gates[0].get_center() + Vector2(0, 80), Vector2.UP * game.speed(), 0)
	game._physics_process(0.3)
	for i in range(2):
		if game.pool[i].active:
			game.pool[i].p = game.gates[1].get_center() + Vector2(0, 80)
			game.pool[i].v = Vector2.UP * game.speed()
	game._physics_process(0.3)
	await shot("gate")
	# Maximum-pool fixture through the unchanged production restore path.
	var balls: Array = []
	for i in range(64):
		balls.append([0.14 + (i % 8) * 0.1, 0.49 + (i / 8) * 0.025, (-1 if i % 2 else 1) * (140 + i % 5 * 20), -380, 3, i % 5])
	var health: Array = []
	for i in range(4):
		health.append(5)
	for i in range(20):
		health.append(4)
	app.leave_game()
	save.data.sessions["bouncy_balls"] = {"seed": 640012, "wave": 7, "score": 0, "paddle": 0.5,
		"balls": balls, "health": health, "clear": 0, "area": [game.area.x, game.area.y]}
	app.open_game(3)
	app.resume()
	game = app.game
	game.set_physics_process(false)
	await frames(14)
	await shot("full-pool")
	write_metrics(game)
	print(JSON.stringify(metrics(game)))
	await root.get_node("Sound").shutdown()
	app.queue_free()
	await process_frame
	quit(0)
