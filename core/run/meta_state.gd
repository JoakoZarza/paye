class_name MetaState extends RefCounted
## Guarda deuda y legado entre runs.

const DEFAULT_PATH := "user://meta.json"

var debt: int = 0
var legacy: StringName = &""
var runs_played: int = 0
var best_round: int = 0


static func load_from(path: String = DEFAULT_PATH) -> MetaState:
	var state := MetaState.new()
	if not FileAccess.file_exists(path):
		return state
	# JSON.new().parse no ensucia el log con un error de motor si el archivo está corrupto.
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		return state
	var data: Dictionary = json.data
	state.debt = int(data.get("debt", 0))
	state.legacy = StringName(String(data.get("legacy", "")))
	state.runs_played = int(data.get("runs_played", 0))
	state.best_round = int(data.get("best_round", 0))
	return state


func save_to(path: String = DEFAULT_PATH) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	var data: Dictionary = {
		"debt": debt,
		"legacy": String(legacy),
		"runs_played": runs_played,
		"best_round": best_round,
	}
	file.store_string(JSON.stringify(data))
	return file.get_error() == OK
