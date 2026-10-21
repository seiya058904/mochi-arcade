class_name HopRules
extends RefCounted

const MIN_DISTANCE := 70.0
const MAX_DISTANCE := 350.0
const MAX_HOLD := 1.2
const EDGE_MARGIN := 6.0
const PERFECT_RADIUS := 14.0
const MIN_WINDOW := 0.18

static func distance(held: float) -> float:
	return lerpf(MIN_DISTANCE, MAX_DISTANCE, clampf(held / MAX_HOLD, 0, 1))

static func hold_for_distance(length: float) -> float:
	return (length - MIN_DISTANCE) / (MAX_DISTANCE - MIN_DISTANCE) * MAX_HOLD

static func project(point: Vector2) -> Vector2:
	return Vector2(point.x - point.y, -(point.x + point.y) * 0.5)

static func charge_interval(from: Vector2, target: Vector2, radius: float) -> Vector2:
	var gap := from.distance_to(target)
	var low := maxf(MIN_DISTANCE, gap - radius - EDGE_MARGIN)
	var high := minf(MAX_DISTANCE, gap + radius + EDGE_MARGIN)
	if low > high:
		return Vector2(-1, -1)
	return Vector2(hold_for_distance(low), hold_for_distance(high))

static func next_platform(random: RandomNumberGenerator, current: Vector2, from: Vector2, count: int) -> Dictionary:
	var radius := maxf(48, 62 - count * 0.35)
	var progress := minf(count / 45.0, 1.0)
	for _attempt in range(16):
		var direction := Vector2.RIGHT if random.randi_range(0, 1) == 0 else Vector2.DOWN
		var center := current + direction * random.randf_range(175 + progress * 25, 230 + progress * 40)
		var interval := charge_interval(from, center, radius)
		if interval.y - interval.x >= MIN_WINDOW:
			return {"center": center, "radius": radius, "kind": random.randi_range(0, 3)}
	# Deterministic safety fallback still has a large, measurable hold interval.
	return {"center": from + Vector2.RIGHT * 220, "radius": radius, "kind": random.randi_range(0, 3)}

static func landing(point: Vector2, platform: Dictionary, combo: int) -> Dictionary:
	var offset: Vector2 = point - platform.center
	var error := offset.length()
	var radius: float = platform.radius
	if error > radius + EDGE_MARGIN + 0.0001:
		return {"success": false, "perfect": false, "points": 0, "combo": 0, "foot": point}
	var perfect := error <= PERFECT_RADIUS + 0.0001
	var streak := mini(5, combo + 1) if perfect else 0
	var foot: Vector2 = platform.center if perfect else platform.center + offset.limit_length(radius - 4)
	return {"success": true, "perfect": perfect, "points": 2 + streak if perfect else 1, "combo": streak, "foot": foot}

static func ground_position(from: Vector2, to: Vector2, progress: float) -> Vector2:
	return from.lerp(to, clampf(progress, 0, 1))

static func arc_height(progress: float, height: float = 125.0) -> float:
	var t := clampf(progress, 0, 1)
	return 4 * height * t * (1 - t)
