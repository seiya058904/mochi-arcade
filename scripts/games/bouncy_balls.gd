extends MochiGame

const P := preload("res://scripts/shared/palette.gd")
const SWEEP := preload("res://scripts/shared/sweep.gd")
const MAX_BALLS := 64
# Player-feedback layout revision: the ball, brick wall, multiplier gates and
# bumpers were all too small on a portrait phone. The paddle keeps its exact
# width, height, y position and drag mapping; only the play-field objects grow.
const RADIUS := 16.0
const PADDLE_WIDTH := 172.0
const BRICK_COLUMNS := 4
const BRICK_ROWS := 6
const BRICK_GAP := 7.0
const BRICK_MARGIN := 26.0
const BRICK_HEIGHT := 44.0
const BRICK_TOP := 78.0
const BRICK_PITCH := 49.0
const GATE_SIZE := Vector2(150, 46)
const GATE_Y := [0.635, 0.76]
const BUMPER_RADIUS := 34.0
const COLORS := [P.ROSE, P.SKY, P.YELLOW, P.MINT, P.LILAC]
var pool: Array[Dictionary] = []
var bricks: Array[Dictionary] = []
var gates: Array[Rect2] = []
var bumpers: Array[Vector2] = []
var sprites: Array[Texture2D] = []
var paddle_x := 0.0
var wave := 1
var clear_time := 0.0
var save_time := 0.0
var sound_time := 0.0
var tick := 0
var max_active := 0
var gate_passes := [0, 0]
var denied := 0
var catches := 0
var brick_hits := 0
var bumper_hits := 0
var recycled := 0
var collision_limit_hits := 0
var gate_glow := [0.0, 0.0]

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	paddle_x = area.x / 2
	for i in range(MAX_BALLS):
		pool.append({"active": false, "p": Vector2.ZERO, "v": Vector2.ZERO, "gates": 0, "born": -1, "color": i % 5})
	var atlas: Texture2D = load("res://assets/art/bubble-characters.png")
	for x in [10, 405, 799, 1193, 1578]:
		var sprite := AtlasTexture.new()
		sprite.atlas = atlas
		sprite.region = Rect2(x, 187, 398, 398)
		sprites.append(sprite)
	gates.assign([
		Rect2(area.x * 0.28 - GATE_SIZE.x * 0.5, area.y * GATE_Y[0], GATE_SIZE.x, GATE_SIZE.y),
		Rect2(area.x * 0.72 - GATE_SIZE.x * 0.5, area.y * GATE_Y[1], GATE_SIZE.x, GATE_SIZE.y)])
	bumpers.assign([Vector2(area.x * 0.30, area.y * 0.50), Vector2(area.x * 0.70, area.y * 0.50)])
	if not restore(Save.session(game_id)):
		make_wave()
		spawn(Vector2(paddle_x, paddle_y() - 25), Vector2(0.34, -1).normalized() * speed(), 0)
	checkpoint()

func speed() -> float:
	return minf(540, 400 + (wave - 1) * 14)

func paddle_y() -> float:
	return area.y - 76

func paddle_rect() -> Rect2:
	return Rect2(paddle_x - PADDLE_WIDTH / 2, paddle_y(), PADDLE_WIDTH, 19)

func make_wave() -> void:
	bricks.clear()
	var width := (area.x - BRICK_MARGIN * 2.0 - BRICK_GAP * (BRICK_COLUMNS - 1)) / BRICK_COLUMNS
	for row in range(BRICK_ROWS):
		for col in range(BRICK_COLUMNS):
			var hp := 1 + mini(3, (wave - 1) / 2) + (1 if row == 0 else 0)
			bricks.append({"rect": Rect2(BRICK_MARGIN + col * (width + BRICK_GAP), BRICK_TOP + row * BRICK_PITCH, width, BRICK_HEIGHT), "hp": hp, "max": hp, "color": (row + col / 2 + wave) % 5})
	for ball in pool:
		ball.gates = 0
	clear_time = 0

func active_count() -> int:
	var count := 0
	for ball in pool:
		if ball.active:
			count += 1
	return count

func bricks_left() -> int:
	var count := 0
	for brick in bricks:
		if brick.hp > 0:
			count += 1
	return count

func spawn(point: Vector2, velocity: Vector2, seen_gates: int) -> int:
	for i in range(MAX_BALLS):
		if not pool[i].active:
			pool[i].merge({"active": true, "p": point, "v": safe_velocity(velocity), "gates": seen_gates, "born": tick}, true)
			max_active = maxi(max_active, active_count())
			return i
	return -1

