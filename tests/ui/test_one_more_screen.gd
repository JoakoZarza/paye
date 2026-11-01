extends GutTest
const SCENE = preload("res://ui/screens/one_more_screen.tscn")
const META_PATH := "user://test_meta_one_more.json"
func after_each() -> void: DirAccess.remove_absolute(ProjectSettings.globalize_path(META_PATH))
func test_skip_opens_shop() -> void:
	var rc := RunController.new(Economy.load_from(), MetaState.new(), 4, META_PATH); rc.start_run(&"normal"); rc.enter_match()
	var m := rc.table().truco_match; m.start_hand(); m.award(1, 3); m.award(0, m.target); rc.finish_match()
	var screen = SCENE.instantiate(); add_child_autofree(screen); screen.setup(rc)
	screen.find_child("Skip", true, false).pressed.emit()
	assert_eq(rc.phase, RunController.Phase.SHOP)
