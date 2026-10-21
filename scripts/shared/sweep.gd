class_name MochiSweep
extends RefCounted
## Continuous segment queries in logical canvas coordinates.

static func circle(from: Vector2, to: Vector2, center: Vector2, radius: float) -> float:
	var offset := from - center
	var movement := to - from
	var a := movement.length_squared()
	if offset.length_squared() <= radius * radius:
		return 0.0
	if a <= 0.00001:
		return INF
	var b := 2.0 * offset.dot(movement)
	var c := offset.length_squared() - radius * radius
	var discriminant := b * b - 4.0 * a * c
	if discriminant < 0:
		return INF
	var t := (-b - sqrt(discriminant)) / (2.0 * a)
	return t if t >= 0 and t <= 1 else INF

static func rounded_box(from: Vector2, to: Vector2, rect: Rect2, radius: float) -> Dictionary:
	# Minkowski sum of the rectangle and circle: four faces plus four round
	# corners. A merely expanded AABB incorrectly collides at empty corners.
	var result := {"time": INF, "normal": Vector2.ZERO}
	if not Rect2(from, Vector2.ZERO).expand(to).intersects(rect.grow(radius), true):
		return result
	var movement := to - from
	var faces := [
		[Vector2.LEFT, rect.position.x - radius, true],
		[Vector2.RIGHT, rect.end.x + radius, true],
		[Vector2.UP, rect.position.y - radius, false],
		[Vector2.DOWN, rect.end.y + radius, false]]
	for face in faces:
		var normal: Vector2 = face[0]
		if movement.dot(normal) >= -0.000001:
			continue
		var vertical: bool = face[2]
		var t: float = (face[1] - (from.x if vertical else from.y)) / (movement.x if vertical else movement.y)
		if t < 0 or t > 1 or t >= result.time:
			continue
		var point := from.lerp(to, t)
		if (vertical and point.y >= rect.position.y and point.y <= rect.end.y) or (not vertical and point.x >= rect.position.x and point.x <= rect.end.x):
			result = {"time": t, "normal": normal}
	if radius > 0:
		for corner in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
			var t := circle(from, to, corner, radius)
			if t >= result.time:
				continue
			var point := from.lerp(to, t)
			var normal: Vector2 = (point - corner).normalized()
			var outside_x: bool = point.x <= rect.position.x if corner.x == rect.position.x else point.x >= rect.end.x
			var outside_y: bool = point.y <= rect.position.y if corner.y == rect.position.y else point.y >= rect.end.y
			if outside_x and outside_y and movement.dot(normal) < -0.000001:
				result = {"time": t, "normal": normal}
	return result