func safe_velocity(value: Vector2) -> Vector2:
	var result := value.normalized() * speed() if value.length_squared() > 0.001 else Vector2(0.3, -1).normalized() * speed()
	# A shallow bumper/corner rebound must never become an endless horizontal orbit.
	if absf(result.y) < speed() * 0.26:
		result.y = speed() * 0.26 * (-1 if result.y <= 0 else 1)
		result.x = sqrt(speed() * speed() - result.y * result.y) * (-1 if result.x < 0 else 1)
	return result

func rebound(velocity: Vector2, normal: Vector2) -> Vector2:
	var result := safe_velocity(velocity.bounce(normal))
	# Enforcing a vertical minimum after a grazing curved hit can otherwise
	# steer back into the surface. Keep the anti-trap correction outward.
	if result.dot(normal) <= 0:
		result.y *= -1
		if result.dot(normal) <= 0:
			result = safe_velocity(normal)
	return result

func press(point: Vector2) -> void:
	drag(point)

func drag(point: Vector2) -> void:
	if stopped or suspended:
		return
	paddle_x = clampf(point.x, 18 + PADDLE_WIDTH / 2, area.x - 18 - PADDLE_WIDTH / 2)
	queue_redraw()

func add_score(value: int) -> void:
	# High-frequency collisions update memory immediately; the two-second and
	# lifecycle checkpoints atomically persist score and the corresponding rally.
	score += value
	Save.data.records[game_id] = maxi(score, Save.best(game_id))
	score_changed.emit(score)

func multiply(index: int, gate: int) -> void:
	var ball := pool[index]
	var bit := 1 << gate
	if ball.gates & bit:
		return
	ball.gates |= bit
	gate_passes[gate] += 1
	gate_glow[gate] = 0.4
	var old_velocity: Vector2 = ball.v
	var extra := gate + 1
	# Claim the gate before cloning. Children inherit claims and cannot recursively
	# multiply again while still intersecting the very same gate.
	for i in range(extra):
		var angle := 0.22 if extra == 1 else (-0.25 if i == 0 else 0.25)
		if spawn(ball.p, old_velocity.rotated(angle), ball.gates) < 0:
			denied += 1
			add_score(5)
	if extra == 1:
		ball.v = safe_velocity(old_velocity.rotated(-0.22))
	burst(ball.p, COLORS[gate + 2], 5)
	if sound_time <= 0:
		Sound.play(5 + gate)
		sound_time = 0.08

func collision(from: Vector2, to: Vector2, seen: int) -> Dictionary:
	var result := {"time": INF, "normal": Vector2.ZERO, "kind": "none", "id": -1}
	var movement := to - from
	for boundary in [[18 + RADIUS, Vector2.RIGHT, true], [area.x - 18 - RADIUS, Vector2.LEFT, true], [57 + RADIUS, Vector2.DOWN, false]]:
		var normal: Vector2 = boundary[1]
		if movement.dot(normal) >= -0.000001:
			continue
		var t: float = (boundary[0] - (from.x if boundary[2] else from.y)) / (movement.x if boundary[2] else movement.y)
		if t >= 0 and t <= 1 and t < result.time:
			result = {"time": t, "normal": normal, "kind": "wall", "id": -1}
	if movement.y > 0 and from.y <= paddle_y() - RADIUS + 0.1:
		var hit := SWEEP.rounded_box(from, to, paddle_rect(), RADIUS)
		if hit.time < result.time:
			result = {"time": hit.time, "normal": hit.normal, "kind": "paddle", "id": -1}
	for i in range(bricks.size()):
		if bricks[i].hp <= 0:
			continue
		var hit := SWEEP.rounded_box(from, to, bricks[i].rect, RADIUS)
		if hit.time < result.time:
			result = {"time": hit.time, "normal": hit.normal, "kind": "brick", "id": i}
	for i in range(bumpers.size()):
		var t := SWEEP.circle(from, to, bumpers[i], BUMPER_RADIUS + RADIUS)
		if t < result.time:
			var normal := (from.lerp(to, t) - bumpers[i]).normalized()
			if movement.dot(normal) < -0.000001:
				result = {"time": t, "normal": normal, "kind": "bumper", "id": i}
	for i in range(gates.size()):
		if seen & (1 << i):
			continue
		var hit := SWEEP.rounded_box(from, to, gates[i], RADIUS)
		if hit.time < result.time:
			result = {"time": hit.time, "normal": hit.normal, "kind": "gate", "id": i}
	return result

