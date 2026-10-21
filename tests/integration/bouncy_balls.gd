extends SceneTree
const SWEEP := preload("res://scripts/shared/sweep.gd")
var checks := 0
var failures: Array[String] = []
var app: Control

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		if failures.size() <= 15:
			push_error(message)

func fresh() -> Node:
	app.open_game(3, true, 881)
	app.resume()
	app.game.set_physics_process(false)
	return app.game

func empty_pool(game: Node) -> void:
	for ball in game.pool:
		ball.active = false

func run() -> void:
	root.size = Vector2i(450, 800)
	var save = root.get_node("Save")
	save.folder = "user://qa-balls-" + str(int(Time.get_unix_time_from_system() * 1000000)) + "-" + str(OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(save.folder)
	save.data = save.defaults()
	save.data.settings.music = false
	save.data.settings.sfx = false
	root.get_node("Sound").apply_settings()
	app = load("res://scenes/app/main.tscn").instantiate()
	root.add_child(app)
	var rect := Rect2(100, 100, 100, 50)
	var hit := SWEEP.rounded_box(Vector2(0, 125), Vector2(500, 125), rect, 10)
	check(is_equal_approx(hit.time, 0.18) and hit.normal == Vector2.LEFT, "Continuous sweep catches a thin brick across 500 px")
	hit = SWEEP.rounded_box(Vector2(90, 90), Vector2(95, 90), rect, 10)
	check(hit.time == INF, "Empty expanded-AABB corner does not falsely collide")
	hit = SWEEP.rounded_box(Vector2(0, 0), Vector2(200, 200), rect, 10)
	check(absf(hit.time - (100 - 10 / sqrt(2.0)) / 200) < 0.00001 and hit.normal.is_equal_approx(Vector2(-1, -1).normalized()), "Rounded corner uses true circle contact and diagonal normal")
	check(SWEEP.rounded_box(Vector2(90, 125), Vector2(50, 125), rect, 10).time == INF, "A ball moving away from contact cannot bounce twice")
	var random := RandomNumberGenerator.new()
	random.seed = 1002
	for case_id in range(1000):
		var start := Vector2(random.randf_range(-200, 300), random.randf_range(-200, 300))
		if rect.grow(10).has_point(start):
			start.x = -100
		var end := Vector2(random.randf_range(-200, 400), random.randf_range(-200, 300))
		hit = SWEEP.rounded_box(start, end, rect, 10)
		if hit.time <= 1:
			var point := start.lerp(end, hit.time)
			var closest := Vector2(clampf(point.x, rect.position.x, rect.end.x), clampf(point.y, rect.position.y, rect.end.y))
			check(absf(point.distance_to(closest) - 10) < 0.002 and (end - start).dot(hit.normal) < 0, "Random sweep contact agrees with independent nearest-rectangle oracle " + str(case_id))
		else:
			var crossed := false
			for sample in range(201):
				var point := start.lerp(end, sample / 200.0)
				var closest := Vector2(clampf(point.x, 100, 200), clampf(point.y, 100, 150))
				if point.distance_to(closest) < 9.99:
					crossed = true
			check(not crossed, "No-hit sweep has no sampled intersection " + str(case_id))
	var game := fresh()
	var regression_normal := Vector2(-0.13369, -0.991023).normalized()
	check(game.rebound(Vector2(-507.9101, 136.76), regression_normal).dot(regression_normal) > 0, "Preserved stress failure: grazing anti-horizontal correction must point away from the bumper")
	for sample in range(2000):
		var normal := Vector2.from_angle(random.randf_range(-PI, PI))
		var incoming: Vector2 = -normal.rotated(random.randf_range(-1.56, 1.56)) * game.speed()
		var bounced: Vector2 = game.rebound(incoming, normal)
		check(bounced.dot(normal) > 0 and absf(bounced.y) >= game.speed() * 0.259, "Curved rebounds always leave the surface with a vertical component " + str(sample))
	check(game.active_count() == 1 and game.pool.size() == 64 and game.bricks_left() == 24, "Fresh game has one ball, 24 bricks and a fixed 64-slot pool")
	game.press(Vector2(-10000, 100))
	check(is_equal_approx(game.paddle_rect().position.x, 18), "Paddle clamps at left rail")
	game.drag(Vector2(10000, 100))
	check(is_equal_approx(game.paddle_rect().end.x, game.area.x - 18), "Paddle clamps at right rail")
	empty_pool(game)
	game.spawn(game.gates[0].get_center() + Vector2(0, 70), Vector2.UP, 0)
	game._physics_process(0.3)
	check(game.active_count() == 2 and game.gate_passes[0] == 1, "Crossing x2 creates a real second active ball")
	game.multiply(0, 0)
	game.multiply(1, 0)
	check(game.active_count() == 2 and game.gate_passes[0] == 1, "Parent and child both retain the gate claim")
	for i in range(2):
		game.pool[i].p = game.gates[1].get_center() + Vector2(0, 70)
		game.pool[i].v = Vector2.UP * game.speed()
	game._physics_process(0.3)
	check(game.active_count() == 6 and game.gate_passes[1] == 2, "Two balls crossing x3 create four independent children")
	check(game.pool[0].v != game.pool[2].v and game.pool[0].p != game.pool[2].p, "Children have distinct trajectories and wait until the next tick")
	empty_pool(game)
	for i in range(63):
		game.spawn(Vector2(300, 600), Vector2.UP, 0)
	var before: int = game.score
	game.multiply(0, 1)
	check(game.active_count() == 64 and game.pool.size() == 64 and game.denied == 1 and game.score == before + 5, "Saturated x3 fills one slot and converts the other to exactly five points")
	game.multiply(1, 1)
	check(game.active_count() == 64 and game.denied == 3 and game.score == before + 15, "Full pool cannot grow; both extra children become points")
	game = fresh()
	empty_pool(game)
	game.spawn(Vector2(game.paddle_x + 50, game.paddle_y() - 90), Vector2.DOWN, 3)
	game._physics_process(0.3)
	check(game.catches == 1 and game.pool[0].v.y < 0 and game.pool[0].v.x > 0, "Paddle catches a swept ball and steers by contact offset")
	var endpoints: Array = []
	for fps in [30, 60, 120]:
		game = fresh()
		empty_pool(game)
		game.spawn(Vector2(game.paddle_x + 25, game.paddle_y() - 90), Vector2.DOWN, 3)
		for frame in range(fps / 2):
			game._physics_process(1.0 / fps)
		endpoints.append(game.pool[0].p)
	check(endpoints[0].distance_to(endpoints[1]) < 0.02 and endpoints[0].distance_to(endpoints[2]) < 0.02, "Paddle endpoint agrees at 30/60/120 Hz")
	game = fresh()
	empty_pool(game)
	game.spawn(Vector2(120, 300), Vector2.UP, 3)
	game._physics_process(0.25)
	check(game.brick_hits == 1 and game.score == 25 and game.pool[0].v.y > 0, "A swept brick hit scores once and rebounds without tunneling")
	game = fresh()
	empty_pool(game)
	game.spawn(game.bumpers[0] + Vector2(-80, 0), Vector2.RIGHT, 3)
	game.pool[0].v = Vector2.RIGHT * game.speed()
	game._physics_process(0.2)
	check(game.bumper_hits == 1 and game.pool[0].v.x < 0 and absf(game.pool[0].v.y) >= game.speed() * 0.259, "Round bumper rebounds and repairs horizontal trapping")
	var position: Vector2 = game.pool[0].p
	game.set_suspended(true)
	game._physics_process(10)
	game.drag(Vector2.ZERO)
	check(game.pool[0].p == position and game.collision_limit_hits == 0, "Pause freezes the pool and prevents catch-up simulation")
	game.set_suspended(false)
	game.set_physics_process(false)
	game.checkpoint()
	var saved: Dictionary = save.session("bouncy_balls")
	app.leave_game()
	app.open_game(3)
	app.resume()
	game = app.game
	game.set_physics_process(false)
	check(game.pool[0].p.distance_to(position) < 0.001 and game.score == saved.score and game.pool[0].gates == 3, "Reload preserves positions, score, bricks and consumed gates")
	saved.area = [360, 999]
	app.leave_game()
	save.data.sessions["bouncy_balls"] = saved
	app.open_game(3)
	app.resume()
	game = app.game
	game.set_physics_process(false)
	check(game.pool[0].p == Vector2(game.paddle_x, game.paddle_y() - 25) and game.pool[0].v.y < 0 and game.pool[0].gates == 3 and game.score == saved.score, "Changed viewport recalls survivors below new geometry, preserving progress and gate claims")
	# One final brick contact and one lost ball in the same update: clear wins.
	for brick in game.bricks:
		brick.hp = 0
	game.bricks[18].hp = 1
	empty_pool(game)
	game.spawn(Vector2(70, 300), Vector2.UP, 3)
	game.spawn(Vector2(300, game.area.y + 10), Vector2.DOWN, 3)
	game._physics_process(0.2)
	check(game.clear_time > 0 and not game.stopped and game.active_count() == 1, "Last brick clear takes precedence over a simultaneous lost ball")
	var clear_score: int = game.score
	game.checkpoint()
	app.leave_game()
	app.open_game(3)
	app.resume()
	game = app.game
	game.set_physics_process(false)
	game._physics_process(0.7)
	check(game.wave == 2 and game.score == clear_score and game.bricks_left() == 24 and game.pool[0].gates == 0, "Mid-clear reload advances once, resets gates and does not duplicate bonus")
	empty_pool(game)
	game.spawn(Vector2(40, game.area.y + 10), Vector2.DOWN, 3)
	game._physics_process(0.1)
	check(game.stopped and game.active_count() == 0 and is_instance_valid(app.overlay), "Losing every ball gives real results")
	app.restart()
	game = app.game
	game.set_physics_process(false)
	check(not game.stopped and game.wave == 1 and game.active_count() == 1 and game.score == 0, "Result retry starts a playable new rally")
	var old_game: WeakRef = weakref(game)
	app.leave_game()
	await process_frame
	check(old_game.get_ref() == null, "Leaving frees the entire pool with no ghost nodes")
	# Sustained fixture: maintain 64 live balls for 60 simulated seconds. These
	# replenishments are a load test, deliberately separate from normal play.
	game = fresh()
	empty_pool(game)
	await process_frame
	var node_count := get_node_count()
	var times: Array[int] = []
	var stress_max := 0
	for frame in range(3600):
		for slot in game.pool:
			if not slot.active:
				game.spawn(Vector2(random.randf_range(60, game.area.x - 60), game.paddle_y() - 25), Vector2(random.randf_range(-0.8, 0.8), -1), 0)
		game.drag(Vector2(game.area.x * (0.5 + 0.3 * sin(frame * 0.02)), 0))
		var start := Time.get_ticks_usec()
		game._physics_process(1.0 / 60)
		times.append(Time.get_ticks_usec() - start)
		stress_max = maxi(stress_max, game.active_count())
		check(game.pool.size() == 64 and game.active_count() <= 64 and game.particles.size() <= 64, "Bounded stress pool/effects at frame " + str(frame))
		for ball in game.pool:
			if ball.active:
				check(ball.p.is_finite() and ball.v.is_finite() and ball.v.length() <= 540.01 and absf(ball.v.y) >= game.speed() * 0.259, "Finite bounded motion under sustained load " + str(frame))
		if frame % 30 == 0:
			await process_frame # Drain normal queue_free work, including replaced wave toasts.
	times.sort()
	await process_frame
	check(stress_max == 64 and get_node_count() <= node_count + 1 and game.collision_limit_hits == 0, "64-ball stress retains only the one shared wave-toast label and exhausts no collision iterations")
	var report := {"status": "PASS" if failures.is_empty() else "FAIL", "checks": checks, "failures": failures,
		"preserved_adverse_sample": {"initial_collision_limit_hits": 7, "normal": [-0.13369, -0.991023], "incoming": [-507.9101, 136.76], "cause": "Minimum vertical speed restored inward velocity after grazing bumper reflection", "fix": "Outward-normal validation after speed correction, normal separation epsilon; 2000 additional curved contacts"},
		"stress": {"simulated_seconds": 60, "maintained_pool_fixture": true, "max_balls": stress_max, "pool_size": game.pool.size(), "collision_limit_hits": game.collision_limit_hits,
		"nodes_before": node_count, "nodes_after": get_node_count(), "allowed_ui_toast_nodes": 1, "physics_us_p50": times[1800], "physics_us_p95": times[3420], "physics_us_max": times.back(), "scope": "Windows headless GDScript simulation only; not Android FPS or rendering performance"}}
	var output := FileAccess.open("res://docs/evidence/bouncy-balls-tests.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "  ") + "\n")
	print(JSON.stringify(report))
	await root.get_node("Sound").shutdown()
	app.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
