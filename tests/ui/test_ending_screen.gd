extends GutTest
const SCENE = preload("res://ui/screens/ending_screen.tscn")
const META_PATH := "user://test_meta_ending_screen.json"
func after_each() -> void: DirAccess.remove_absolute(ProjectSettings.globalize_path(META_PATH))
func test_picker_starts_new_run() -> void:
	var economy := Economy.load_from()
	var rc := RunController.new(economy, MetaState.new(), 4, META_PATH); rc.start_run(&"normal")
	rc.state.round = economy.rounds_total(); rc.state.money = 11000000; rc.enter_match()
	var m := rc.table().truco_match; m.start_hand(); m.award(1, 3); m.award(0, m.target); rc.finish_match(); rc.retire()
	var screen = SCENE.instantiate(); add_child_autofree(screen); screen.setup(rc)
	screen.find_child("Deck_normal", true, false).pressed.emit()
	assert_eq(rc.phase, RunController.Phase.BAR)
