extends MochiGame

const P := preload("res://scripts/shared/palette.gd")
const RULES := preload("res://scripts/games/hop_rules.gd")
const SWEETS := [Color("edbdc4"), Color("c6dfca"), Color("f2dba6"), Color("d6c6e4")]
enum State { READY, CHARGING, AIRBORNE, SETTLING, FALLING }
var state := State.READY
var current := {"center": Vector2.ZERO, "radius": 62.0, "kind": 0}
var target: Dictionary = {}
var previous: Array[Dictionary] = []
var foot := Vector2.ZERO
var held := 0.0
var charge_note := 0
var jump_from := Vector2.ZERO
var jump_to := Vector2.ZERO
var jump_elapsed := 0.0
var jump_duration := 0.7
var settle_time := 0.0
var fall_time := 0.0
var landed := 0
var combo := 0
var jumps := 0
var camera := Vector2.ZERO
var camera_target := Vector2.ZERO
var last_result: Dictionary = {}
var bunny: Texture2D
var platforms: Array[Texture2D] = []

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if ResourceLoader.exists("res://assets/art/hop-bunny.png"):
		var sprite := AtlasTexture.new()
		sprite.atlas = load("res://assets/art/hop-bunny.png")
		sprite.region = Rect2(136, 94, 992, 1118)
		bunny = sprite
	load_platform_art()
	var saved := Save.session(game_id)
	if saved.has("current") and saved.has("target") and saved.get("foot") is Array:
		var restored_current := decode_platform(saved.current)
		var restored_target := decode_platform(saved.target)
		if not restored_current.is_empty() and not restored_target.is_empty() and saved.foot.size() == 2:
			current = restored_current
			target = restored_target
			foot = Vector2(float(saved.foot[0]), float(saved.foot[1]))
			if not foot.is_finite() or foot.distance_to(current.center) > current.radius:
				foot = current.center
			landed = maxi(0, int(saved.get("landed", 0)))
			combo = clampi(int(saved.get("combo", 0)), 0, 5)
			score = maxi(0, int(saved.get("score", 0)))
			rng.state = int(saved.get("rng", str(rng.state)))
	if target.is_empty() or RULES.charge_interval(foot, target.center, target.radius).y < 0:
		target = RULES.next_platform(rng, current.center, foot, landed)
	update_camera()
	camera = camera_target
	checkpoint()

func decode_platform(value: Variant) -> Dictionary:
	if not value is Dictionary or not value.get("center") is Array or value.center.size() != 2:
		return {}
	var center := Vector2(float(value.center[0]), float(value.center[1]))
	if not center.is_finite():
		return {}
	return {"center": center, "radius": clampf(float(value.get("radius", 62)), 48, 62), "kind": clampi(int(value.get("kind", 0)), 0, 3)}

func load_platform_art() -> void:
	if not ResourceLoader.exists("res://assets/art/hop-platforms.png"):
		return
	var sheet: Texture2D = load("res://assets/art/hop-platforms.png")
	for i in range(4):
		var texture := AtlasTexture.new()
		texture.atlas = sheet
		texture.region = Rect2(35 + i * 543, 169, 475, 347)
		platforms.append(texture)

func update_camera() -> void:
	camera_target = (RULES.project(current.center) + RULES.project(target.center)) * 0.5

func screen_point(point: Vector2) -> Vector2:
	return RULES.project(point) - camera + Vector2(area.x * 0.5, area.y * 0.52)

func press(_point: Vector2) -> void:
	if stopped or suspended or state != State.READY:
		return
	state = State.CHARGING
	held = 0
	charge_note = 0
	Sound.play(1)
	queue_redraw()

func release(_point: Vector2) -> void:
	if stopped or suspended or state != State.CHARGING:
		return
	jump_from = foot
	jump_to = foot + foot.direction_to(target.center) * RULES.distance(held)
	jump_duration = 0.5 + jump_from.distance_to(jump_to) / 1200
	jump_elapsed = 0
	jumps += 1
	state = State.AIRBORNE
	Sound.play(3)

func cancel_pointer() -> void:
	super.cancel_pointer()
	if state == State.CHARGING:
		state = State.READY
		held = 0
	queue_redraw()

func resolve_landing() -> void:
	last_result = RULES.landing(jump_to, target, combo)
	if not last_result.success:
		state = State.FALLING
		fall_time = 0
		combo = 0
		Sound.play(0)
		return
	previous.append(current.duplicate())
	if previous.size() > 3:
		previous.pop_front()
	current = target
	foot = last_result.foot
	combo = last_result.combo
	landed += 1
	add_score(last_result.points)
	burst(screen_point(foot), SWEETS[current.kind], 12)
	toast_requested.emit(MochiCatalog.words("Perfect! +", "正中心！+") + str(last_result.points) if last_result.perfect else MochiCatalog.words("A sweet little landing +1", "稳稳落地 +1"))
	Sound.play(mini(7, 2 + combo))
	target = RULES.next_platform(rng, current.center, foot, landed)
	update_camera()
	state = State.SETTLING
	settle_time = 0.22
	held = 0
	checkpoint()

func _process(delta: float) -> void:
	if stopped or suspended:
		return
	match state:
		State.CHARGING:
			held = minf(RULES.MAX_HOLD, held + delta)
			var note := mini(4, int(held / 0.25))
			if note > charge_note:
				charge_note = note
				Sound.play(note)
		State.AIRBORNE:
			jump_elapsed += delta
			if jump_elapsed >= jump_duration:
				resolve_landing()
		State.SETTLING:
			settle_time -= delta
			if settle_time <= 0:
				state = State.READY
		State.FALLING:
			fall_time += delta
			if fall_time >= 0.35:
				finish(MochiCatalog.words("A little tumble. Your next sweet landing is one hop away.", "轻轻摔了一跤，再来一次甜甜的跳跃吧。"))
	camera = camera_target if reduced_motion else camera.lerp(camera_target, 1 - exp(-delta * 7))
	step_effects(delta)
	queue_redraw()

func ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(48):
		points.append(center + Vector2(cos(i * TAU / 48), sin(i * TAU / 48)) * radius)
	draw_colored_polygon(points, color)

func draw_platform(platform: Dictionary, alpha: float = 1.0) -> void:
	var center := screen_point(platform.center)
	if alpha < 1.0 and (center.x < 90 or center.x > area.x - 90 or center.y > area.y - 180):
		return
	var radius: float = platform.radius
	var rx := radius * sqrt(2.0)
	var ry := rx * 0.5
	var color: Color = SWEETS[platform.kind]
	color.a = alpha
	ellipse(center + Vector2(0, 40), Vector2(rx * 0.9, ry * 0.8), Color(0.4, 0.3, 0.25, 0.06 * alpha))
	if platforms.size() == 4:
		draw_texture_rect(platforms[platform.kind], Rect2(center - Vector2(rx, ry), Vector2(rx * 2, ry * 2 + 30)), false, Color(1, 1, 1, alpha))
	else:
		ellipse(center + Vector2(0, 24), Vector2(rx, ry), color.darkened(0.13))
		draw_rect(Rect2(center - Vector2(rx, 0), Vector2(rx * 2, 24)), color.darkened(0.08))
		ellipse(center, Vector2(rx, ry), color.lightened(0.15))
	# Same projection as the landing rule; the gentle center mark identifies perfection.
	ellipse(center, Vector2(11, 5.5), Color(1, 1, 1, 0.75 * alpha))
	ellipse(center, Vector2(4, 2), Color(0.42, 0.32, 0.27, 0.22 * alpha))

func draw_bunny(ground: Vector2, height: float, squash: Vector2, alpha: float = 1.0) -> void:
	var screen := screen_point(ground)
	ellipse(screen, Vector2(29, 13) * (1 - minf(height / 350, 0.45)), Color(0.4, 0.3, 0.25, 0.16 * alpha))
	var size_px := Vector2(96, 96 * bunny.get_height() / float(bunny.get_width()) if bunny else 118) * squash
	var rect := Rect2(screen - Vector2(size_px.x * 0.5, size_px.y + height), size_px)
	if bunny:
		draw_texture_rect(bunny, rect, false, Color(1, 1, 1, alpha))
	else:
		ellipse(screen - Vector2(0, 43 + height), Vector2(38, 42) * squash, P.PAPER)
		for side in [-1, 1]:
			ellipse(screen + Vector2(side * 17, -86 - height), Vector2(9, 22) * squash, P.PAPER)
			ellipse(screen + Vector2(side * 12, -47 - height), Vector2(3, 4), P.INK)

func _draw() -> void:
	rounded(Rect2(Vector2.ZERO, area), Color("f1eef5"), 30)
	text_at(MochiCatalog.words("ONE LITTLE HOP AT A TIME", "一小步，也是一份快乐"), Vector2(area.x / 2, 44), 20, P.MUTED, true)
	if combo >= 2:
		text_at(MochiCatalog.words("Sweet streak  ", "连续正中  ") + str(combo), Vector2(area.x / 2, 90), 25, P.INK, true)
	for platform in previous:
		draw_platform(platform, 0.35)
	draw_platform(current)
	draw_platform(target)
	var ground := foot
	var height := 0.0
	var squash := Vector2.ONE
	var alpha := 1.0
	if state == State.CHARGING:
		var power := held / RULES.MAX_HOLD
		squash = Vector2(1 + power * 0.2, 1 - power * 0.28)
	elif state == State.AIRBORNE:
		var progress := jump_elapsed / jump_duration
		ground = RULES.ground_position(jump_from, jump_to, progress)
		height = RULES.arc_height(progress, 85 if reduced_motion else 125)
		squash = Vector2(0.94, 1.06)
	elif state == State.SETTLING and not reduced_motion:
		var bounce := sin(settle_time / 0.22 * PI)
		squash = Vector2(1 + bounce * 0.13, 1 - bounce * 0.15)
	elif state == State.FALLING:
		ground = jump_to
		height = -fall_time * 120
		alpha = maxf(0.2, 1 - fall_time * 2)
	draw_bunny(ground, height, squash, alpha)
	var meter := Rect2(area.x / 2 - 135, area.y - 110, 270, 20)
	rounded(meter, Color("e1d9e7"), 10)
	if held > 0 and state == State.CHARGING:
		rounded(Rect2(meter.position, Vector2(maxf(10, meter.size.x * held / RULES.MAX_HOLD), meter.size.y)), P.ROSE, 10)
	text_at(MochiCatalog.words("Hold to squish · release to hop", "按住蓄力 · 松手起跳"), Vector2(area.x / 2, area.y - 55), 24, P.MUTED, true)
	text_at(MochiCatalog.words("Longer hold, farther hop", "按得越久，跳得越远"), Vector2(area.x / 2, area.y - 23), 19, P.MUTED, true)
	draw_effects()

func encode_platform(value: Dictionary) -> Dictionary:
	return {"center": [value.center.x, value.center.y], "radius": value.radius, "kind": value.kind}

func checkpoint() -> void:
	if stopped or target.is_empty():
		return
	# On process death during flight, restore the last safe footing and same target.
	# Normal pause/resume keeps the exact airborne state in memory.
	Save.save_session(game_id, {"current": encode_platform(current), "target": encode_platform(target),
		"foot": [foot.x, foot.y], "landed": landed, "combo": combo, "score": score, "rng": str(rng.state), "seed": run_seed})
