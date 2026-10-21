extends SceneTree
const RULES := preload("res://scripts/games/hop_rules.gd")
var checks := 0
var failures: Array[String] = []
var failure_count := 0
var smallest_window := INF
var smallest_seed := -1

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failure_count += 1
		if failures.size() < 30:
			failures.append(message)
			push_error(message)

func run() -> void:
	check(RULES.distance(-1) == 70 and RULES.distance(0) == 70, "Short hold is clamped")
	check(RULES.distance(10) == 350 and RULES.distance(1.2) == 350, "Long hold is capped without auto jump")
	check(RULES.distance(0.6) == 210, "Half hold has stable distance")
	for seed_value in range(1, 2001):
		var random := RandomNumberGenerator.new()
		random.seed = seed_value
		var center := Vector2.ZERO
		var from := Vector2.ZERO
		for step in range(25):
			var target := RULES.next_platform(random, center, from, step * 3)
			var interval := RULES.charge_interval(from, target.center, target.radius)
			var prefix := "seed=" + str(seed_value) + " step=" + str(step)
			var width := interval.y - interval.x
			if width < smallest_window:
				smallest_window = width
				smallest_seed = seed_value
			# Vector2 endpoints are float32: exact 1.2 stores as 1.2000000477.
			check(interval.x >= 0 and (interval.y <= RULES.MAX_HOLD or is_equal_approx(interval.y, RULES.MAX_HOLD)) and width >= RULES.MIN_WINDOW, prefix + " reachable hold interval")
			var direction := from.direction_to(target.center)
			for hold in [interval.x + 0.001, (interval.x + interval.y) / 2, interval.y - 0.001]:
				var point := from + direction * RULES.distance(hold)
				var result := RULES.landing(point, target, 2)
				check(result.success, prefix + " sampled foot is landable")
				# Independent world-circle oracle, plus its actual projected ellipse.
				var displacement: Vector2 = point - target.center
				check(displacement.length() <= target.radius + 6.001, prefix + " analytic world distance")
				var screen := RULES.project(displacement)
				var normalized := Vector2(screen.x / (sqrt(2.0) * target.radius), screen.y / (sqrt(2.0) * target.radius * 0.5)).length()
				check(absf(normalized - displacement.length() / target.radius) < 0.0001, prefix + " projected foot and visible top agree")
			var center_hold := RULES.hold_for_distance(from.distance_to(target.center))
			var perfect := RULES.landing(from + direction * RULES.distance(center_hold), target, 2)
			check(perfect.perfect and perfect.points == 5, prefix + " center charge and combo")
			# Carry an edge-biased previous landing into the next generation, not just centers.
			var selected_hold := lerpf(interval.x, interval.y, 0.06 if step % 2 == 0 else 0.94)
			from = RULES.landing(from + direction * RULES.distance(selected_hold), target, 0).foot
			center = target.center
	var platform := {"center": Vector2(220, 0), "radius": 60.0, "kind": 0}
	check(RULES.landing(Vector2(286, 0), platform, 3).success, "Explicit six-unit edge forgiveness")
	check(not RULES.landing(Vector2(286.1, 0), platform, 3).success, "Beyond forgiveness is a miss")
	check(RULES.landing(Vector2(234, 0), platform, 4).points == 7, "Perfect streak capped at seven points")
	check(RULES.landing(Vector2(235, 0), platform, 4).points == 1, "Ordinary edge resets streak")
	check(RULES.arc_height(0) == 0 and RULES.arc_height(1) == 0 and RULES.arc_height(0.5) == 125, "Parabolic altitude is independent of landing plane")
	var report := {"suite": "Mochi Hop seed reachability", "seeds": 2000, "platforms": 50000,
		"seed_range": [1, 2000], "checks": checks, "failure_count": failure_count, "failures": failures,
		"minimum_charge_window_seconds": smallest_window, "minimum_window_seed": smallest_seed,
		"method": "25 platforms per seed across capped difficulty; both hold edges + midpoint, independent distance/ellipse oracle, edge-biased prior footing.",
		"status": "PASS" if failures.is_empty() else "FAIL"}
	var output := FileAccess.open("res://docs/evidence/hop-reachability-tests.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "  ") + "\n")
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
