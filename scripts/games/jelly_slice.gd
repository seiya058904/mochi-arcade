extends MochiGame

const P := preload("res://scripts/shared/palette.gd")
const SWEEP := preload("res://scripts/shared/sweep.gd")
const MAX_FRUIT := 12
const MAX_HALVES := 32
const MAX_TRAIL := 24
const GRAVITY := 640.0
const COMBO_WINDOW := 0.65
const COLORS := [Color("ed9fae"), Color("efbb79"), Color("aac87c"), Color("bca0d4")]
var fruit: Array[Dictionary] = []
var halves: Array[Dictionary] = []
var trail: Array[Dictionary] = []
var sprites: Array[Texture2D] = []
var stroke := false
var last_point := Vector2.ZERO
var spawn_time := 0.3
var save_time := 0.0
var combo_time := 0.0
var combo := 0
var sliced := 0
var missed := 0
var launched := 0
var max_fruit := 0
var max_halves := 0
var serial := 0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	for i in range(MAX_FRUIT):
		fruit.append({"active": false, "p": Vector2.ZERO, "origin": Vector2.ZERO, "v0": Vector2.ZERO, "age": 0.0, "r": 46.0, "kind": 0, "angle": 0.0, "spin": 0.0, "serial": 0})
	for i in range(MAX_HALVES):
		halves.append({"active": false, "p": Vector2.ZERO, "v": Vector2.ZERO, "age": 0.0, "r": 46.0, "sprite": 0, "angle": 0.0, "spin": 0.0})
	load_art()
	restore(Save.session(game_id))
	checkpoint()

func load_art() -> void:
	if not ResourceLoader.exists("res://assets/art/jelly-fruit.png"):
		return
	var atlas: Texture2D = load("res://assets/art/jelly-fruit.png")
	# Bounds were inspected separately: equal grid cells would clip whole fruit
	# into the adjacent half. Cropping preserves each half's natural proportions.
	var regions: Array[Rect2] = [
		Rect2(94, 67, 298, 293), Rect2(472, 62, 169, 298), Rect2(817, 67, 163, 293),
		Rect2(93, 403, 301, 307), Rect2(472, 400, 170, 310), Rect2(813, 400, 176, 309),
		Rect2(90, 755, 307, 295), Rect2(469, 754, 178, 295), Rect2(807, 755, 188, 294),
		Rect2(98, 1088, 294, 305), Rect2(466, 1090, 185, 299), Rect2(804, 1091, 188, 298)]
	for region in regions:
		var sprite := AtlasTexture.new()
		sprite.atlas = atlas
		sprite.region = region
		sprites.append(sprite)

func active_count(items: Array[Dictionary]) -> int:
	var count := 0
	for item in items:
		if item.active:
			count += 1
	return count

func spawn_one(kind: int, point: Vector2, velocity: Vector2, radius: float = 46.0) -> int:
	for i in range(MAX_FRUIT):
		if not fruit[i].active:
			serial += 1
			fruit[i].merge({"active": true, "p": point, "origin": point, "v0": velocity, "age": 0.0, "r": radius, "kind": kind, "angle": rng.randf_range(-0.2, 0.2), "spin": rng.randf_range(-0.7, 0.7), "serial": serial}, true)
			launched += 1
			max_fruit = maxi(max_fruit, active_count(fruit))
			return i
	return -1

func spawn_group() -> void:
	var count := rng.randi_range(2, 4)
	for i in range(count):
		var radius := rng.randf_range(42, 51)
		var point := Vector2(rng.randf_range(65, area.x - 65), area.y + radius)
		var apex := rng.randf_range(maxf(145, area.y * 0.25), area.y * 0.48)
		var velocity := Vector2((area.x / 2 - point.x) * 0.33 + rng.randf_range(-85, 85), -sqrt(2 * GRAVITY * (point.y - apex)))
		spawn_one(rng.randi_range(0, 3), point, velocity, radius)

func press(point: Vector2) -> void:
	if stopped or suspended or not point.is_finite():
		return
	stroke = true
	last_point = point
	trail.clear()
	append_trail(point)

