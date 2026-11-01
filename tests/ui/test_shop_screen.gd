extends GutTest
const SCENE = preload("res://ui/screens/shop_screen.tscn")
const META_PATH := "user://test_meta_shop_screen.json"
func after_each() -> void: DirAccess.remove_absolute(ProjectSettings.globalize_path(META_PATH))
func test_next_returns_to_bar_and_advances_round() -> void:
	var rc := RunController.new(Economy.load_from(), MetaState.new(), 4, META_PATH); rc.start_run(&"normal"); rc.enter_match()
	var m := rc.table().truco_match; m.start_hand(); m.award(1, 3); m.award(0, m.target); rc.finish_match(); rc.skip_one_more()
	var screen = SCENE.instantiate(); add_child_autofree(screen); screen.setup(rc)
	screen.find_child("Next", true, false).pressed.emit()
	assert_eq(rc.phase, RunController.Phase.BAR); assert_eq(rc.state.round, 2)
