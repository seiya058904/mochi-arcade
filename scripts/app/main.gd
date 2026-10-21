extends Control

const P := preload("res://scripts/shared/palette.gd")
const C := preload("res://scripts/app/catalog.gd")
var ui: Control
var overlay: Control
var game: MochiGame
var current_index := -1
var page := "home"
var font: Font
var title_font: Font
var score_label: Label
var best_label: Label
var play_rect := Rect2()
var active_pointer := -2
var toast_label: Label
var toast_tween: Tween
var cached_icons: Array[Texture2D] = []
var top_safe := 36.0
var bottom_safe := 28.0
var switching := false
var lifecycle_suspend_pending := false

func _ready() -> void:
	get_tree().auto_accept_quit = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var latin: FontFile = load("res://assets/fonts/Nunito.ttf")
	var cjk: FontFile = load("res://assets/fonts/NotoSansSC.ttf")
	var cjk_regular := FontVariation.new()
	cjk_regular.base_font = cjk
	cjk_regular.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 550.0}
	var cjk_bold := FontVariation.new()
	cjk_bold.base_font = cjk
	cjk_bold.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 750.0}
	var regular := FontVariation.new()
	regular.base_font = latin
	regular.fallbacks = [cjk_regular]
	regular.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 650.0}
	font = regular
	var bold := FontVariation.new()
	bold.base_font = latin
	bold.fallbacks = [cjk_bold]
	bold.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 850.0}
	title_font = bold
	get_viewport().size_changed.connect(_resize)
	load_icons()
	show_home()

func _resize() -> void:
	if not is_inside_tree() or switching:
		return
	if page == "home":
		show_home()
	elif page == "settings":
		show_settings()
	elif is_instance_valid(game):
		# Freeze the current world rather than rebuilding/losing a run.
		layout_shell()
		show_pause()

func safe_insets() -> void:
	top_safe = 36
	bottom_safe = 28
	if OS.get_name() == "Android":
		var screen := DisplayServer.screen_get_size()
		var safe := DisplayServer.get_display_safe_area()
		if screen.x > 0 and safe.size.y > 0:
			var factor := size.x / float(screen.x)
			top_safe = maxf(32.0, safe.position.y * factor + 12)
			bottom_safe = maxf(24.0, (screen.y - safe.end.y) * factor + 12)

func load_icons() -> void:
	cached_icons.clear()
	if not ResourceLoader.exists("res://assets/art/game-icons.png"):
		return
	var source: Texture2D = load("res://assets/art/game-icons.png")
	# The generated sheet is not a mathematically aligned grid. Use individually
	# inspected bounds, including the bunny ears above the nominal second row.
	var regions := [Rect2(32, 24, 408, 398), Rect2(472, 46, 412, 365),
		Rect2(936, 22, 386, 414), Rect2(1372, 76, 382, 346),
		Rect2(40, 466, 410, 392), Rect2(506, 414, 358, 455),
		Rect2(918, 476, 390, 379), Rect2(1367, 457, 390, 399)]
	for i in range(8):
		var tex := AtlasTexture.new()
		tex.atlas = source
		tex.region = regions[i]
		cached_icons.append(tex)

func clear_page() -> void:
	switching = true
	dismiss_overlay()
	active_pointer = -2
	if is_instance_valid(game):
		game.checkpoint()
		game.cancel_pointer()
		remove_child(game)
		game.queue_free()
		game = null
	if is_instance_valid(ui):
		remove_child(ui)
		ui.queue_free()
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	safe_insets()
	switching = false
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), P.CREAM)
	# Restrained paper flecks are original vector decoration, never hit targets.
	for i in range(38):
		var point := Vector2(fposmod(i * 173.3 + 21, size.x), fposmod(i * 227.7 + 53, size.y))
		draw_circle(point, 1.4, Color(0.65, 0.48, 0.3, 0.07))

func panel(parent: Control, rect: Rect2, color: Color, radius: int = 26, border: Color = Color.TRANSPARENT) -> Panel:
	var item := Panel.new()
	item.position = rect.position
	item.size = rect.size
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_theme_stylebox_override("panel", P.box(color, radius, border, 4))
	parent.add_child(item)
	return item