func append_trail(point: Vector2) -> void:
	if reduced_motion:
		return
	if trail.size() == MAX_TRAIL:
		trail.pop_front()
	trail.append({"p": point, "life": 0.22})

func drag(point: Vector2) -> void:
	if not stroke or stopped or suspended or not point.is_finite():
		return
	if point.distance_squared_to(last_point) < 4:
		return
	var hits: Array[Dictionary] = []
	for i in range(MAX_FRUIT):
		if fruit[i].active:
			var t := SWEEP.circle(last_point, point, fruit[i].p, fruit[i].r)
			if t <= 1:
				hits.append({"id": i, "t": t})
	hits.sort_custom(func(a: Dictionary, b: Dictionary): return a.t < b.t if not is_equal_approx(a.t, b.t) else a.id < b.id)
	var direction := (point - last_point).normalized()
	for hit in hits:
		slice_one(hit.id, direction)
	last_point = point
	append_trail(point)
	queue_redraw()

func release(point: Vector2) -> void:
	drag(point)
	stroke = false

func cancel_pointer() -> void:
	super.cancel_pointer()
	stroke = false
	trail.clear()

func add_half(item: Dictionary, side: int, direction: Vector2) -> void:
	var slot := -1
	var oldest := -1.0
	for i in range(MAX_HALVES):
		if not halves[i].active:
			slot = i
			break
		if halves[i].age > oldest:
			oldest = halves[i].age
			slot = i
	var sign_x := -1 if side == 0 else 1
	halves[slot].merge({"active": true, "p": item.p + Vector2(sign_x * item.r * 0.3, 0),
		"v": Vector2(sign_x * 115, -95) + direction * 38, "age": 0.0, "r": item.r,
		"sprite": item.kind * 3 + 1 + side, "angle": item.angle,
		"spin": sign_x * (0.45 if reduced_motion else 2.0)}, true)
	max_halves = maxi(max_halves, active_count(halves))

func slice_one(index: int, direction: Vector2) -> void:
	var item := fruit[index]
	if not item.active:
		return
	# Claim before score, particles, halves or signals; re-entrant/overlapping input
	# cannot collect the same fruit twice.
	item.active = false
	sliced += 1
	combo = mini(5, combo + 1) if combo_time > 0 else 1
	combo_time = COMBO_WINDOW
	add_score(10 + (combo - 1) * 5)
	for side in range(2):
		add_half(item, side, direction)
	burst(item.p, COLORS[item.kind], 9)
	Sound.play(mini(7, 2 + combo))

func add_score(value: int) -> void:
	score += value
	Save.data.records[game_id] = maxi(score, Save.best(game_id))
	score_changed.emit(score)

func action(name: String) -> void:
	if name == "finish" and not stopped and not suspended:
		finish(MochiCatalog.words("A soft little pause. ", "轻轻松松的小憩。") + str(sliced) + MochiCatalog.words(" jellies sliced.", " 颗果冻被切开啦。"))

func _physics_process(delta: float) -> void:
	if stopped or suspended:
		return
	spawn_time -= delta
	if spawn_time <= 0:
		spawn_group()
		spawn_time = rng.randf_range(0.9, 1.35)
	combo_time = maxf(0, combo_time - delta)
	if combo_time <= 0:
		combo = 0
	for item in fruit:
		if not item.active:
			continue
		item.age += delta
		item.p = item.origin + item.v0 * item.age + Vector2(0, GRAVITY * item.age * item.age / 2)
		if not reduced_motion:
			item.angle += item.spin * delta
		var descending: bool = item.v0.y + GRAVITY * item.age > 0
		if item.age > 6 or (descending and item.p.y > area.y + item.r * 2) or item.p.x < -150 or item.p.x > area.x + 150:
			item.active = false
			missed += 1
	for half in halves:
		if not half.active:
			continue
		half.age += delta
		half.v.y += GRAVITY * delta
		half.p += half.v * delta
		half.angle += half.spin * delta
		if half.age >= 1.3 or half.p.y > area.y + 100:
			half.active = false
	for i in range(trail.size() - 1, -1, -1):
		trail[i].life -= delta
		if trail[i].life <= 0:
			trail.remove_at(i)
	save_time += delta
	if save_time >= 2:
		checkpoint()
	step_effects(delta)
	queue_redraw()

