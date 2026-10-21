extends SceneTree
## Actual rendered viewport captures. Deliberately separate from touch evidence.
var app: Control

func _initialize() -> void:
	call_deferred("run")

func shot(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/" + name + ".png")

func run() -> void:
	root.size = Vector2i(450, 800)
	var save = root.get_node("Save")
	save.folder = "user://qa-visual-" + str(Time.get_ticks_msec())
	DirAccess.make_dir_recursive_absolute(save.folder)
	save.data = save.defaults()
	save.data.settings.music = false
	root.get_node("Sound").apply_settings()
	app = load("res://scenes/app/main.tscn").instantiate()
	root.add_child(app)
	await shot("desktop-home")
	app.show_settings()
	await shot("desktop-settings")
	save.set_setting("language", "zh")
	app.show_settings()
	await shot("desktop-settings-zh")
	save.set_setting("language", "en")
	app.open_game(2, true)
	await shot("desktop-help")
	app.resume()
	for i in range(6):
		app.game.moving_x = app.game.layers[-1].x + (0 if i % 2 == 0 else 16)
		app.game.press(Vector2(300, 300))
	await create_timer(0.2).timeout
	await shot("desktop-cake-stack")
	app.show_pause()
	await shot("desktop-pause")
	app.open_game(6, true)
	app.resume()
	for direction in [0, 3, 1, 3, 0, 2, 1, 3, 0, 0, 2, 1, 3, 0, 2, 3]:
		app.game.slide(direction)
		await create_timer(0.17).timeout
	await shot("desktop-number-bloom")
	app.open_game(1, true, 5402)
	app.resume()
	await shot("desktop-bubble-opening")
	root.size = Vector2i(360, 800)
	await process_frame
	app.show_home()
	await shot("desktop-home-tall")
	root.size = Vector2i(360, 640)
	await process_frame
	app.open_game(6)
	app.resume()
	await shot("desktop-bloom-small")
	app.queue_free()
	await process_frame
	quit()