func label(parent: Control, value: String, rect: Rect2, font_size: int = 28, color: Color = P.INK, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, strong: bool = false, wrapped: bool = false) -> Label:
	var item := Label.new()
	if wrapped:
		item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.text = value
	item.position = rect.position
	item.size = rect.size
	item.add_theme_font_override("font", title_font if strong else font)
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", color)
	item.horizontal_alignment = align
	item.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(item)
	return item

func button(parent: Control, value: String, rect: Rect2, callback: Callable, color: Color = P.PAPER, font_size: int = 27) -> Button:
	var item := Button.new()
	item.position = rect.position
	item.size = rect.size
	item.text = value
	item.add_theme_font_override("font", title_font)
	item.add_theme_font_size_override("font_size", font_size)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		item.add_theme_color_override(state, P.INK)
	item.add_theme_stylebox_override("normal", P.box(color, 24, P.LINE, 3))
	item.add_theme_stylebox_override("hover", P.box(color.lightened(0.06), 24, P.LINE, 3))
	item.add_theme_stylebox_override("pressed", P.box(color.darkened(0.04), 22, P.LINE))
	item.add_theme_stylebox_override("focus", P.box(Color.TRANSPARENT, 24, P.MUTED))
	item.pivot_offset = rect.size * 0.5
	item.button_down.connect(func():
		if not Save.setting("reduced_motion"):
			item.scale = Vector2.ONE * 0.97)
	item.button_up.connect(func():
		item.scale = Vector2.ONE)
	item.pressed.connect(func():
		Sound.play(0)
		if OS.get_name() == "Android" and Save.setting("haptics"):
			Input.vibrate_handheld(12)
		callback.call())
	parent.add_child(item)
	return item

func illustration(parent: Control, texture: Texture2D, rect: Rect2) -> TextureRect:
	var item := TextureRect.new()
	item.texture = texture
	item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item.position = rect.position
	item.size = rect.size
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(item)
	return item

func show_home() -> void:
	clear_page()
	page = "home"
	current_index = -1
	Sound.suspend(false)
	var w := size.x
	var left := maxf(30.0, (w - 680) / 2.0)
	var content := w - left * 2
	label(ui, "MOCHI ARCADE", Rect2(left, top_safe, content - 92, 36), 23, P.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)
	button(ui, "☷", Rect2(w - left - 78, top_safe, 78, 78), show_settings, P.PAPER, 38)
	label(ui, C.words("A little pocket\nof play.", "装一口快乐，\n慢慢玩。"), Rect2(left, top_safe + 48, content * 0.66, 144), 51, P.INK, HORIZONTAL_ALIGNMENT_LEFT, true)
	if ResourceLoader.exists("res://assets/art/mochi-bunny.png"):
		illustration(ui, load("res://assets/art/mochi-bunny.png"), Rect2(w - left - 236, top_safe + 72, 244, 188))
	label(ui, C.words("Eight little ways to feel good", "八款小游戏，随时开启好心情"), Rect2(left, top_safe + 214, content, 38), 24, P.MUTED)
	var start_y := top_safe + 284
	var card_h := clampf((size.y - bottom_safe - start_y - 88) / 4.0 - 16, 156, 192)
	var card_w := (content - 20) / 2.0
	for i in range(8):
		var id := str(C.GAMES[i][0])
		var rect := Rect2(left + (i % 2) * (card_w + 20), start_y + (i / 2) * (card_h + 16), card_w, card_h)
		var card := button(ui, "", rect, func(): open_game(i), P.ACCENTS[i])
		label(card, "%02d" % (i + 1), Rect2(20, 12, 40, 28), 17, P.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)
		if cached_icons.size() == 8:
			illustration(card, cached_icons[i], Rect2(88, 0, card_w - 96, card_h - 59))
		label(card, C.title(i), Rect2(20, card_h - 69, card_w - 40, 36), 27, P.INK, HORIZONTAL_ALIGNMENT_LEFT, true)
		var summary := C.subtitle(i) if Save.best(id) == 0 else C.words("Best  ", "纪录  ") + str(Save.best(id))
		label(card, summary, Rect2(20, card_h - 34, card_w - 40, 25), 19, P.MUTED)
	label(ui, C.words("ALL YOURS  ·  OFFLINE  ·  NO HURRY", "随心玩  ·  离线可用  ·  不必着急"), Rect2(left, size.y - bottom_safe - 46, content, 32), 18, P.MUTED, HORIZONTAL_ALIGNMENT_CENTER)

