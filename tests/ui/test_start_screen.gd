extends GutTest
const SCENE = preload("res://ui/screens/start_screen.tscn")
const META_PATH := "user://test_meta_start_screen.json"
func after_each() -> void: DirAccess.remove_absolute(ProjectSettings.globalize_path(META_PATH))
func test_deck_starts_run() -> void:
	var rc := RunController.new(Economy.load_from(), MetaState.new(), 4, META_PATH)
	var screen = SCENE.instantiate(); add_child_autofree(screen); screen.setup(rc)
	screen.find_child("Deck_normal", true, false).pressed.emit()
	assert_eq(rc.phase, RunController.Phase.BAR)