func move_ball(index: int, delta: float) -> void:
	var ball := pool[index]
	var remaining := delta
	for step in range(8):
		var destination: Vector2 = ball.p + ball.v * remaining
		var hit := collision(ball.p, destination, ball.gates)
		if hit.time > 1:
			ball.p = destination
			remaining = 0
			break
		ball.p = ball.p.lerp(destination, hit.time)
		remaining *= 1.0 - hit.time
		if hit.kind == "gate":
			multiply(index, hit.id)
		elif hit.kind == "paddle":
			var offset := clampf((ball.p.x - paddle_x) / (PADDLE_WIDTH / 2), -1, 1)
			var angle := offset * 1.05
			if absf(angle) < 0.12:
				angle = 0.12 * (-1 if ball.v.x < 0 else 1)
			ball.v = Vector2(sin(angle), -cos(angle)) * speed()
			catches += 1
		else:
			ball.v = rebound(ball.v, hit.normal)
			if hit.kind == "brick":
				bricks[hit.id].hp -= 1
				brick_hits += 1
				add_score(10 if bricks[hit.id].hp > 0 else 25)
				burst(ball.p, COLORS[bricks[hit.id].color], 3)
			elif hit.kind == "bumper":
				bumper_hits += 1
		if hit.kind != "gate" and sound_time <= 0:
			Sound.play(2 if hit.kind == "brick" else 1)
			sound_time = 0.07
		ball.p += (ball.v.normalized() if hit.kind == "gate" else hit.normal) * 0.08
		if remaining < 0.000001:
			break
	if remaining > 0.000001:
		collision_limit_hits += 1
	# Dropped balls return to the fixed pool; no scene nodes or timers survive.
	if ball.p.y > area.y + RADIUS:
		ball.active = false
		recycled += 1

func _physics_process(delta: float) -> void:
	if stopped or suspended:
		return
	tick += 1
	sound_time = maxf(0, sound_time - delta)
	for i in range(2):
		gate_glow[i] = maxf(0, gate_glow[i] - delta)
	if clear_time > 0:
		clear_time -= delta
		if clear_time <= 0:
			wave += 1
			make_wave()
			# Recall survivors below the new board, so new bricks never enclose balls.
			var count := active_count()
			var ordinal := 0
			for ball in pool:
				if ball.active:
					var angle := -0.75 + 1.5 * (ordinal + 0.5) / count
					ball.p = Vector2(paddle_x, paddle_y() - 25)
					ball.v = Vector2(sin(angle), -cos(angle)) * speed()
					ordinal += 1
			if count == 0:
				spawn(Vector2(paddle_x, paddle_y() - 25), Vector2(0.34, -1), 0)
			checkpoint()
	else:
		for i in range(MAX_BALLS):
			if pool[i].active and pool[i].born < tick:
				move_ball(i, delta)
		if bricks_left() == 0:
			clear_time = 0.65
			add_score(100)
			toast_requested.emit(MochiCatalog.words("Lovely rally! Next wave", "打得漂亮！下一波"))
			checkpoint()
		elif active_count() == 0:
			finish(MochiCatalog.words("A lovely little rally. Catch another?", "这轮弹跳真开心，再接一球吧？"))
	save_time += delta
	if save_time >= 2:
		checkpoint()
	step_effects(delta)
	queue_redraw()

func checkpoint() -> void:
	if stopped:
		return
	save_time = 0
	var balls: Array = []
	for ball in pool:
		if ball.active:
			balls.append([ball.p.x / area.x, ball.p.y / area.y, ball.v.x, ball.v.y, ball.gates, ball.color])
	var health: Array = []
	for brick in bricks:
		health.append(brick.hp)
	Save.save_session(game_id, {"seed": run_seed, "wave": wave, "score": score, "paddle": paddle_x / area.x, "balls": balls, "health": health, "clear": clear_time, "area": [area.x, area.y]})

