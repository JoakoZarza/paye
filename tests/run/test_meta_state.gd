extends GutTest

const MetaStateScript = preload("res://core/run/meta_state.gd")
const SAVE_PATH := "user://test_meta_save.json"
const MISSING_PATH := "user://test_meta_missing.json"
const CORRUPT_PATH := "user://test_meta_corrupt.json"


func test_guardar_y_cargar() -> void:
	var state: MetaState = MetaStateScript.new()
	state.debt = 12345
	state.legacy = &"cinta_roja"
	state.runs_played = 7
	state.best_round = 9
	assert_true(state.save_to(SAVE_PATH))
	var loaded: MetaState = MetaStateScript.load_from(SAVE_PATH)
	assert_eq(loaded.debt, 12345)
	assert_eq(loaded.legacy, &"cinta_roja")
	assert_eq(loaded.runs_played, 7)
	assert_eq(loaded.best_round, 9)
	_remove_file(SAVE_PATH)


func test_archivo_ausente_arranca_limpio() -> void:
	_remove_file(MISSING_PATH)
	var state: MetaState = MetaStateScript.load_from(MISSING_PATH)
	assert_eq(state.debt, 0)
	assert_eq(state.legacy, &"")
	assert_eq(state.runs_played, 0)
	assert_eq(state.best_round, 0)
	_remove_file(MISSING_PATH)


func test_archivo_corrupto_arranca_limpio() -> void:
	var file := FileAccess.open(CORRUPT_PATH, FileAccess.WRITE)
	assert_not_null(file)
	file.store_string("{ esto no es JSON")
	file.close()
	var state: MetaState = MetaStateScript.load_from(CORRUPT_PATH)
	assert_eq(state.debt, 0)
	assert_eq(state.legacy, &"")
	assert_eq(state.runs_played, 0)
	assert_eq(state.best_round, 0)
	_remove_file(CORRUPT_PATH)


func _remove_file(path: String) -> void:
	var absolute_path: String = ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(absolute_path)


func test_deuda_negativa_se_corrige() -> void:
	var path := "user://test_meta_negativa.json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("{\"debt\": -5000}")
	f.close()
	assert_eq(MetaState.load_from(path).debt, 0)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