func show_settings() -> void:
	clear_page()
	page = "settings"
	button(ui, "‹", Rect2(36, top_safe, 80, 80), show_home, P.PAPER, 46)
	label(ui, C.words("Make yourself comfy", "选一种舒服的方式"), Rect2(40, top_safe + 118, size.x - 80, 64), 40, P.INK, HORIZONTAL_ALIGNMENT_LEFT, true)
	label(ui, C.words("Little things, just the way you like.", "让这些小细节，合你的心意。"), Rect2(40, top_safe + 188, size.x - 80, 44), 24, P.MUTED)
	var rows := [["music", "Soft music", "轻柔音乐"], ["sfx", "Little sounds", "游戏音效"], ["reduced_motion", "Less motion", "减少动态效果"], ["haptics", "Gentle vibration", "轻微振动"]]
	for i in range(rows.size()):
		var row: Array = rows[i]
		var y := top_safe + 282 + i * 106
		panel(ui, Rect2(36, y, size.x - 72, 88), P.PAPER)
		label(ui, C.words(row[1], row[2]), Rect2(58, y + 10, size.x - 260, 68), 29)
		button(ui, C.words("On", "开") if Save.setting(row[0]) else C.words("Off", "关"), Rect2(size.x - 168, y + 8, 112, 72), func():
			Save.set_setting(row[0], not Save.setting(row[0]))
			Sound.apply_settings()
			show_settings(), P.MINT if Save.setting(row[0]) else P.CREAM)
	button(ui, C.words("Language  ·  English", "语言  ·  简体中文"), Rect2(36, top_safe + 734, size.x - 72, 88), func():
		Save.set_setting("language", "zh" if Save.setting("language") == "en" else "en")
		show_settings(), P.LILAC)
	button(ui, C.words("Reset my records", "重置我的纪录"), Rect2(36, top_safe + 858, size.x - 72, 88), confirm_reset, P.CREAM)
	label(ui, "Mochi Arcade  ·  " + str(ProjectSettings.get_setting("application/config/version")), Rect2(36, size.y - bottom_safe - 60, size.x - 72, 40), 22, P.MUTED, HORIZONTAL_ALIGNMENT_CENTER)

func confirm_reset() -> void:
	show_dialog(C.words("A fresh little start?", "重新开始？"), C.words("This clears game progress and records. Your sound and comfort settings stay.", "这会清除游戏进度和纪录，保留声音等偏好设置。"), [[C.words("Keep my records", "保留纪录"), dismiss_overlay], [C.words("Yes, reset records", "确认重置"), func(): Save.reset_records(); dismiss_overlay()]])

func open_game(index: int, fresh: bool = false) -> void:
	var id := str(C.GAMES[index][0])
	var scene_path := "res://scenes/games/" + id + ".tscn"
	if not ResourceLoader.exists(scene_path):
		show_dialog(C.title(index), C.words("This game is being lovingly made. This development build is not the finished collection.", "这款游戏正在制作中，当前为开发版本。"), [[C.words("Back to my pocket", "回到首页"), dismiss_overlay]])
		return
	clear_page()
	page = "game"
	current_index = index
	if fresh:
		Save.clear_session(id)
	var packed: PackedScene = load(scene_path)
	game = packed.instantiate()
	layout_shell()
	game.setup(id, play_rect.size, font)
	game.position = play_rect.position
	game.score_changed.connect(update_score)
	game.ended.connect(show_result)
	game.toast_requested.connect(toast)
	add_child(game)
	move_child(game, 0)
	update_score(game.score)
	if not Save.data.seen.get(id, false):
		Save.data.seen[id] = true
		Save.flush()
		show_help()

