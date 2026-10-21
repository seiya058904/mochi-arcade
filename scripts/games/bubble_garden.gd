extends MochiGame

const P := preload("res://scripts/shared/palette.gd")
const RULES := preload("res://scripts/games/bubble_rules.gd")
const RADIUS := 30.0
const COLORS := [Color("edbdc4"), Color("b9d8e9"), Color("f0d58f"), Color("b8d4a5"), Color("cdbce2")]
var grid: Dictionary = {}
var stage := 1
var shot_color := 0
var next_color := 0
var aim := Vector2(0, -1)
var origin := Vector2.ZERO
var flying := false
var projectile := Vector2.ZERO
var velocity := Vector2.ZERO
var aim_path := PackedVector2Array()
var falling: Array[Dictionary] = []
var sprites: Array[Texture2D] = []
var missed := 0
var reload_time := 0.0
var shots := 0
var popped_count := 0
var dropped_count := 0
var bounce_count := 0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	origin = Vector2(area.x / 2, area.y - 82)
	load_art()
	var saved := Save.session(game_id)
	stage = maxi(1, int(saved.get("stage", 1)))
	score = int(saved.get("score", 0))
	if saved.has("grid") and saved.grid is Array and not saved.grid.is_empty():
		for tile in saved.grid:
			if tile is Array and tile.size() == 3:
				var cell := Vector2i(int(tile[0]), int(tile[1]))
				if cell.x >= 0 and cell.x < RULES.COLS and cell.y >= 0 and cell.y < RULES.ROWS:
					grid[cell] = clampi(int(tile[2]), 0, 4)
		shot_color = int(saved.get("shot", 0))
		next_color = int(saved.get("next", 0))
		missed = int(saved.get("missed", 0))
		rng.state = int(saved.get("rng", str(rng.state)))
		refresh_colors(false)
	else:
		make_garden()
	update_aim()

func load_art() -> void:
	if not ResourceLoader.exists("res://assets/art/bubble-characters.png"):
		return
	var atlas: Texture2D = load("res://assets/art/bubble-characters.png")
	# Production sheet has vertical transparent space; inspected circular bounds.
	var regions := [Rect2(10, 187, 398, 398), Rect2(405, 187, 398, 398),
		Rect2(799, 187, 398, 398), Rect2(1193, 187, 398, 398), Rect2(1578, 187, 398, 398)]
	for i in range(5):
		var sprite := AtlasTexture.new()
		sprite.atlas = atlas
		sprite.region = regions[i]
		sprites.append(sprite)

func cell_position(cell: Vector2i) -> Vector2:
	var width := (RULES.COLS * 2 + 1) * RADIUS
	return Vector2((area.x - width) / 2 + RADIUS + cell.x * 2 * RADIUS + (RADIUS if cell.y % 2 else 0.0), 80 + cell.y * RADIUS * sqrt(3.0))

func make_garden() -> void:
	grid.clear()
	missed = 0
	var rows := mini(6, 3 + stage / 3)
	var color_count := mini(5, 3 + stage / 6)
	# Short coherent color patches; all rows are roof-connected at start.
	var offset := rng.randi_range(0, color_count - 1)
	for row in range(rows):
		for col in range(RULES.COLS):
			grid[Vector2i(col, row)] = (col / 3 + row / 2 + offset) % color_count
	refresh_colors(true)
	update_aim()
	checkpoint()

func refresh_colors(advance: bool) -> void:
	var pool := RULES.colors(grid)
	if pool.is_empty():
		return
	if advance:
		shot_color = next_color if next_color in pool else pool[rng.randi_range(0, pool.size() - 1)]
	if not shot_color in pool:
		shot_color = pool[rng.randi_range(0, pool.size() - 1)]
	if advance or not next_color in pool:
		next_color = pool[rng.randi_range(0, pool.size() - 1)]

