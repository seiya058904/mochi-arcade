extends "res://scripts/games/fruit_drop.gd"
var snapshots: Array[String] = []

func checkpoint() -> void:
	super.checkpoint()
	if merge_count > 0:
		snapshots.append(FileAccess.get_file_as_string(Save.folder.path_join("save.json")))