func layout_shell() -> void:
	if is_instance_valid(ui):
		for child in ui.get_children():
			ui.remove_child(child)
			child.queue_free()
	safe_insets()
	button(ui, "‹", Rect2(30, top_safe, 78, 78), leave_game, P.PAPER, 44)
	button(ui, "Ⅱ", Rect2(size.x - 108, top_safe, 78, 78), show_pause, P.PAPER, 28)
	label(ui, C.title(current_index), Rect2(116, top_safe, size.x - 232, 44), 33, P.INK, HORIZONTAL_ALIGNMENT_CENTER, true)
	label(ui, C.subtitle(current_index), Rect2(112, top_safe + 46, size.x - 224, 32), 19, P.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	var half := (size.x - 82) / 2.0
	panel(ui, Rect2(30, top_safe + 104, half, 88), P.PAPER)
	panel(ui, Rect2(52 + half, top_safe + 104, half, 88), P.ACCENTS[current_index])
	label(ui, C.words("BEST", "最高纪录"), Rect2(50, top_safe + 115, half - 40, 24), 17, P.MUTED)
	label(ui, C.words("THIS ROUND", "本局成绩"), Rect2(72 + half, top_safe + 115, half - 40, 24), 17, P.MUTED)
	best_label = label(ui, str(Save.best(C.GAMES[current_index][0])), Rect2(50, top_safe + 143, half - 40, 36), 31, P.INK, HORIZONTAL_ALIGNMENT_LEFT, true)
	score_label = label(ui, str(game.score if is_instance_valid(game) else 0), Rect2(72 + half, top_safe + 143, half - 40, 36), 31, P.INK, HORIZONTAL_ALIGNMENT_LEFT, true)
	play_rect = Rect2(36, top_safe + 218, size.x - 72, size.y - top_safe - bottom_safe - 330)
	if is_instance_valid(game) and game.is_inside_tree():
		var factor := minf(play_rect.size.x / game.area.x, play_rect.size.y / game.area.y)
		game.scale = Vector2.ONE * factor
		game.position = play_rect.position + (play_rect.size - game.area * factor) * 0.5
	var y := size.y - bottom_safe - 84
	button(ui, C.words("How to play", "怎么玩"), Rect2(30, y, 214, 76), show_help, P.PAPER, 24)
	var action_name := C.words("Undo", "撤回") if current_index in [4, 6] else C.words("Restart", "重开")
	button(ui, action_name, Rect2(254, y, size.x - 284, 76), func():
		if current_index in [4, 6]:
			game.action("undo")
		else:
			confirm_restart(), P.ACCENTS[current_index], 25)

func update_score(value: int) -> void:
	if is_instance_valid(score_label):
		score_label.text = str(value)
	if is_instance_valid(best_label) and current_index >= 0:
		best_label.text = str(maxi(value, Save.best(C.GAMES[current_index][0])))

func pause_game(value: bool) -> void:
	active_pointer = -2
	if is_instance_valid(game):
		game.set_suspended(value)
		game.checkpoint()
	Sound.suspend(value)

func leave_game() -> void:
	pause_game(true)
	show_home()

func show_pause() -> void:
	if not is_instance_valid(game) or game.stopped:
		return
	pause_game(true)
	show_dialog(C.words("Take a little breath", "歇一小会儿"), C.words("Your game is right here when you're ready.", "准备好了就继续，游戏在这里等你。"), [[C.words("Keep playing", "继续游戏"), resume], [C.words("Start again", "重新开始"), restart], [C.words("Back to my pocket", "返回首页"), leave_game]])

func show_help() -> void:
	pause_game(true)
	show_dialog(C.title(current_index), C.help(current_index), [[C.words("Let's play", "开始玩吧"), resume]])

func confirm_restart() -> void:
	pause_game(true)
	show_dialog(C.words("Another little go?", "再来一局？"), C.words("Start a fresh round. Your best is already saved.", "重新开始这一局，最高纪录已保存。"), [[C.words("Keep playing", "继续本局"), resume], [C.words("Start again", "重新开始"), restart]])

func resume() -> void:
	dismiss_overlay()
	pause_game(false)

func restart() -> void:
	var index := current_index
	Sound.suspend(false)
	open_game(index, true)

func show_result(message: String) -> void:
	show_dialog(C.words("A lovely little round", "又一局小快乐"), message + "\n" + C.words("Your score  ", "本局得分  ") + str(game.score), [[C.words("One more go", "再玩一次"), restart], [C.words("Back to my pocket", "返回首页"), leave_game]])

func show_dialog(title: String, body: String, actions: Array) -> void:
	dismiss_overlay()
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.26, 0.2, 0.15, 0.25)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var h := 352.0 + actions.size() * 96.0
	var w := minf(size.x - 64, 624)
	var box := panel(overlay, Rect2((size.x - w) / 2.0, (size.y - h) / 2.0, w, h), P.PAPER, 36, P.LINE)
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	label(box, title, Rect2(28, 28, w - 56, 70), 35, P.INK, HORIZONTAL_ALIGNMENT_CENTER, true)
	label(box, body, Rect2(36, 112, w - 72, 180), 27, P.MUTED, HORIZONTAL_ALIGNMENT_CENTER, false, true)
	for i in range(actions.size()):
		button(box, actions[i][0], Rect2(30, 320 + i * 96, w - 60, 78), actions[i][1], P.MINT if i == 0 else P.CREAM)

