extends SceneTree
const RULES := preload("res://scripts/games/trio_rules.gd")
var checks := 0
var failures: Array[String] = []
var maximum_nodes := 0
var worst_seed := -1
var start_time := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func verify_path(tiles: Array, path: Array, prefix: String) -> void:
	var mask := RULES.all_mask()
	var tray: Array = []
	var oracle_counts := PackedInt32Array()
	oracle_counts.resize(8)
	for id in path:
		var a: Rect2 = tiles[id].rect
		var uncovered := true
		for other in tiles:
			var b: Rect2 = other.rect
			if (mask & (1 << int(other.id))) != 0 and other.layer > tiles[id].layer and minf(a.end.x, b.end.x) > maxf(a.position.x, b.position.x) and minf(a.end.y, b.end.y) > maxf(a.position.y, b.position.y):
				uncovered = false
		check(uncovered, prefix + " independent rectangle occlusion")
		var move := RULES.take(tiles, mask, tray, id)
		check(move.valid, prefix + " legal uncovered pick")
		if not move.valid:
			return
		mask = move.mask
		tray = move.tray
		oracle_counts[tiles[id].kind] = (oracle_counts[tiles[id].kind] + 1) % 3
		var expected_size := 0
		for count in oracle_counts:
			expected_size += count
		check(tray.size() == expected_size, prefix + " independent triple count")
		check(not move.lost, prefix + " tray never fills")
	check(mask == 0 and tray.is_empty(), prefix + " all tiles cleared")

func run() -> void:
	start_time = Time.get_ticks_msec()
	for level in [1, 4, 10]:
		for seed_value in range(1, 501):
			var board := RULES.generate(seed_value, level)
			var prefix := "seed=" + str(seed_value) + " level=" + str(level)
			check(board.tiles.size() == 36, prefix + " fixed bounded board")
			check(RULES.valid_state(board.tiles, board.mask, []), prefix + " every motif count is a multiple of three")
			verify_path(board.tiles, board.witness, prefix + " construction")
			# The solver receives no construction witness; it searches only occupancy,
			# blockers and motif counts, and its result is independently replayed.
			var result := RULES.solve(board.tiles, board.mask, [], 20000)
			check(result.status == "SOLVED", prefix + " independent solver within budget")
			if result.visited > maximum_nodes:
				maximum_nodes = result.visited
				worst_seed = seed_value
			if result.status == "SOLVED":
				verify_path(board.tiles, result.path, prefix + " solver")
	var board := RULES.generate(701, 1)
	var covered := -1
	for tile in board.tiles:
		if tile.cover != 0:
			covered = tile.id
			break
	check(not RULES.take(board.tiles, board.mask, [], covered).valid, "Covered tile cannot enter tray")
	var id: int = RULES.available(board.tiles, board.mask)[0]
	var move := RULES.take(board.tiles, board.mask, [], id)
	check(not RULES.take(board.tiles, move.mask, move.tray, id).valid, "Repeated pick cannot duplicate tile")
	check(not RULES.valid_state(board.tiles, board.mask, [id]), "A tile cannot exist on board and in tray")
	check(not RULES.valid_state(board.tiles, 0, [1.5]), "Fractional corrupted tile id is rejected")
	# A seventh insertion that completes a trio is safe; an unmatched seventh loses.
	var fixture: Array = []
	for i in range(9):
		fixture.append({"id": i, "kind": [0, 0, 1, 1, 2, 2, 0, 3, 4][i], "cover": 0})
	var seventh := RULES.take(fixture, 1 << 6, [0, 1, 2, 3, 4, 5], 6)
	check(seventh.matched.size() == 3 and seventh.tray.size() == 4 and not seventh.lost, "Seventh matching pick clears before capacity check")
	var full := RULES.take(fixture, 1 << 7, [0, 1, 2, 3, 4, 5], 7)
	check(full.tray.size() == 7 and full.lost, "Seventh unmatched pick is a real loss")
	var report := {"suite": "Tile Trio construction and independent solver", "boards": 1500,
		"seeds": [1, 500], "levels": [1, 4, 10], "checks": checks, "failures": failures,
		"maximum_search_nodes": maximum_nodes, "worst_seed": worst_seed,
		"elapsed_ms": Time.get_ticks_msec() - start_time,
		"status": "PASS" if failures.is_empty() else "FAIL"}
	var output := FileAccess.open("res://docs/evidence/trio-solver-tests.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "  ") + "\n")
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
