class_name BubbleRules
extends RefCounted

const COLS := 9
const ROWS := 14

static func neighbors(cell: Vector2i) -> Array[Vector2i]:
	var side := 1 if cell.y % 2 == 1 else -1
	var candidates: Array[Vector2i] = [cell + Vector2i(-1, 0), cell + Vector2i(1, 0),
		cell + Vector2i(0, -1), cell + Vector2i(side, -1), cell + Vector2i(0, 1), cell + Vector2i(side, 1)]
	var result: Array[Vector2i] = []
	for other in candidates:
		if other.x >= 0 and other.x < COLS and other.y >= 0 and other.y < ROWS:
			result.append(other)
	return result

static func cluster(grid: Dictionary, start: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if not grid.has(start):
		return result
	var pending: Array[Vector2i] = [start]
	var seen := {start: true}
	while not pending.is_empty():
		var cell: Vector2i = pending.pop_back()
		result.append(cell)
		for neighbor in neighbors(cell):
			if not seen.has(neighbor) and grid.get(neighbor, -1) == grid[start]:
				seen[neighbor] = true
				pending.append(neighbor)
	return result

static func floating(grid: Dictionary) -> Array[Vector2i]:
	var pending: Array[Vector2i] = []
	var connected: Dictionary = {}
	for cell in grid:
		if cell.y == 0:
			pending.append(cell)
			connected[cell] = true
	while not pending.is_empty():
		var cell: Vector2i = pending.pop_back()
		for other in neighbors(cell):
			if grid.has(other) and not connected.has(other):
				connected[other] = true
				pending.append(other)
	var result: Array[Vector2i] = []
	for cell in grid:
		if not connected.has(cell):
			result.append(cell)
	return result

static func colors(grid: Dictionary) -> Array[int]:
	var result: Array[int] = []
	for value in grid.values():
		if not int(value) in result:
			result.append(int(value))
	result.sort()
	return result

static func segment_circle(from: Vector2, to: Vector2, center: Vector2, radius: float) -> float:
	return MochiSweep.circle(from, to, center, radius)