func dismiss_overlay() -> void:
	if is_instance_valid(overlay):
		remove_child(overlay)
		overlay.queue_free()
		overlay = null

func toast(message: String) -> void:
	if is_instance_valid(toast_label):
		toast_label.queue_free()
	if is_instance_valid(toast_tween):
		toast_tween.kill()
	toast_label = label(ui, message, Rect2(30, play_rect.end.y - 62, size.x - 60, 54), 25, P.INK, HORIZONTAL_ALIGNMENT_CENTER, true)
	toast_tween = create_tween()
	toast_tween.tween_interval(1.4)
	toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.3)

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT]:
		# Notifications may arrive while the tree is adding/removing children.
		# Defer both state and overlay changes to keep a paused run recoverable.
		if is_inside_tree() and not lifecycle_suspend_pending:
			lifecycle_suspend_pending = true
			_suspend_from_lifecycle.call_deferred()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if page != "game":
			Sound.suspend(false)
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		back()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_instance_valid(game):
			game.checkpoint()
		Save.flush()
		get_tree().quit()

func _suspend_from_lifecycle() -> void:
	lifecycle_suspend_pending = false
	if page == "game" and is_instance_valid(game) and game.is_inside_tree() and not game.stopped:
		pause_game(true)
		if not is_instance_valid(overlay):
			show_pause()
	Sound.suspend(true)

func back() -> void:
	if is_instance_valid(overlay):
		if is_instance_valid(game) and not game.stopped:
			resume()
		elif is_instance_valid(game):
			leave_game()
		else:
			dismiss_overlay()
	elif page == "game":
		show_pause()
	elif page == "settings":
		show_home()
	else:
		show_dialog(C.words("See you in a little while?", "下次再一起玩？"), C.words("Your records are tucked away safely.", "你的纪录已经妥善保存。"), [[C.words("Stay here", "再玩一会儿"), dismiss_overlay], [C.words("Close the app", "退出应用"), func(): get_tree().quit()]])

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		back()
		get_viewport().set_input_as_handled()
		return
	# An owned gesture must terminate even when released over a UI control.
	if active_pointer != -2 and is_instance_valid(game) and not game.suspended:
		if event is InputEventScreenTouch and event.index == active_pointer and not event.pressed:
			game.release(game.to_local(event.position))
			active_pointer = -2
			get_viewport().set_input_as_handled()
		elif event is InputEventScreenDrag and event.index == active_pointer:
			game.drag(game.to_local(event.position))
		elif event is InputEventMouseButton and event.device != -1 and active_pointer == -1 and not event.pressed:
			game.release(game.to_local(event.position))
			active_pointer = -2
			get_viewport().set_input_as_handled()
		elif event is InputEventMouseMotion and event.device != -1 and active_pointer == -1:
			game.drag(game.to_local(event.position))

func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(game) or is_instance_valid(overlay) or game.stopped or game.suspended:
		return
	if event is InputEventScreenTouch and event.pressed and active_pointer == -2 and play_rect.has_point(event.position):
		active_pointer = event.index
		game.press(game.to_local(event.position))
	elif event is InputEventMouseButton and event.device != -1 and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and active_pointer == -2 and play_rect.has_point(event.position):
		active_pointer = -1
		game.press(game.to_local(event.position))
	elif event is InputEventKey and event.pressed and not event.echo:
		game.action(OS.get_keycode_string(event.keycode).to_lower())
