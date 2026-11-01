class_name MetaState extends RefCounted
## Guarda deuda y legado entre runs.

const DEFAULT_PATH := "user://meta.json"

var debt: int = 0
var legacy: StringName = &""
var runs_played: int = 0
var best_round: int = 0
## Hay una run sin terminar: si el juego se cerró a mitad de run, cuenta como abandonada.
var run_in_progress := false


static func load_from(path: String = DEFAULT_PATH) -> MetaState:
	var state := MetaState.new()
	if not FileAccess.file_exists(path):
		return state
	# JSON.new().parse no ensucia el log con un error de motor si el archivo está corrupto.
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		return state
	var data: Dictionary = json.data
	state.debt = maxi(0, int(data.get("debt", 0)))
	state.run_in_progress = bool(data.get("run_in_progress", false))
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
		"run_in_progress": run_in_progress,
	}
	file.store_string(JSON.stringify(data))
	return file.get_error() == OK