func collision(from: Vector2, to: Vector2) -> Dictionary:
	var result := {"time": INF, "kind": "none", "cell": Vector2i(-1, -1)}
	var movement := to - from
	var left := field_left()
	var right := area.x - left
	if to.x < left and movement.x < 0:
		result = {"time": (left - from.x) / movement.x, "kind": "wall", "cell": Vector2i(-1, -1)}
	elif to.x > right and movement.x > 0:
		result = {"time": (right - from.x) / movement.x, "kind": "wall", "cell": Vector2i(-1, -1)}
	if to.y < 80 and movement.y < 0:
		var t := (80 - from.y) / movement.y
		if t < result.time:
			result = {"time": t, "kind": "roof", "cell": Vector2i(-1, -1)}
	for cell in grid:
		var t := RULES.segment_circle(from, to, cell_position(cell), RADIUS * 2 - 0.5)
		if t < result.time:
			result = {"time": t, "kind": "bubble", "cell": cell}
	return result

func field_left() -> float:
	# Keep the walls beside the nine-column grid even on expanded wide viewports.
	return (area.x - (RULES.COLS * 2 + 1) * RADIUS) / 2 + RADIUS / 2

func snap_cell(point: Vector2, hit: Dictionary) -> Vector2i:
	var available: Array[Vector2i] = []
	if hit.kind == "roof":
		for x in range(RULES.COLS):
			if not grid.has(Vector2i(x, 0)):
				available.append(Vector2i(x, 0))
	else:
		for neighbor in RULES.neighbors(hit.cell):
			if not grid.has(neighbor):
				available.append(neighbor)
	var closest := Vector2i(-1, -1)
	var distance := INF
	for cell in available:
		var candidate := point.distance_squared_to(cell_position(cell))
		if candidate < distance:
			distance = candidate
			closest = cell
	return closest

func trace(direction: Vector2) -> Dictionary:
	var point := origin
	var heading := direction
	var path := PackedVector2Array([origin])
	for step in range(350):
		var next := point + heading * 12
		var hit := collision(point, next)
		if hit.time <= 1:
			point = point.lerp(next, hit.time)
			path.append(point)
			if hit.kind == "wall":
				heading.x *= -1
				point += heading * 0.1
			else:
				return {"path": path, "cell": snap_cell(point, hit)}
		else:
			point = next
			path.append(point)
	return {"path": path, "cell": Vector2i(-1, -1)}

func update_aim() -> void:
	aim_path = trace(aim).path
	queue_redraw()

func press(point: Vector2) -> void:
	if not flying and reload_time <= 0:
		drag(point)

func drag(point: Vector2) -> void:
	if flying or reload_time > 0 or point.y > origin.y - 60:
		return
	var angle := clampf((point - origin).angle(), -PI + 0.2, -0.2)
	aim = Vector2.from_angle(angle)
	update_aim()

func release(point: Vector2) -> void:
	if stopped or suspended or flying or reload_time > 0:
		return
	drag(point)
	flying = true
	projectile = origin
	velocity = aim * 1000
	shots += 1
	Sound.play(1)

func attach(cell: Vector2i) -> void:
	flying = false
	if cell.x < 0 or grid.has(cell):
		finish(MochiCatalog.words("The garden is full. Let's plant a fresh one.", "花园满啦，重新种一片吧。"))
		return
	grid[cell] = shot_color
	var matching := RULES.cluster(grid, cell)
	if matching.size() >= 3:
		for item in matching:
			burst(cell_position(item), COLORS[grid[item]], 4)
			grid.erase(item)
		popped_count += matching.size()
		var loose := RULES.floating(grid)
		for item in loose:
			falling.append({"p": cell_position(item), "v": Vector2(effects_rng.randf_range(-40, 40), 70), "color": grid[item]})
			grid.erase(item)
		dropped_count += loose.size()
		add_score(matching.size() * 10 + loose.size() * 20)
		missed = 0
		Sound.play(mini(7, 2 + loose.size()))
	else:
		missed += 1
	if grid.is_empty():
		stage += 1
		reload_time = 0.7
		toast_requested.emit(MochiCatalog.words("Lovely! A new garden is blooming.", "真漂亮！下一片花园要开花啦。"))
		add_score(100)
	else:
		refresh_colors(true)
		for item in grid:
			if cell_position(item).y + RADIUS >= origin.y - 72:
				finish(MochiCatalog.words("A full garden. Try a bounce or a helpful hint next time.", "花园长满啦，下次试试反弹或免费提示吧。"))
	update_aim()
	checkpoint()

