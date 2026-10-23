extends MochiGame

const P := preload("res://scripts/shared/palette.gd")
const RULES := preload("res://scripts/games/trio_rules.gd")
var tiles: Array[Dictionary] = []
var mask := 0
var tray: Array = []
var stage := 1
var history: Array[Dictionary] = []
var board_origin := Vector2.ZERO
var icons: Array[Texture2D] = []
var animation: Dictionary = {}
var pending_loss := false
var clear_time := 0.0
var hint_id := -1
var hint_status := ""
var matches := 0
var picks := 0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	board_origin = Vector2((area.x - RULES.BOARD_SIZE.x) / 2, 120)
	load_art()
	var saved := Save.session(game_id)
	stage = maxi(1, int(saved.get("stage", 1)))
	build_level()
	var restored := decode_state(saved)
	if not restored.is_empty():
		mask = restored.mask
		tray = restored.tray
		score = restored.score
		var saved_history = saved.get("history", [])
		if saved_history is Array:
			for item in saved_history.slice(-36):
				var state := decode_state(item)
				if not state.is_empty() and state.score <= score:
					history.append(state)
	if mask == 0 and tray.is_empty():
		stage += 1
		build_level()
	elif tray.size() >= RULES.CAPACITY:
		pending_loss = true
	checkpoint()

func load_art() -> void:
	if not ResourceLoader.exists("res://assets/art/trio-icons.png"):
		return
	var sheet: Texture2D = load("res://assets/art/trio-icons.png")
	var regions := [Rect2(48, 42, 392, 382), Rect2(524, 44, 304, 378),
		Rect2(912, 104, 412, 294), Rect2(1366, 54, 370, 354),
		Rect2(38, 460, 422, 362), Rect2(458, 466, 436, 354),
		Rect2(910, 468, 418, 352), Rect2(1358, 457, 382, 372)]
	for region in regions:
		var texture := AtlasTexture.new()
		texture.atlas = sheet
		texture.region = region
		icons.append(texture)

func build_level() -> void:
	var board := RULES.generate(run_seed, stage)
	tiles = board.tiles
	mask = board.mask
	tray.clear()
	history.clear()
	animation.clear()
	pending_loss = false
	clear_time = 0
	hint_id = -1
	queue_redraw()

func decode_state(value: Variant) -> Dictionary:
	if not value is Dictionary or not value.get("tray") is Array or not value.has("mask"):
		return {}
	var restored_mask := int(value.mask)
	if not RULES.valid_state(tiles, restored_mask, value.tray):
		return {}
	var restored_tray: Array = []
	for id in value.tray:
		restored_tray.append(int(id))
	return {"mask": restored_mask, "tray": restored_tray, "score": maxi(0, int(value.get("score", 0)))}

func tile_rect(id: int) -> Rect2:
	var rect: Rect2 = tiles[id].rect
	return Rect2(rect.position + board_origin, rect.size)

func tray_rect(slot: int) -> Rect2:
	return Rect2((area.x - 554) / 2 + slot * 80, area.y - 168, 74, 84)

func press(point: Vector2) -> void:
	if stopped or suspended or not animation.is_empty() or clear_time > 0:
		return
	for id in range(tiles.size() - 1, -1, -1):
		if (mask & (1 << id)) != 0 and tile_rect(id).has_point(point):
			if RULES.selectable(tiles, mask, id):
				choose(id)
			else:
				toast_requested.emit(MochiCatalog.words("Uncover this tile first", "先移开上面的图块吧"))
			return

func choose(id: int) -> void:
	if stopped or suspended or not animation.is_empty() or clear_time > 0:
		return
	var move := RULES.take(tiles, mask, tray, id)
	if not move.valid:
		return
	history.append({"mask": mask, "tray": tray.duplicate(), "score": score})
	if history.size() > 36:
		history.pop_front()
	animation = {"id": id, "from": tile_rect(id).get_center(), "to": tray_rect(move.insert_index).get_center(), "time": 0.0, "matched": move.matched.size() == 3}
	mask = move.mask
	tray = move.tray
	picks += 1
	hint_id = -1
	if move.matched.size() == 3:
		matches += 1
		add_score(30)
		Sound.play(4)
	else:
		Sound.play(1)
	pending_loss = move.lost
	if move.won:
		add_score(60)
		clear_time = 0.85
		toast_requested.emit(MochiCatalog.words("A lovely tidy shop! +60", "收拾得真漂亮！+60"))
	checkpoint()
	queue_redraw()

func can_undo() -> bool:
	return not history.is_empty()

