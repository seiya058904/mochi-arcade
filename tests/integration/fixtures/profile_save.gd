extends "res://scripts/app/save_manager.gd"
var flush_calls := 0
var write_calls := 0
var commits := 0

func flush() -> Error:
	flush_calls += 1
	var result := super.flush()
	if result == OK:
		commits += 1
	return result

func write_temp(path: String, contents: String) -> Error:
	write_calls += 1
	return super.write_temp(path, contents)