func restore(saved: Dictionary) -> bool:
	if not saved.get("balls") is Array or not saved.get("health") is Array or saved.health.size() != 24 or saved.balls.size() > MAX_BALLS:
		return false
	wave = clampi(int(saved.get("wave", 1)), 1, 100000)
	make_wave()
	for i in range(24):
		if not (saved.health[i] is float or saved.health[i] is int) or saved.health[i] < 0 or saved.health[i] > bricks[i].max:
			wave = 1
			return false
	for entry in saved.balls:
		if not entry is Array or entry.size() != 6:
			wave = 1
			return false
		for value in entry:
			if not (value is float or value is int) or not is_finite(float(value)):
				wave = 1
				return false
		if entry[0] < 0 or entry[0] > 1 or entry[1] < 0 or entry[1] > 1.1 or int(entry[4]) < 0 or int(entry[4]) > 3:
			wave = 1
			return false
	for i in range(24):
		bricks[i].hp = int(saved.health[i])
	clear_time = clampf(float(saved.get("clear", 0)), 0, 0.65)
	if bricks_left() == 0:
		clear_time = maxf(0.01, clear_time)
	elif saved.balls.is_empty():
		wave = 1
		return false
	score = maxi(0, int(saved.get("score", 0)))
	paddle_x = clampf(float(saved.get("paddle", 0.5)) * area.x, 18 + PADDLE_WIDTH / 2, area.x - 18 - PADDLE_WIDTH / 2)
	for entry in saved.balls:
		var point := Vector2(clampf(entry[0] * area.x, 18 + RADIUS, area.x - 18 - RADIUS), maxf(57 + RADIUS, entry[1] * area.y))
		var id := spawn(point, Vector2(entry[2], entry[3]), int(entry[4]))
		pool[id].color = clampi(int(entry[5]), 0, 4)
	if saved.get("area", []) != [area.x, area.y]:
		# A different aspect ratio changes obstacles. Recall safely below them,
		# retaining every survivor, gate claim, brick, wave and point.
		for ball in pool:
			if ball.active:
				ball.p = Vector2(paddle_x, paddle_y() - 25)
				ball.v.y = -absf(ball.v.y)
	return true

func _draw() -> void:
	rounded(Rect2(Vector2.ZERO, area), Color("f8efda"), 30)
	text_at(MochiCatalog.words("RALLY ", "弹跳 ") + str(wave), Vector2(38, 36), 21, P.MUTED)
	text_at(str(active_count()) + " / 64 " + MochiCatalog.words("BALLS", "颗球"), Vector2(area.x - 180, 36), 20, P.MUTED)
	draw_line(Vector2(18, 57), Vector2(18, paddle_y() + 20), Color("e6d7b9"), 3, true)
	draw_line(Vector2(area.x - 18, 57), Vector2(area.x - 18, paddle_y() + 20), Color("e6d7b9"), 3, true)
	for brick in bricks:
		if brick.hp > 0:
			rounded(brick.rect, COLORS[brick.color], 12, Color("d6c3a6"))
			text_at(str(brick.hp), brick.rect.get_center() + Vector2(0, 9), 25, P.INK, true)
	for point in bumpers:
		draw_circle(point + Vector2(0, 5), BUMPER_RADIUS + 3, Color("e5d7ba"))
		draw_circle(point, BUMPER_RADIUS, P.PAPER)
		var sprite_size := BUMPER_RADIUS * 1.65
		draw_texture_rect(sprites[2], Rect2(point - Vector2.ONE * sprite_size * 0.5, Vector2.ONE * sprite_size), false)
	for i in range(gates.size()):
		var color: Color = P.MINT if i == 0 else P.LILAC
		rounded(gates[i].grow(4 if gate_glow[i] > 0 and not reduced_motion else 0), color, 20, color.darkened(0.14))
		text_at("×" + str(i + 2), gates[i].get_center() + Vector2(0, 12), 34, P.INK, true)
	# Draw trails together behind the shared-atlas sprites. Interleaving each
	# line with a sprite prevented batching and added two submissions per ball.
	if not reduced_motion:
		var trails := PackedVector2Array()
		for ball in pool:
			if ball.active:
				trails.append(ball.p - ball.v.normalized() * (RADIUS * 1.7))
				trails.append(ball.p)
		if not trails.is_empty():
			draw_multiline(trails, Color(1, 1, 1, 0.7), 10, true)
	for ball in pool:
		if ball.active:
			draw_texture_rect(sprites[ball.color], Rect2(ball.p - Vector2.ONE * RADIUS, Vector2.ONE * RADIUS * 2), false)
	rounded(paddle_rect().grow(3), Color("dfbda0"), 13)
	rounded(paddle_rect(), P.PAPER, 10)
	draw_line(Vector2(paddle_x - 22, paddle_y() + 9), Vector2(paddle_x + 22, paddle_y() + 9), P.PEACH, 4, true)
	text_at(MochiCatalog.words("Drag to catch · full pool = +5 per extra ball", "拖动接球 · 球池满后每颗额外球 +5 分"), Vector2(area.x / 2, area.y - 22), 19, P.MUTED, true)
	draw_effects()
