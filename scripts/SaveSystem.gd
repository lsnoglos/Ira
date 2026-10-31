extends RefCounted
class_name IraSaveSystem

const SAVE_FILE := "user://ira_stage_save_v1.json"
const SAVE_SCHEMA := 1

static func defaults() -> Dictionary:
	return {"version": SAVE_SCHEMA, "stage": 1, "checkpoint": 0, "score": 0, "kills": 0, "hp": 100, "weapon_level": 1, "cleared": false, "save_time": ""}

static func exists() -> bool:
	return FileAccess.file_exists(SAVE_FILE)

static func read_save() -> Dictionary:
	var result := defaults()
	if not exists():
		return result
	var f := FileAccess.open(SAVE_FILE, FileAccess.READ)
	if f == null:
		return result
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or int(parsed.get("version", -1)) != SAVE_SCHEMA:
		return result
	for key in result.keys():
		if parsed.has(key):
			result[key] = parsed[key]
	result["checkpoint"] = clampi(int(result["checkpoint"]), 0, 3)
	result["hp"] = clampi(int(result["hp"]), 1, 100)
	result["stage"] = clampi(int(result["stage"]), 1, 2)
	result["score"] = maxi(0, int(result["score"]))
	result["kills"] = maxi(0, int(result["kills"]))
	result["weapon_level"] = clampi(int(result["weapon_level"]), 1, 3)
	return result

static func write_save(data: Dictionary) -> bool:
	var safe := defaults()
	for key in safe.keys():
		if data.has(key):
			safe[key] = data[key]
	safe["save_time"] = Time.get_datetime_string_from_system()
	var f := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if f == null:
		push_warning("IRA: no se pudo escribir el guardado local")
		return false
	f.store_string(JSON.stringify(safe, "\t"))
	f.flush()
	return true

static func remove_save() -> void:
	if exists():
		DirAccess.remove_absolute(SAVE_FILE)
