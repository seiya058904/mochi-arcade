extends SceneTree

const BLOOM := preload("res://scripts/games/bloom_rules.gd")
const CAKE := preload("res://scripts/games/cake_rules.gd")
var checks := 0
var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	# The logic suite exercises no audio. Stop the autoload before the dummy
	# headless audio backend shuts down, and let the playback reference drain.
	root.get_node("Sound").music.stop()
	root.get_node("Sound").music.stream = null
	await process_frame
	var rows := [
		[[2, 2, 2, 2], [4, 4, 0, 0], 8],
		[[4, 4, 8, 8], [8, 16, 0, 0], 24],
		[[2, 2, 4, 0], [4, 4, 0, 0], 4],
		[[4, 0, 4, 4], [8, 4, 0, 0], 8],
		[[0, 0, 0, 0], [0, 0, 0, 0], 0],
		[[2, 4, 8, 16], [2, 4, 8, 16], 0],
		[[0, 2, 0, 2], [4, 0, 0, 0], 4],
		[[1024, 1024, 2048, 2048], [2048, 4096, 0, 0], 6144]]
	for row in rows:
		var actual := BLOOM.slide_line(row[0])
		check(actual.line == row[1] and actual.score == row[2], "2048 canonical row " + str(row[0]))
	var values := [0, 2, 4, 8, 16]
	for a in values:
		for b in values:
			for c in values:
				for d in values:
					var line := [a, b, c, d]
					var result := BLOOM.slide_line(line)
					check(result.line.reduce(func(x, y): return x + y, 0) == a + b + c + d, "2048 mass conservation " + str(line))
					var zeros_seen := false
					var compact := true
					for n in result.line:
						if n == 0: zeros_seen = true
						elif zeros_seen: compact = false
					check(compact, "2048 no gaps " + str(line))
	var sample := [2, 2, 2, 2, 0, 4, 4, 0, 0, 0, 0, 0, 2, 4, 8, 16]
	check(BLOOM.move(sample, 0).board == [4, 4, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 2, 4, 8, 16], "2048 horizontal board")
	check(BLOOM.move(sample, 1).board == [0, 0, 4, 4, 0, 0, 0, 8, 0, 0, 0, 0, 2, 4, 8, 16], "2048 reversed board")
	var column := [2, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0]
	check(BLOOM.move(column, 2).board == [4, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], "2048 vertical single merge")
	var blocked := [2, 4, 2, 4, 4, 2, 4, 2, 2, 4, 2, 4, 4, 2, 4, 2]
	check(not BLOOM.can_move(blocked), "2048 terminal board")
	for direction in range(4):
		check(not BLOOM.move(blocked, direction).changed, "2048 invalid move " + str(direction))
	var rng := RandomNumberGenerator.new()
	rng.seed = 44281
	var fours := 0
	for i in range(10000):
		var empty: Array = []
		empty.resize(16)
		empty.fill(0)
		var index := BLOOM.spawn(empty, rng)
		check(index >= 0 and empty.count(0) == 15 and empty[index] in [2, 4], "2048 spawn " + str(i))
		if empty[index] == 4: fours += 1
	check(fours > 850 and fours < 1150, "2048 90/10 distribution: fours=" + str(fours))
	check(BLOOM.spawn(blocked, rng) == -1, "2048 no spawn into full board")
	check(CAKE.overlap(100, 300, 106).perfect, "Cake perfect tolerance inclusive")
	check(not CAKE.overlap(100, 300, 109).perfect, "Cake outside perfect tolerance")
	check(CAKE.overlap(100, 300, 150).width == 250.0, "Cake right cut")
	check(CAKE.overlap(100, 300, 50).x == 100.0 and CAKE.overlap(100, 300, 50).width == 250.0, "Cake left cut")
	check(not CAKE.overlap(100, 300, 400).hit, "Cake edge-only contact is a miss")
	check(not CAKE.overlap(100, 300, 800).hit, "Cake full miss")
	for x in range(-500, 1000):
		var result := CAKE.overlap(100, 300, x)
		check(result.width >= 0 and result.width <= 300, "Cake bounded width " + str(x))
		check(is_equal_approx(result.width + result.cut_width, 300), "Cake cut conservation " + str(x))
	await save_tests()
	var report := {"suite": "logic", "checks": checks, "failures": failures, "status": "PASS" if failures.is_empty() else "FAIL", "engine": Engine.get_version_info().string, "spawn_four_count": fours}
	print(JSON.stringify(report))
	if DirAccess.dir_exists_absolute("res://docs/evidence"):
		var output := FileAccess.open("res://docs/evidence/logic-tests.json", FileAccess.WRITE)
		output.store_string(JSON.stringify(report, "  ") + "\n")
	quit(0 if failures.is_empty() else 1)

func save_tests() -> void:
	var save = root.get_node("Save")
	var original_folder: String = save.folder
	var original_data: Dictionary = save.data.duplicate(true)
	var test_folder := "user://qa-save-" + str(int(Time.get_unix_time_from_system() * 1000000)) + "-" + str(OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(test_folder)
	save.folder = test_folder
	save.data = save.defaults()
	save.data.records["cake_stack"] = 28
	check(save.flush() == OK, "Save initial atomic write")
	save.data.records["cake_stack"] = 39
	check(save.flush() == OK, "Save backup rotation")
	save.load_save()
	check(save.best("cake_stack") == 39, "Save round trip")
	var corrupt := FileAccess.open(test_folder.path_join("save.json"), FileAccess.WRITE)
	corrupt.store_string("{corrupt")
	corrupt.close()
	save.load_save()
	check(save.recovered and save.best("cake_stack") == 28, "Save corrupted primary recovers previous valid backup")
	save.folder = original_folder
	save.data = original_data
	await process_frame
