class_name TrioRules
extends RefCounted

const CAPACITY := 7
const TILE_SIZE := Vector2(88, 96)
const BOARD_SIZE := Vector2(488, 396)
const TILE_COUNT := 36

static func all_mask() -> int:
	return (1 << TILE_COUNT) - 1

static func selectable(tiles: Array, mask: int, id: int) -> bool:
	return id >= 0 and id < tiles.size() and (mask & (1 << id)) != 0 and (mask & int(tiles[id].cover)) == 0

static func available(tiles: Array, mask: int) -> Array[int]:
	var result: Array[int] = []
	for id in range(tiles.size()):
		if selectable(tiles, mask, id):
			result.append(id)
	return result

static func generate(seed_value: int, level: int) -> Dictionary:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value + level * 104729
	var tiles: Array[Dictionary] = []
	for layer in range(3):
		var columns: int = [5, 4, 2][layer]
		var rows: int = [4, 3, 2][layer]
		var shift: Vector2 = [Vector2.ZERO, Vector2(50, 38), Vector2(100 + random.randi_range(0, 1) * 100, 88)][layer]
		for row in range(rows):
			for col in range(columns):
				tiles.append({"id": tiles.size(), "kind": -1, "layer": layer,
					"rect": Rect2(Vector2(col * 100, row * 100) + shift, TILE_SIZE), "cover": 0})
	for tile in tiles:
		for other in tiles:
			if other.layer > tile.layer and tile.rect.intersects(other.rect):
				tile.cover |= 1 << int(other.id)
	# Construct a legal removal order first. Assign each consecutive triple its
	# motif afterward: following this witness can never fill a seven-slot tray.
	var mask := all_mask()
	var witness: Array[int] = []
	while mask != 0:
		var choices := available(tiles, mask)
		var id := choices[random.randi_range(0, choices.size() - 1)]
		witness.append(id)
		mask &= ~(1 << id)
	var kind_count := mini(8, 6 + (level - 1) / 3)
	var palette: Array = range(kind_count)
	for i in range(palette.size() - 1, 0, -1):
		var other := random.randi_range(0, i)
		var value = palette[i]
		palette[i] = palette[other]
		palette[other] = value
	for i in range(witness.size()):
		tiles[witness[i]].kind = palette[(i / 3) % kind_count]
	return {"tiles": tiles, "witness": witness, "mask": all_mask(), "kinds": kind_count}

static func take(tiles: Array, mask: int, tray: Array, id: int) -> Dictionary:
	if tray.size() >= CAPACITY or not selectable(tiles, mask, id):
		return {"valid": false}
	var result_tray := tray.duplicate()
	var kind: int = tiles[id].kind
	var insertion := result_tray.size()
	for i in range(result_tray.size()):
		if tiles[result_tray[i]].kind == kind:
			insertion = i + 1
	result_tray.insert(insertion, id)
	var matching: Array[int] = []
	for item in result_tray:
		if tiles[item].kind == kind:
			matching.append(item)
	if matching.size() == 3:
		for item in matching:
			result_tray.erase(item)
	else:
		matching.clear()
	var remaining := mask & ~(1 << id)
	return {"valid": true, "mask": remaining, "tray": result_tray, "matched": matching,
		"insert_index": insertion, "lost": result_tray.size() >= CAPACITY,
		"won": remaining == 0 and result_tray.is_empty()}

static func valid_state(tiles: Array, mask: int, tray: Array) -> bool:
	if mask < 0 or (mask & ~all_mask()) != 0 or tray.size() > CAPACITY:
		return false
	var counts := PackedInt32Array()
	counts.resize(8)
	var tray_counts := PackedInt32Array()
	tray_counts.resize(8)
	var seen: Dictionary = {}
	for id in tray:
		if not (id is int or id is float) or not is_finite(float(id)) or float(id) < 0 or float(id) >= tiles.size() or float(id) != floorf(float(id)):
			return false
		id = int(id)
		if seen.has(id) or (mask & (1 << id)) != 0:
			return false
		seen[id] = true
		counts[tiles[id].kind] += 1
		tray_counts[tiles[id].kind] += 1
		if tray_counts[tiles[id].kind] > 2:
			return false
	for tile in tiles:
		if (mask & (1 << int(tile.id))) != 0:
			counts[tile.kind] += 1
	for count in counts:
		if count % 3 != 0:
			return false
	return true

class Search:
	var tiles: Array
	var budget := 20000
	var visited := 0
	var limit_hit := false
	var memo: Dictionary = {}
	var path: Array[int] = []

	func walk(mask: int, counts: PackedInt32Array, size: int) -> bool:
		if mask == 0:
			return size == 0
		if visited >= budget:
			limit_hit = true
			return false
		var signature := 0
		for i in range(8):
			signature = signature * 3 + counts[i]
		var key := mask | (signature << TILE_COUNT)
		if memo.has(key):
			return false
		visited += 1
		var choices := TrioRules.available(tiles, mask)
		# Complete a trio first, then use matching tray motifs, then open a new one.
		choices.sort_custom(func(a: int, b: int): return counts[tiles[a].kind] > counts[tiles[b].kind])
		for id in choices:
			var kind: int = tiles[id].kind
			var next_counts := counts.duplicate()
			next_counts[kind] = (next_counts[kind] + 1) % 3
			var next_size := size - 2 if counts[kind] == 2 else size + 1
			if next_size >= CAPACITY:
				continue
			path.append(id)
			if walk(mask & ~(1 << id), next_counts, next_size):
				return true
			path.pop_back()
			if limit_hit:
				return false
		memo[key] = true
		return false

static func solve(tiles: Array, mask: int, tray: Array, budget: int = 20000) -> Dictionary:
	var search := Search.new()
	search.tiles = tiles
	search.budget = budget
	var counts := PackedInt32Array()
	counts.resize(8)
	for id in tray:
		counts[tiles[id].kind] += 1
	var success := false
	if tray.size() < CAPACITY:
		success = search.walk(mask, counts, tray.size())
	return {"status": "SOLVED" if success else ("LIMIT" if search.limit_hit else "UNSOLVABLE"),
		"path": search.path if success else [], "visited": search.visited}
