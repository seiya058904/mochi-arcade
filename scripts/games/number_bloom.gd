extends MochiGame

const P := preload("res://scripts/shared/palette.gd")
const RULES := preload("res://scripts/games/bloom_rules.gd")
var board: Array = []
var undo_state: Dictionary = {}
var start := Vector2.ZERO
var holding := false
var won := false
var traces: Array = []
var animation := 1.0
var spawned := -1
var board_y := 0.0
var cell := 0.0

func _ready() -> void:
	board.resize(16)
	board.fill(0)
	board_y = maxf(76, (area.y - area.x) * 0.4)
	cell = (area.x - 52) / 4.0
	var saved := Save.session(game_id)
	if valid_board(saved.get("board", [])):
		board = saved.board.map(func(x): return int(x))
		score = int(saved.get("score", 0))
		won = bool(saved.get("won", false))
		rng.state = int(saved.get("rng", str(rng.state)))
		undo_state = saved.get("undo", {})
	else:
		RULES.spawn(board, rng)
		RULES.spawn(board, rng)
	checkpoint()

func valid_board(value: Variant) -> bool:
	if not value is Array or value.size() != 16:
		return false
	for number in value:
		var n := int(number)
		if n < 0 or n > 1048576 or (n > 0 and (n < 2 or (n & (n - 1)) != 0)):
			return false
	return true

func _process(delta: float) -> void:
	animation = minf(1, animation + delta / (0.04 if reduced_motion else 0.15))
	step_effects(delta)
	queue_redraw()

func press(point: Vector2) -> void:
	holding = true
	start = point

func release(point: Vector2) -> void:
	if not holding:
		return
	holding = false
	var distance := point - start
	if distance.length() < 28:
		return
	if absf(distance.x) > absf(distance.y):
		slide(1 if distance.x > 0 else 0)
	else:
		slide(3 if distance.y > 0 else 2)

func cancel_pointer() -> void:
	super.cancel_pointer()
	holding = false

func action(name: String) -> void:
	if name == "undo":
		undo()
	elif name in ["left", "a"]:
		slide(0)
	elif name in ["right", "d"]:
		slide(1)
	elif name in ["up", "w"]:
		slide(2)
	elif name in ["down", "s"]:
		slide(3)

func slide(direction: int) -> void:
	if stopped or suspended or animation < 1:
		return
	var result := RULES.move(board, direction)
	if not result.changed:
		if not RULES.can_move(board):
			finish(MochiCatalog.words("Your garden is full. A fresh start is one tap away.", "花园长满啦，点一下就能重新开始。"))
		return
	undo_state = {"board": board.duplicate(), "score": score, "rng": str(rng.state), "won": won}
	board = result.board
	traces = result.traces
	spawned = RULES.spawn(board, rng)
	animation = 0.0
	add_score(result.score)
	Sound.play(mini(7, int(log(maxi(2, result.score)) / log(2.0))))
	if 2048 in board and not won:
		won = true
		toast_requested.emit(MochiCatalog.words("2048 bloomed! Keep growing.", "2048 绽放啦！继续生长吧。"))
		burst(Vector2(area.x / 2, board_y + area.x / 2), P.MINT, 32)
	checkpoint()
	if not RULES.can_move(board):
		# End after the final movement can actually be seen; no orphan timers.
		var tween := create_tween()
		tween.tween_interval(0.22)
		tween.tween_callback(func():
			if not stopped and not RULES.can_move(board):
				finish(MochiCatalog.words("A full garden of numbers. Beautifully played.", "满满一园数字，玩得真好。")))

func undo() -> void:
	if undo_state.is_empty() or suspended:
		toast_requested.emit(MochiCatalog.words("Make a move first", "先走一步试试"))
		return
	board = undo_state.board.duplicate()
	score = int(undo_state.score)
	rng.state = int(undo_state.rng)
	won = bool(undo_state.won)
	undo_state.clear()
	animation = 1
	stopped = false
	score_changed.emit(score)
	checkpoint()
	queue_redraw()

func tile_position(index: int) -> Vector2:
	return Vector2(20 + (index % 4) * (cell + 4), board_y + 20 + (index / 4) * (cell + 4))

func tile_color(value: int) -> Color:
	var colors := [P.PAPER, Color("f8e9c7"), P.PEACH, P.ROSE, P.LILAC, P.SKY, P.MINT, Color("ecd8a3"), Color("dfc6b8"), Color("ccb7d8"), Color("b9d3c0"), Color("f0ce83")]
	return colors[mini(colors.size() - 1, int(log(value) / log(2.0)) - 1)]

func draw_tile(value: int, point: Vector2, scale_value: float = 1.0) -> void:
	var extent := Vector2.ONE * (cell - 2)
	var center := point + extent / 2
	var rect := Rect2(center - extent * scale_value / 2, extent * scale_value)
	rounded(Rect2(rect.position + Vector2(0, 4), rect.size), Color("d5c7b6"), 18)
	rounded(rect, tile_color(value), 18)
	draw_arc(rect.position + Vector2(18, 18), 7, PI, PI * 1.5, 10, Color(1, 1, 1, 0.65), 3, true)
	text_at(str(value), center + Vector2(0, 16), 43 if value < 1024 else 32, P.INK, true)

func _draw() -> void:
	text_at(MochiCatalog.words("A LITTLE SPACE TO GROW", "留一点空间，慢慢生长"), Vector2(area.x / 2, 38), 21, P.MUTED, true)
	rounded(Rect2(0, board_y, area.x, area.x), Color("e8dfcd"), 30)
	for i in range(16):
		rounded(Rect2(tile_position(i), Vector2.ONE * (cell - 2)), Color("f2e9da"), 18)
	if animation < 1:
		var eased := 1.0 - pow(1.0 - animation, 3)
		for trace in traces:
			draw_tile(trace.value, tile_position(trace.from).lerp(tile_position(trace.to), eased))
	else:
		for i in range(16):
			if int(board[i]) > 0:
				draw_tile(board[i], tile_position(i))
	var footer := board_y + area.x + 65
	text_at(MochiCatalog.words("Swipe. Merge. Bloom.", "滑动，合并，绽放。"), Vector2(area.x / 2, footer), 29, P.INK, true)
	text_at(MochiCatalog.words("One move at a time. Undo is always free.", "一步一步来，撤回不收费。"), Vector2(area.x / 2, footer + 42), 22, P.MUTED, true)
	draw_effects()

func checkpoint() -> void:
	if not stopped:
		Save.save_session(game_id, {"board": board, "score": score, "rng": str(rng.state), "won": won, "undo": undo_state, "seed": run_seed})
