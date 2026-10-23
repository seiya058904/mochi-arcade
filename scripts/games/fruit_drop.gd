extends MochiGame

const P := preload("res://scripts/shared/palette.gd")
const RULES := preload("res://scripts/games/fruit_rules.gd")
const BODY := preload("res://scripts/games/fruit_body.gd")
var textures: Array[Texture2D] = []
var fruits: Array[RigidBody2D] = []
var claimed: Dictionary = {}
var pending_merges: Array = []
var next_id := 0
var next_level := 0
var aim_x := 324.0
var cooldown := 0.0
var overflow_time := 0.0
var danger_line := 180.0
var jar_top := 142.0
var floor_y := 0.0
var holding := false
var merge_count := 0
var save_clock := 0.0

func _ready() -> void:
	floor_y = area.y - 60
	aim_x = area.x / 2
	load_art()
	wall(Rect2(2, jar_top, 16, floor_y - jar_top + 18))
	wall(Rect2(area.x - 18, jar_top, 16, floor_y - jar_top + 18))
	wall(Rect2(2, floor_y, area.x - 4, 20))
	var saved := Save.session(game_id)
	if saved.get("fruit", []) is Array and saved.has("score"):
		score = int(saved.score)
		next_level = clampi(int(saved.get("next", 0)), 0, 2)
		rng.state = int(saved.get("rng", str(rng.state)))
		for state in saved.fruit:
			if state is Dictionary and state.has_all(["level", "x", "y"]):
				var fruit = spawn_fruit(clampi(int(state.level), 0, 7), Vector2(float(state.x), float(state.y)))
				fruit.linear_velocity = Vector2(float(state.get("vx", 0)), float(state.get("vy", 0)))
				fruit.rotation = float(state.get("angle", 0))
				fruit.age = 2.0
	else:
		next_level = rng.randi_range(0, 2)

func load_art() -> void:
	if not ResourceLoader.exists("res://assets/art/fruit-characters.png"):
		return
	var atlas: Texture2D = load("res://assets/art/fruit-characters.png")
	# Tight per-object crops preserve the round body's collision silhouette;
	# foliage extends above the circle instead of shrinking the entire fruit.
	var regions := [Rect2(76, 43, 312, 376), Rect2(510, 55, 326, 365),
		Rect2(937, 54, 330, 365), Rect2(1381, 40, 330, 393),
		Rect2(63, 449, 348, 390), Rect2(501, 457, 352, 378),
		Rect2(928, 454, 350, 385), Rect2(1367, 436, 353, 410)]
	for i in range(8):
		var texture := AtlasTexture.new()
		texture.atlas = atlas
		texture.region = regions[i]
		textures.append(texture)