func checkpoint() -> void:
	if stopped:
		return
	save_time = 0
	var items: Array = []
	for item in fruit:
		if item.active:
			items.append([item.kind, item.p.x / area.x, item.p.y / area.y, item.v0.x, item.v0.y + GRAVITY * item.age, item.r, item.angle, item.spin])
	Save.save_session(game_id, {"seed": run_seed, "rng": str(rng.state), "score": score, "sliced": sliced, "missed": missed, "launched": launched, "fruit": items, "spawn_time": spawn_time})

func restore(saved: Dictionary) -> void:
	if saved.is_empty():
		return
	score = maxi(0, int(saved.get("score", 0)))
	sliced = maxi(0, int(saved.get("sliced", 0)))
	missed = maxi(0, int(saved.get("missed", 0)))
	var items: Variant = saved.get("fruit", [])
	if items is Array and items.size() <= MAX_FRUIT:
		for entry in items:
			if not entry is Array or entry.size() != 8:
				continue
			var valid := true
			for value in entry:
				if not (value is int or value is float) or not is_finite(float(value)):
					valid = false
			if not valid or entry[1] < -0.25 or entry[1] > 1.25 or entry[2] < -0.3 or entry[2] > 1.3:
				continue
			var id := spawn_one(clampi(int(entry[0]), 0, 3), Vector2(entry[1] * area.x, entry[2] * area.y), Vector2(clampf(entry[3], -500, 500), clampf(entry[4], -1400, 1400)), clampf(entry[5], 42, 51))
			fruit[id].angle = entry[6]
			fruit[id].spin = entry[7]
	launched = maxi(sliced + missed + active_count(fruit), int(saved.get("launched", 0)))
	rng.state = int(saved.get("rng", str(rng.state)))
	spawn_time = clampf(float(saved.get("spawn_time", 0.3)), 0.05, 1.35)
	# Restarting a process never restores a held finger or an expired combo.
	combo = 0
	combo_time = 0

func draw_piece(index: int, point: Vector2, radius: float, angle: float, alpha: float = 1.0) -> void:
	draw_set_transform(point, angle)
	if sprites.size() == 12:
		var texture := sprites[index]
		var size := Vector2(radius * 2 * texture.get_width() / texture.get_height(), radius * 2)
		draw_texture_rect(texture, Rect2(-size / 2, size), false, Color(1, 1, 1, alpha))
	else:
		draw_circle(Vector2.ZERO, radius, Color(COLORS[index / 3], alpha))
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	rounded(Rect2(Vector2.ZERO, area), Color("f7e9e2"), 30)
	text_at(MochiCatalog.words("ZEN BREAK", "禅意小憩"), Vector2(34, 40), 21, P.MUTED)
	text_at(str(sliced) + MochiCatalog.words(" SLICED", " 颗切开"), Vector2(area.x - 166, 40), 21, P.MUTED)
	for i in range(8):
		var point := Vector2(52 + fposmod(i * 163, area.x - 104), 130 + fposmod(i * 211, area.y - 240))
		draw_circle(point, 5 + i % 3, Color(1, 1, 1, 0.32))
	if combo >= 2 and combo_time > 0:
		rounded(Rect2(area.x / 2 - 92, 66, 184, 42), P.PAPER, 21)
		text_at(MochiCatalog.words("SWEET ×", "甜蜜连切 ×") + str(combo), Vector2(area.x / 2, 95), 23, P.INK, true)
	for item in fruit:
		if item.active:
			draw_piece(item.kind * 3, item.p, item.r, item.angle)
	for half in halves:
		if half.active:
			draw_piece(half.sprite, half.p, half.r, half.angle, minf(1, (1.3 - half.age) / 0.25))
	draw_effects()
	for i in range(1, trail.size()):
		var alpha: float = trail[i].life / 0.22
		draw_line(trail[i - 1].p, trail[i].p, Color(1, 1, 1, alpha * 0.9), 9 * alpha + 1, true)
	text_at(MochiCatalog.words("No rush. Just a little slice of joy.", "不着急，划开一点点快乐。"), Vector2(area.x / 2, area.y - 24), 20, P.MUTED, true)
