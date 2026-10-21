class_name FruitRules
extends RefCounted

const RADII := [22.0, 29.0, 37.0, 47.0, 59.0, 73.0, 90.0, 109.0]

static func claim(a: int, b: int, a_level: int, b_level: int, claimed: Dictionary) -> bool:
	if a == b or a_level != b_level or claimed.has(a) or claimed.has(b):
		return false
	claimed[a] = true
	claimed[b] = true
	return true

static func merge_score(level: int) -> int:
	return 10 * (1 << (level + 1))

static func overflow(top: float, speed: float, age: float, line: float) -> bool:
	return top < line and age > 1.8 and speed < 90.0
