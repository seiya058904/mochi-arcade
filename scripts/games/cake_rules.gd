class_name CakeRules
extends RefCounted

static func overlap(previous_x: float, previous_width: float, moving_x: float, tolerance: float = 8.0) -> Dictionary:
	if absf(previous_x - moving_x) <= tolerance:
		return {"hit": true, "perfect": true, "x": previous_x, "width": previous_width, "cut_x": moving_x, "cut_width": 0.0}
	var left := maxf(previous_x, moving_x)
	var right := minf(previous_x + previous_width, moving_x + previous_width)
	var width := maxf(0.0, right - left)
	return {"hit": width > 0.0, "perfect": false, "x": left, "width": width,
		"cut_x": moving_x if moving_x < previous_x else right, "cut_width": previous_width - width}

static func position_at(time: float, width: float, arena_width: float, speed: float) -> float:
	var span := maxf(1.0, arena_width - width - 24.0)
	return 12.0 + absf(fposmod(time * speed, span * 2.0) - span)
