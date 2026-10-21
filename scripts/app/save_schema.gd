class_name MochiSaveSchema
extends RefCounted
## Reject structurally damaged local rounds before any numeric cast or scene use.
## Gameplay-specific invariants (solvability, legal trays, reachability) stay in games.

static func number(value: Variant, low: float = -1000000000, high: float = 1000000000, integer: bool = false) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= low and value <= high and (not integer or value == floor(value))

static func integer_text(value: Variant) -> bool:
	return (value is String and value.is_valid_int() and str(int(value)) == value) or number(value, -9007199254740991, 9007199254740991, true)

static func tuple(value: Variant, length: int) -> bool:
	if not value is Array or value.size() != length:
		return false
	for item in value:
		if not number(item):
			return false
	return true

static func fields(value: Variant, required: Array, optional: Array = []) -> bool:
	if not value is Dictionary or not value.has_all(required):
		return false
	for key in required + optional:
		if value.has(key) and not number(value[key]):
			return false
	return true

static func board(value: Variant) -> bool:
	if not value is Array or value.size() != 16:
		return false
	var occupied := false
	for item in value:
		if not number(item, 0, 1048576, true):
			return false
		var n := int(item)
		if n > 0:
			if n < 2 or n & (n - 1):
				return false
			occupied = true
	return occupied

static func platform(value: Variant) -> bool:
	return value is Dictionary and tuple(value.get("center"), 2) and fields(value, ["radius", "kind"])

static func trio_state(value: Variant) -> bool:
	if not value is Dictionary or not integer_text(value.get("mask")) or not value.get("tray") is Array or value.tray.size() > 7:
		return false
	if int(value.mask) < 0 or int(value.mask) >= 1 << 36 or not number(value.get("score", 0), 0, 9007199254740991, true):
		return false
	for id in value.tray:
		if not number(id, 0, 35, true):
			return false
	return true

static func session(id: String, value: Variant) -> bool:
	if not value is Dictionary:
		return false
	if value.is_empty():
		return true
	for key in ["score", "seed", "tier", "combo", "landed", "stage", "wave", "missed", "sliced", "launched", "next", "shot"]:
		if value.has(key) and not number(value[key], 0, 9007199254740991, true):
			return false
	for key in ["time", "paddle", "clear", "spawn_time"]:
		if value.has(key) and not number(value[key], 0, 1000000000):
			return false
	if value.has("rng") and not integer_text(value.rng):
		return false
	match id:
		"cake_stack":
			if not value.get("layers") is Array or value.layers.is_empty() or value.layers.size() > 24:
				return false
			for layer in value.layers:
				if not fields(layer, ["x", "w", "tier"]) or not number(layer.w, 0.01, 320) or not number(layer.tier, 0, 1000000000, true):
					return false
		"number_bloom":
			if not board(value.get("board")) or not value.get("won", false) is bool or not value.get("undo", {}) is Dictionary:
				return false
			var undo: Dictionary = value.get("undo", {})
			if not undo.is_empty() and (not board(undo.get("board")) or not number(undo.get("score"), 0, 9007199254740991, true) or not integer_text(undo.get("rng")) or not undo.get("won") is bool):
				return false
		"fruit_drop":
			if not value.get("fruit") is Array or value.fruit.size() > 256 or not value.has("score"):
				return false
			for item in value.fruit:
				if not fields(item, ["level", "x", "y"], ["vx", "vy", "angle"]) or not number(item.level, 0, 7, true):
					return false
		"bubble_garden":
			if not value.get("grid") is Array or value.grid.size() > 126:
				return false
			var seen := {}
			for cell in value.grid:
				if not tuple(cell, 3) or not number(cell[0], 0, 8, true) or not number(cell[1], 0, 13, true) or not number(cell[2], 0, 4, true):
					return false
				var key := Vector2i(int(cell[0]), int(cell[1]))
				if seen.has(key):
					return false
				seen[key] = true
		"mochi_hop":
			if not platform(value.get("current")) or not platform(value.get("target")) or not tuple(value.get("foot"), 2):
				return false
		"tile_trio":
			if not trio_state(value) or not value.get("history", []) is Array or value.get("history", []).size() > 36:
				return false
			for state in value.get("history", []):
				if not trio_state(state):
					return false
		"bouncy_balls":
			if not value.get("balls") is Array or value.balls.size() > 64 or not tuple(value.get("health"), 24):
				return false
			for ball in value.balls:
				if not tuple(ball, 6):
					return false
			if value.has("area") and not tuple(value.area, 2):
				return false
		"jelly_slice":
			if not value.get("fruit") is Array or value.fruit.size() > 12:
				return false
			for item in value.fruit:
				if not tuple(item, 8):
					return false
	return true