func action(name: String) -> void:
	if suspended:
		return
	if name == "undo":
		if history.is_empty():
			toast_requested.emit(MochiCatalog.words("Your tray is still fresh", "还没有需要撤回的图块"))
			return
		var state: Dictionary = history.pop_back()
		mask = state.mask
		tray = state.tray
		score = state.score
		stopped = false
		animation.clear()
		pending_loss = false
		clear_time = 0
		hint_id = -1
		score_changed.emit(score)
		Sound.play(2)
		checkpoint()
	elif name == "hint" and not stopped and animation.is_empty() and clear_time <= 0:
		var result := RULES.solve(tiles, mask, tray, 8000)
		hint_status = result.status
		if result.status == "SOLVED" and not result.path.is_empty():
			hint_id = result.path[0]
			toast_requested.emit(MochiCatalog.words("Try the green-outlined tile", "试试绿色描边的图块"))
		else:
			hint_id = -1
			toast_requested.emit(MochiCatalog.words("Try Undo to open another path", "撤回一步，换条路试试吧"))
	queue_redraw()

func _process(delta: float) -> void:
	if stopped or suspended:
		return
	if animation.is_empty() and not pending_loss and clear_time <= 0 and particles.is_empty():
		return
	if not animation.is_empty():
		animation.time += delta
		if animation.time >= 0.18:
			if animation.matched:
				burst(animation.to, P.MINT, 12)
			animation.clear()
	if pending_loss and animation.is_empty():
		finish(MochiCatalog.words("Your tray is full. Undo a tile or enjoy a fresh start.", "托盘满啦。撤回一步，或轻松再来一局吧。"))
	if clear_time > 0:
		clear_time -= delta
		if clear_time <= 0:
			stage += 1
			build_level()
			checkpoint()
	step_effects(delta)
	queue_redraw()

func draw_tile(id: int, rect: Rect2, blocked: bool = false, alpha: float = 1.0) -> void:
	var color := Color("e2ded0") if blocked else P.PAPER
	color.a = alpha
	var shadow := Color(0.65, 0.55, 0.41, 0.7 * alpha)
	rounded(Rect2(rect.position + Vector2(0, 5), rect.size), shadow, 12)
	var surface := P.box(color, 12, Color("709a72") if id == hint_id else P.LINE)
	surface.set_border_width_all(4 if id == hint_id else 2)
	draw_style_box(surface, rect)
	if icons.size() == 8:
		var icon: Texture2D = icons[tiles[id].kind]
		var factor := minf((rect.size.x - 18) / icon.get_width(), (rect.size.y - 18) / icon.get_height())
		var dimensions := icon.get_size() * factor
		draw_texture_rect(icon, Rect2(rect.get_center() - dimensions / 2, dimensions), false, Color(0.65, 0.65, 0.6, alpha * 0.65) if blocked else Color(1, 1, 1, alpha))
	else:
		text_at(str(tiles[id].kind + 1), rect.get_center() + Vector2(0, 12), 32, P.INK, true)
	if id == hint_id:
		draw_circle(rect.position + Vector2(10, 10), 5, Color("6f9e73"))

func _draw() -> void:
	rounded(Rect2(Vector2.ZERO, area), Color("f3f2e7"), 30)
	text_at(MochiCatalog.words("LITTLE SHOP ", "小铺 ") + str(stage), Vector2(area.x / 2, 38), 22, P.MUTED, true)
	var left := 0
	for tile in tiles:
		if (mask & (1 << int(tile.id))) != 0:
			left += 1
			draw_tile(tile.id, tile_rect(tile.id), not RULES.selectable(tiles, mask, tile.id))
	text_at(str(left) + MochiCatalog.words(" little things to tidy", " 件小物，慢慢收拾"), Vector2(area.x / 2, 76), 21, P.MUTED, true)
	text_at(MochiCatalog.words("YOUR LITTLE TRAY", "你的小托盘"), Vector2(area.x / 2, area.y - 198), 20, P.MUTED, true)
	for slot in range(RULES.CAPACITY):
		var rect := tray_rect(slot)
		rounded(rect, Color("e4e1d1"), 12)
		if slot < tray.size() and (animation.is_empty() or tray[slot] != animation.id):
			draw_tile(tray[slot], rect)
	if not animation.is_empty():
		var progress := clampf(animation.time / 0.18, 0, 1)
		var point: Vector2 = animation.from.lerp(animation.to, 1 - pow(1 - progress, 3))
		var dimensions := RULES.TILE_SIZE.lerp(Vector2(74, 84), progress)
		draw_tile(animation.id, Rect2(point - dimensions / 2, dimensions), false, 1 - progress * 0.5 if animation.matched else 1.0)
	text_at(MochiCatalog.words("Three alike make a little space", "三个相同，就能腾出一点空间"), Vector2(area.x / 2, area.y - 35), 22, P.MUTED, true)
	draw_effects()

func checkpoint() -> void:
	if stopped or tiles.is_empty():
		return
	var snapshots: Array = []
	for state in history:
		snapshots.append({"mask": str(state.mask), "tray": state.tray, "score": state.score})
	Save.save_session(game_id, {"stage": stage, "mask": str(mask), "tray": tray, "score": score,
		"history": snapshots, "seed": run_seed})