func action(name: String) -> void:
	if name != "hint" or flying or stopped or suspended or reload_time > 0:
		return
	var best := -1
	var suggested := aim
	for step in range(65):
		var direction := Vector2.from_angle(-PI + 0.23 + step * (PI - 0.46) / 64)
		var result := trace(direction)
		if result.cell.x < 0:
			continue
		var copy := grid.duplicate()
		copy[result.cell] = shot_color
		var count := RULES.cluster(copy, result.cell).size()
		if count > best:
			best = count
			suggested = direction
	aim = suggested
	update_aim()
	toast_requested.emit(MochiCatalog.words("Tap near the launcher to follow this path", "点击发射器附近，沿这条路线发射"))

func _physics_process(delta: float) -> void:
	if stopped or suspended:
		return
	if reload_time > 0:
		reload_time -= delta
		if reload_time <= 0:
			make_garden()
	if flying:
		var remaining := delta
		for _bounce in range(4):
			var next := projectile + velocity * remaining
			var hit := collision(projectile, next)
			if hit.time > 1:
				projectile = next
				break
			projectile = projectile.lerp(next, hit.time)
			if hit.kind == "wall":
				velocity.x *= -1
				projectile += velocity.normalized() * 0.1
				remaining *= 1.0 - hit.time
				bounce_count += 1
			else:
				attach(snap_cell(projectile, hit))
				break
	for i in range(falling.size() - 1, -1, -1):
		falling[i].v.y += delta * 650
		falling[i].p += falling[i].v * delta
		if falling[i].p.y > area.y + 50:
			falling.remove_at(i)
	step_effects(delta)
	queue_redraw()

func bubble(point: Vector2, color_index: int, radius: float = RADIUS) -> void:
	if sprites.size() == 5:
		draw_texture_rect(sprites[color_index], Rect2(point - Vector2.ONE * radius, Vector2.ONE * radius * 2), false)
	else:
		draw_circle(point, radius, COLORS[color_index])
		draw_arc(point, radius - 4, PI * 1.1, PI * 1.55, 12, Color(1, 1, 1, 0.7), 3, true)
		text_at(["✿", "◇", "★", "♧", "♡"][color_index], point + Vector2(0, 10), 27, P.INK, true)

func _draw() -> void:
	rounded(Rect2(0, 0, area.x, area.y), Color("eef4ed"), 30)
	for wall in [field_left() - RADIUS, area.x - field_left() + RADIUS]:
		draw_line(Vector2(wall, 66), Vector2(wall, origin.y - 58), Color("dce7da"), 2, true)
	text_at(MochiCatalog.words("GARDEN ", "小花园 ") + str(stage), Vector2(area.x / 2, 36), 21, P.MUTED, true)
	for cell in grid:
		bubble(cell_position(cell), grid[cell])
	for item in falling:
		bubble(item.p, item.color)
	if not flying and reload_time <= 0:
		for i in range(0, aim_path.size(), 3):
			draw_circle(aim_path[i], 3.2, COLORS[shot_color].darkened(0.15))
		draw_line(origin, origin + aim * 70, P.INK, 6, true)
		bubble(origin, shot_color)
	elif flying:
		bubble(projectile, shot_color)
	rounded(Rect2(origin.x - 47, origin.y + 28, 94, 18), Color("c5b598"), 9)
	bubble(origin + Vector2(115, 16), next_color, 23)
	text_at(MochiCatalog.words("NEXT", "下一颗"), origin + Vector2(115, -20), 16, P.MUTED, true)
	text_at(MochiCatalog.words("Aim · release · bloom", "瞄准 · 松手 · 绽放"), Vector2(area.x / 2, area.y - 8), 20, P.MUTED, true)
	draw_effects()

func checkpoint() -> void:
	if stopped:
		return
	var cells: Array = []
	for cell in grid:
		cells.append([cell.x, cell.y, grid[cell]])
	Save.save_session(game_id, {"grid": cells, "stage": stage, "score": score, "shot": shot_color, "next": next_color, "missed": missed, "rng": str(rng.state), "seed": run_seed})
