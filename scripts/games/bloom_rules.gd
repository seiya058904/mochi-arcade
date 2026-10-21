class_name BloomRules
extends RefCounted

static func slide_line(line: Array) -> Dictionary:
	var compact: Array = []
	for value in line:
		if int(value) != 0:
			compact.append(int(value))
	var result: Array = []
	var score := 0
	var i := 0
	while i < compact.size():
		if i + 1 < compact.size() and compact[i] == compact[i + 1]:
			result.append(compact[i] * 2)
			score += compact[i] * 2
			i += 2
		else:
			result.append(compact[i])
			i += 1
	while result.size() < 4:
		result.append(0)
	return {"line": result, "score": score}

static func index_for(direction: int, lane: int, offset: int) -> int:
	match direction:
		0: return lane * 4 + offset # left
		1: return lane * 4 + 3 - offset # right
		2: return offset * 4 + lane # up
		_: return (3 - offset) * 4 + lane # down

static func move(board: Array, direction: int) -> Dictionary:
	assert(board.size() == 16)
	var next := board.duplicate()
	var score := 0
	var traces: Array = []
	for lane in range(4):
		var values: Array = []
		var originals: Array = []
		for offset in range(4):
			var index := index_for(direction, lane, offset)
			values.append(int(board[index]))
			if int(board[index]) > 0:
				originals.append(index)
		var result := slide_line(values)
		score += result.score
		for offset in range(4):
			next[index_for(direction, lane, offset)] = result.line[offset]
		var read := 0
		var write := 0
		while read < originals.size():
			var source: int = originals[read]
			var target := index_for(direction, lane, write)
			traces.append({"from": source, "to": target, "value": int(board[source])})
			if read + 1 < originals.size() and board[source] == board[originals[read + 1]]:
				traces.append({"from": originals[read + 1], "to": target, "value": int(board[source])})
				read += 1
			read += 1
			write += 1
	return {"board": next, "score": score, "changed": next != board, "traces": traces}

static func can_move(board: Array) -> bool:
	if 0 in board:
		return true
	for direction in range(4):
		if move(board, direction).changed:
			return true
	return false

static func spawn(board: Array, rng: RandomNumberGenerator) -> int:
	var empty: Array = []
	for i in range(16):
		if int(board[i]) == 0:
			empty.append(i)
	if empty.is_empty():
		return -1
	var index: int = empty[rng.randi_range(0, empty.size() - 1)]
	board[index] = 2 if rng.randf() < 0.9 else 4
	return index