func wall(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func spawn_fruit(level: int, point: Vector2) -> RigidBody2D:
	var fruit := BODY.new()
	fruit.level = level
	fruit.number = next_id
	next_id += 1
	fruit.radius = RULES.RADII[level]
	fruit.position = Vector2(clampf(point.x, 20 + fruit.radius, area.x - 20 - fruit.radius), minf(point.y, floor_y - fruit.radius))
	if textures.size() == 8:
		fruit.texture = textures[level]
	fruit.body_entered.connect(func(other): contact(fruit, other))
	add_child(fruit)
	fruits.append(fruit)
	return fruit

func contact(a: RigidBody2D, b: Node) -> void:
	if stopped or suspended or not b.get_script() == BODY:
		return
	if a.consumed or b.consumed:
		return
	if RULES.claim(a.number, b.number, a.level, b.level, claimed):
		a.consumed = true
		b.consumed = true
		pending_merges.append([a, b])
		merge_pair.call_deferred(a, b)

func merge_pair(a: RigidBody2D, b: RigidBody2D) -> void:
	if not is_instance_valid(a) or not is_instance_valid(b) or not is_inside_tree():
		return
	# A claimed pair is still the complete pre-merge state until committed.
	# Lifecycle suspension must not let deferred work change a frozen snapshot.
	if suspended or not pending_merges.has([a, b]):
		return
	pending_merges.erase([a, b])
	var point := (a.position + b.position) / 2
	var level: int = a.level
	var velocity := (a.linear_velocity + b.linear_velocity) * 0.25
	fruits.erase(a)
	fruits.erase(b)
	claimed.erase(a.number)
	claimed.erase(b.number)
	remove_child(a)
	remove_child(b)
	a.queue_free()
	b.queue_free()
	if stopped:
		return
	if level < 7:
		var fruit = spawn_fruit(level + 1, point)
		fruit.linear_velocity = velocity + Vector2(0, -45)
		fruit.visual_scale = 0.84 if not reduced_motion else 1.0
	else:
		toast_requested.emit(MochiCatalog.words("A whole basket of sunshine!", "满满一篮阳光！"))
	merge_count += 1
	add_score(RULES.merge_score(level))
	Sound.play(level)
	burst(point, P.ACCENTS[level], 16)
	checkpoint()

func press(point: Vector2) -> void:
	if cooldown > 0:
		return
	holding = true
	aim_x = point.x

func drag(point: Vector2) -> void:
	if holding:
		aim_x = point.x

func release(point: Vector2) -> void:
	if not holding or stopped or suspended:
		return
	holding = false
	aim_x = point.x
	drop()

func cancel_pointer() -> void:
	super.cancel_pointer()
	holding = false

func drop() -> void:
	if stopped or suspended or cooldown > 0:
		return
	spawn_fruit(next_level, Vector2(aim_x, jar_top - RULES.RADII[next_level] - 5))
	next_level = rng.randi_range(0, 2)
	cooldown = 0.38
	Sound.play(0)
	checkpoint()

func _physics_process(delta: float) -> void:
	if stopped or suspended:
		return
	cooldown = maxf(0, cooldown - delta)
	var danger := false
	for fruit in fruits:
		if is_instance_valid(fruit) and not fruit.consumed:
			if RULES.overflow(fruit.position.y - fruit.radius, fruit.linear_velocity.length(), fruit.age, danger_line):
				danger = true
			# Rare severe collision impulses must not escape the closed jar.
			fruit.linear_velocity = fruit.linear_velocity.limit_length(950)
	overflow_time = overflow_time + delta if danger else 0.0
	if overflow_time > 1.25:
		finish(MochiCatalog.words("Your fruit basket is full. A fresh basket is ready!", "水果篮装满啦！再来一篮吧。"))
		for fruit in fruits:
			fruit.freeze = true
	save_clock += delta
	if save_clock > 2.0:
		save_clock = 0
		checkpoint()
	step_effects(delta)
	queue_redraw()

func set_suspended(value: bool) -> void:
	super.set_suspended(value)
	for fruit in fruits:
		fruit.freeze = value or stopped
	if not value:
		for pair in pending_merges:
			merge_pair.call_deferred(pair[0], pair[1])

func _draw() -> void:
	rounded(Rect2(0, 0, area.x, area.y), Color("fcf0e5"), 30)
	text_at(MochiCatalog.words("A BASKET OF LITTLE JOYS", "把小快乐，合成大快乐"), Vector2(area.x / 2, 38), 21, P.MUTED, true)
	rounded(Rect2(10, jar_top, area.x - 20, floor_y - jar_top + 18), P.PAPER, 30, Color("e8d4bf"))
	for x in range(28, int(area.x - 20), 20):
		draw_line(Vector2(x, danger_line), Vector2(x + 9, danger_line), Color("d78d80") if overflow_time > 0 else Color("dec8b4"), 2)
	var radius: float = RULES.RADII[next_level]
	var x := clampf(aim_x, 20 + radius, area.x - 20 - radius)
	if not stopped:
		draw_line(Vector2(x, 104), Vector2(x, floor_y - 12), Color(0.7, 0.5, 0.35, 0.12), 2)
		if textures.size() == 8:
			var texture: Texture2D = textures[next_level]
			var height := radius * 2 * texture.get_height() / texture.get_width()
			draw_texture_rect(texture, Rect2(x - radius, 94 + radius - height, radius * 2, height), false)
	text_at(MochiCatalog.words("Drag to aim · release to drop", "拖动瞄准 · 松手落下"), Vector2(area.x / 2, area.y - 18), 23, P.MUTED, true)
	draw_effects()

func checkpoint() -> void:
	if stopped:
		return
	var state: Array = []
	for fruit in fruits:
		# Pending pairs remain in fruits until their synchronous replacement and
		# score update finish. Include them so every commit is a coherent prefix.
		if is_instance_valid(fruit):
			state.append({"level": fruit.level, "x": fruit.position.x, "y": fruit.position.y, "vx": fruit.linear_velocity.x, "vy": fruit.linear_velocity.y, "angle": fruit.rotation})
	Save.save_session(game_id, {"fruit": state, "score": score, "next": next_level, "rng": str(rng.state), "seed": run_seed})
