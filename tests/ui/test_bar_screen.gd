extends GutTest
const SCENE = preload("res://ui/screens/bar_screen.tscn")
const META_PATH := "user://test_meta_bar_screen.json"
func after_each() -> void: DirAccess.remove_absolute(ProjectSettings.globalize_path(META_PATH))
func test_sit_enters_match() -> void:
	var rc := RunController.new(Economy.load_from(), MetaState.new(), 4, META_PATH); rc.start_run(&"normal")
	var screen = SCENE.instantiate(); add_child_autofree(screen); screen.setup(rc)
	screen.find_child("Sit", true, false).pressed.emit()
	assert_eq(rc.phase, RunController.Phase.MATCH)
