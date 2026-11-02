extends GutTest

const META_PATH := "user://test_meta_ui.json"

var _economy: Economy


func before_all() -> void:
	_economy = Economy.load_from()


func after_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(META_PATH))


func _controller() -> RunController:
	return RunController.new(_economy, MetaState.new(), 4, META_PATH)


func test_screen_for_phase_routes_run() -> void:
	var rc := _controller()
	var router := ScreenRouter.new()
	router.setup(rc)
	assert_eq(router.screen_for_phase(), &"start")
	rc.start_run(&"normal")
	assert_eq(router.screen_for_phase(), &"bar")
	rc.enter_match()
	assert_eq(router.screen_for_phase(), &"table")
	var m := rc.table().truco_match
	m.start_hand()
	m.award(1, 3)
	m.award(0, m.target)
	rc.finish_match()
	# La mano artificial del test no se jugó y no debe confundirse con una apuesta.
	assert_eq(router.screen_for_phase(), &"one_more")
	rc.one_more(0.5)
	assert_eq(router.screen_for_phase(), &"table", "con la apuesta hecha se juega en la mesa")
	var h := rc.table().truco_match.hand
	h.apply(TrucoAction.make(TrucoAction.Type.MAZO, h.current_player()))
	rc.finish_one_more()
	assert_eq(router.screen_for_phase(), &"shop")
	router.free()


func test_setup_instantiates_a_screen_child() -> void:
	var router := ScreenRouter.new()
	add_child_autofree(router)
	router.setup(_controller())
	assert_eq(router.get_child_count(), 1)
	assert_true(router.get_child(0) is BaseScreen)
