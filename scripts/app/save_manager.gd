extends Node
## Versioned local save. Write a complete temporary file, rotate a valid backup,
## then rename. A corrupt primary never destroys the last readable backup.
const VERSION := 1
var data: Dictionary = {}
var folder := "user://"
var recovered := false
var last_error := OK

func _ready() -> void:
	load_save()

func defaults() -> Dictionary:
	return {"version": VERSION, "settings": {"music": true, "sfx": true,
		"reduced_motion": false, "haptics": true, "language": "en"},
		"records": {}, "sessions": {}, "seen": {}}

func decode(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {}
	var parsed = parser.data
	if not parsed is Dictionary or int(parsed.get("version", 0)) != VERSION:
		return {}
	for key in ["settings", "records", "sessions", "seen"]:
		if not parsed.get(key) is Dictionary:
			return {}
	return parsed

func load_save() -> void:
	data = decode(folder.path_join("save.json"))
	recovered = false
	if data.is_empty():
		data = decode(folder.path_join("save.backup.json"))
		recovered = not data.is_empty()
	if data.is_empty():
		data = defaults()
	var settings: Dictionary = defaults().settings
	settings.merge(data.settings, true)
	data.settings = settings

func flush() -> Error:
	var temp := folder.path_join("save.tmp")
	var primary := folder.path_join("save.json")
	var backup := folder.path_join("save.backup.json")
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		last_error = FileAccess.get_open_error()
		return last_error
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	if not decode(primary).is_empty():
		last_error = DirAccess.copy_absolute(primary, backup)
		if last_error != OK:
			return last_error
	last_error = DirAccess.rename_absolute(temp, primary)
	return last_error

func best(id: String) -> int:
	return int(data.records.get(id, 0))

func record(id: String, score: int) -> void:
	if score > best(id):
		data.records[id] = score
		flush()

func setting(key: String) -> Variant:
	return data.settings.get(key, defaults().settings.get(key))

func set_setting(key: String, value: Variant) -> void:
	data.settings[key] = value
	flush()

func session(id: String) -> Dictionary:
	var value = data.sessions.get(id, {})
	return value.duplicate(true) if value is Dictionary else {}

func save_session(id: String, value: Dictionary) -> void:
	data.sessions[id] = value.duplicate(true)
	flush()

func clear_session(id: String) -> void:
	data.sessions.erase(id)
	flush()

func reset_records() -> void:
	data.records.clear()
	data.sessions.clear()
	flush()
