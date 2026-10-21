extends MochiGame

const P := preload("res://scripts/shared/palette.gd")
const RULES := preload("res://scripts/games/cake_rules.gd")
var layers: Array = []
var scraps: Array[Dictionary] = []
var tier := 0
var combo := 0
var moving_x := 0.0
var moving_time := 0.0
var camera_y := 0.0
var feedback := ""
var feedback_life := 0.0
var bunny: Texture2D

func _ready() -> void:
	layers = [{"x": (area.x - 320) / 2.0, "w": 320.0, "tier": 0}]
	if ResourceLoader.exists("res://assets/art/mochi-bunny.png"):
		bunny = load("res://assets/art/mochi-bunny.png")
	var saved := Save.session(game_id)
	if saved.has("layers") and saved.layers is Array and not saved.layers.is_empty():
		layers = saved.layers
		tier = int(saved.get("tier", 0))
		combo = int(saved.get("combo", 0))
		score = int(saved.get("score", 0))
		moving_time = float(saved.get("time", 0))
		camera_y = maxf(0, tier - 7) * 44
	update_moving()

func update_moving() -> void:
	moving_x = RULES.position_at(moving_time, layers[-1].w, area.x, minf(280, 135 + tier * 5))

func _process(delta: float) -> void:
	if stopped or suspended:
		return
	moving_time += delta
	update_moving()
	camera_y = lerpf(camera_y, maxf(0, tier - 7) * 44, 1.0 - exp(-delta * 6))
	feedback_life = maxf(0, feedback_life - delta)
	for i in range(scraps.size() - 1, -1, -1):
		scraps[i].vy += delta * 850
		scraps[i].y += scraps[i].vy * delta
		scraps[i].x += scraps[i].vx * delta
		if scraps[i].y > area.y + 100:
			scraps.remove_at(i)
	step_effects(delta)
	queue_redraw()

func press(_point: Vector2) -> void:
	place()

func action(name: String) -> void:
	if name in ["space", "enter"]:
		place()

func place() -> void:
	if stopped or suspended:
		return
	var top: Dictionary = layers[-1]
	var result := RULES.overlap(top.x, top.w, moving_x)
	if not result.hit:
		finish(MochiCatalog.words("A sweet little stack. Try a slower breath next time.", "一座甜甜的小高塔。放松一点，再试一次吧。"))
		return
	tier += 1
	combo = combo + 1 if result.perfect else 0
	layers.append({"x": result.x, "w": result.width, "tier": tier})
	if layers.size() > 24:
		layers.pop_front()
	if result.cut_width > 0:
		scraps.append({"x": result.cut_x, "w": result.cut_width, "y": layer_y(tier), "vy": 0.0, "vx": -55.0 if moving_x < top.x else 55.0, "tier": tier})
	feedback = MochiCatalog.words("Perfect!", "完美！") if result.perfect else MochiCatalog.words("Sweet!", "叠好啦！")
	feedback_life = 0.8
	add_score(1 + mini(combo, 5) if result.perfect else 1)
	Sound.play(combo)
	burst(Vector2(result.x + result.width * 0.5, layer_y(tier)), P.ACCENTS[tier % 8], 12)
	moving_time = 0.0
	update_moving()
	checkpoint()
	queue_redraw()

func layer_y(level: int) -> float:
	return area.y - 150 - level * 44 + camera_y

func draw_cake(rect: Rect2, level: int) -> void:
	var frosting: Color = [P.ROSE, P.MINT, P.LILAC, P.YELLOW][posmod(level, 4)]
	rounded(rect, Color("eac896"), 9, Color("d5ae80"))
	rounded(Rect2(rect.position + Vector2(2, 14), Vector2(maxf(2, rect.size.x - 4), 10)), P.PAPER, 4)
	rounded(Rect2(rect.position, Vector2(rect.size.x, 15)), frosting, 8)
	for i in range(int(rect.size.x / 25)):
		var x := rect.position.x + 12 + i * 25
		draw_circle(Vector2(x, rect.position.y + 12), 5, frosting)
		if i % 3 == 0:
			draw_circle(Vector2(x, rect.position.y + 31), 1.5, Color("c79a6d"))

func _draw() -> void:
	rounded(Rect2(0, 0, area.x, area.y), Color("fcf0e8"), 32)
	for i in range(6):
		draw_line(Vector2(i * 140 + 10, 0), Vector2(i * 140 - 140, area.y), Color(1, 1, 1, 0.26), 42)
	text_at(MochiCatalog.words("SWEET MOMENTS, STACKED", "把甜蜜，叠高一点"), Vector2(area.x * 0.5, 48), 20, P.MUTED, true)
	if bunny:
		draw_texture_rect(bunny, Rect2(area.x * 0.5 - 70, 75, 140, 100), false, Color(1, 1, 1, 0.95))
	var floor_y := layer_y(0) + 44
	if floor_y < area.y:
		rounded(Rect2(area.x * 0.5 - 190, floor_y + 8, 380, 20), Color("e8d7bd"), 10)
		rounded(Rect2(area.x * 0.5 - 178, floor_y, 356, 18), P.PAPER, 9)
	for layer in layers:
		var y := layer_y(int(layer.tier))
		if y > -60 and y < area.y:
			draw_cake(Rect2(layer.x, y, layer.w, 40), int(layer.tier))
	for scrap in scraps:
		draw_cake(Rect2(scrap.x, scrap.y, scrap.w, 40), int(scrap.tier))
	if not stopped:
		var y := layer_y(tier + 1)
		draw_cake(Rect2(moving_x, y, layers[-1].w, 40), tier + 1)
		draw_line(Vector2(moving_x + layers[-1].w / 2.0, y + 46), Vector2(moving_x + layers[-1].w / 2.0, y + 65), P.MUTED, 2)
	if feedback_life > 0:
		text_at(feedback + ("  ×" + str(combo) if combo > 1 else ""), Vector2(area.x / 2, 210), 34, P.INK, true)
	text_at(MochiCatalog.words("Tap anywhere to place a layer", "点击放下这一层"), Vector2(area.x / 2, area.y - 40), 25, P.MUTED, true)
	draw_effects()

func checkpoint() -> void:
	if stopped:
		return
	Save.save_session(game_id, {"layers": layers, "tier": tier, "combo": combo, "score": score, "time": moving_time, "seed": run_seed})
