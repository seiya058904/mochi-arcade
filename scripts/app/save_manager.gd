extends Node
signal persistence_changed(error: Error)
## Versioned local save. Write a complete temporary file, rotate a valid backup,
## then rename. A corrupt primary never destroys the last readable backup.
const VERSION := 1
const SCHEMA := preload("res://scripts/app/save_schema.gd")
var data: Dictionary = {}
var folder := "user://"
var recovered := false
var last_error := OK
var dirty := false
var read_error := OK
var load_error := OK
var decode_status := "MISSING"
var recovery_details: Array[String] = []

func _ready() -> void:
	load_save()

func defaults() -> Dictionary:
	return {"version": VERSION, "settings": {"music": true, "sfx": true,
		"reduced_motion": false, "haptics": true, "language": "en"},
		"records": {}, "sessions": {}, "seen": {}}

func decode(path: String) -> Dictionary:
	read_error = OK
	decode_status = "MISSING"
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		read_error = FileAccess.get_open_error()
		decode_status = "IO_ERROR"
		return {}
	decode_status = "INVALID_JSON"
	if file.get_length() > 2000000:
		return {}
	var contents := file.get_as_text()
	var error := file.get_error()
	if error != OK and error != ERR_FILE_EOF:
		read_error = error
		decode_status = "IO_ERROR"
		return {}
	var parser := JSON.new()
	if parser.parse(contents) != OK:
		return {}
	var parsed = parser.data
	if not parsed is Dictionary:
		return {}
	if not SCHEMA.number(parsed.get("version"), VERSION, VERSION, true):
		decode_status = "UNSUPPORTED_VERSION"
		read_error = ERR_FILE_UNRECOGNIZED
		return {}
	decode_status = "VALID"
	for key in ["settings", "records", "sessions", "seen"]:
		if not parsed.get(key) is Dictionary:
			decode_status = "INVALID_SECTION"
	return parsed

func load_save() -> void:
	recovery_details.clear()
	data = decode(folder.path_join("save.json"))
	var primary_status := decode_status
	load_error = read_error
	var backup := decode(folder.path_join("save.backup.json"))
	if load_error == OK:
		load_error = read_error
	recovered = false
	if data.is_empty():
		data = backup.duplicate(true)
		recovered = not data.is_empty()
		if recovered:
			recovery_details.append("primary:" + primary_status + ":backup")
	if data.is_empty():
		data = defaults()
	# The primary wins for valid fields. Recover only malformed fields from the
	# backup; never replace a valid newer score/round with an older one.
	for section in ["settings", "records", "sessions", "seen"]:
		var old_section: Dictionary = backup[section] if backup.get(section) is Dictionary else {}
		if not data.get(section) is Dictionary:
			data[section] = old_section.duplicate(true)
			recovered = true
			recovery_details.append(section + ":invalid_section:" + ("backup" if backup.get(section) is Dictionary else "default"))
		# Only malformed existing fields recover. Missing keys and empty valid
		# sections represent legitimate deletion/reset and must stay absent.
		for key in data[section].keys():
			if not valid_field(section, key, data[section][key]):
				recovered = true
				if valid_field(section, key, old_section.get(key)):
					data[section][key] = old_section[key]
					recovery_details.append(section + "." + key + ":backup")
				else:
					data[section].erase(key)
					recovery_details.append(section + "." + key + ":default")
	var settings: Dictionary = defaults().settings
	for key in ["music", "sfx", "reduced_motion", "haptics"]:
		if data.settings.get(key) is bool:
			settings[key] = data.settings[key]
	if data.settings.get("language") in ["en", "zh"]:
		settings.language = data.settings.language
	data.settings = settings
	for id in data.records.keys():
		if not SCHEMA.number(data.records[id], 0, 9007199254740991, true):
			data.records.erase(id)
	for id in data.seen.keys():
		if not data.seen[id] is bool:
			data.seen.erase(id)
	dirty = load_error != OK or recovered
	last_error = load_error

func valid_field(section: String, key: String, value: Variant) -> bool:
	match section:
		"settings":
			return value in ["en", "zh"] if key == "language" else value is bool
		"records":
			return SCHEMA.number(value, 0, 9007199254740991, true)
		"sessions":
			return SCHEMA.session(key, value)
		"seen":
			return value is bool
	return false

func valid_backup(value: Dictionary) -> bool:
	if value.is_empty():
		return false
	for section in ["settings", "records", "sessions", "seen"]:
		if not value.get(section) is Dictionary:
			return false
		for key in value[section]:
			if not valid_field(section, key, value[section][key]):
				return false
	return true

func complete_write(error: Error) -> Error:
	var was_failed := last_error != OK
	last_error = error
	dirty = error != OK
	# One notification per failure episode, not one toast per score/collision.
	if was_failed != dirty:
		persistence_changed.emit(error)
	return error

func write_temp(path: String, contents: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(contents)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return error
	# Detect short writes before either valid save is touched.
	return OK if FileAccess.get_file_as_string(path) == contents else ERR_FILE_CORRUPT

func flush() -> Error:
	# An unreadable file is not an empty/corrupt save. Its newer data is unknown;
	# do not replace it with defaults or an older backup. Reopen on next launch
	# after access is repaired, rather than guessing a merge of pending progress.
	if load_error != OK:
		return complete_write(load_error)
	var temp := folder.path_join("save.tmp")
	var primary := folder.path_join("save.json")
	var backup := folder.path_join("save.backup.json")
	var backup_temp := folder.path_join("save.backup.tmp")
	var error := write_temp(temp, JSON.stringify(data))
	if error != OK:
		return complete_write(error)
	var previous := decode(primary)
	if read_error != OK:
		return complete_write(read_error)
	if valid_backup(previous):
		# Reuse the validated read. A second read can fail or observe different
		# bytes after validation, and must never replace the backup with empty data.
		error = write_temp(backup_temp, JSON.stringify(previous))
		if error == OK:
			error = DirAccess.rename_absolute(backup_temp, backup)
		if error != OK:
			return complete_write(error)
	return complete_write(DirAccess.rename_absolute(temp, primary))

func best(id: String) -> int:
	var value = data.records.get(id, 0)
	return int(value) if SCHEMA.number(value, 0, 9007199254740991, true) else 0

func record(id: String, score: int) -> Error:
	if score > best(id):
		stage_record(id, score)
		return flush()
	return last_error

func stage_record(id: String, score: int) -> void:
	# Internal logical-action staging, not a successful persistence operation.
	# Callers commit the matching session/terminal deletion synchronously.
	if score > best(id):
		data.records[id] = score
		dirty = true

func setting(key: String) -> Variant:
	return data.settings.get(key, defaults().settings.get(key))

func set_setting(key: String, value: Variant) -> Error:
	data.settings[key] = value
	return flush()

func session(id: String) -> Dictionary:
	var value = data.sessions.get(id, {})
	return value.duplicate(true) if SCHEMA.session(id, value) else {}

func save_session(id: String, value: Dictionary) -> Error:
	data.sessions[id] = value.duplicate(true)
	return flush()

func clear_session(id: String) -> Error:
	data.sessions.erase(id)
	return flush()

func reset_records() -> Error:
	data.records.clear()
	data.sessions.clear()
	return flush()
