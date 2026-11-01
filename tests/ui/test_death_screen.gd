extends GutTest
const SCENE = preload("res://ui/screens/death_screen.tscn")
const META_PATH := "user://test_meta_death_screen.json"
func after_each() -> void: DirAccess.remove_absolute(ProjectSettings.globalize_path(META_PATH))
func test_legacy_selection_stays_dead_and_saves_choice() -> void:
	var rc := RunController.new(Economy.load_from(), MetaState.new(), 4, META_PATH); rc.start_run(&"normal"); rc.state.loadout.equip(AmuletDef.load_all()[&"marker"]); rc.state.money = 0; rc.enter_match()
	var screen = SCENE.instantiate(); add_child_autofree(screen); screen.setup(rc)
	screen.find_child("Legacy_marker", true, false).pressed.emit()
	assert_eq(rc.meta.legacy, &"marker"); assert_eq(rc.phase, RunController.Phase.DEAD)
