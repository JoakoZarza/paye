extends GutTest
## La mesa 3D se juega con clics en las cartas y los botones de abajo (Plan 7, Tareas 4 y 5).

const META_PATH := "user://test_meta_table_3d.json"
const SCENE := preload("res://ui/screens/table_screen.tscn")
const BAR := preload("res://world/bar_3d.tscn")
const MAX_STEPS := 3000


func after_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(META_PATH))


func _setup(seed := 4) -> Array:
	var rc := RunController.new(Economy.load_from(), MetaState.new(), seed, META_PATH)
	rc.start_run(&"normal")
	rc.enter_match()
	var bar: Bar3D = BAR.instantiate()
	add_child_autofree(bar)
	var screen: BaseScreen = SCENE.instantiate()
	screen.world = bar
	add_child_autofree(screen)
	screen.setup(rc)
	var table: Table3D = null
	for c in screen.get_children():
		if c is Table3D:
			table = c
	return [rc, screen, table, bar]


func _dealer_faces_hidden(table: Table3D) -> bool:
	var h := table.presenter.hand()
	for card: Card in h.cards[TablePresenter.DEALER]:
		var node: Card3D = table._cards.get(card)
		if node == null:
			continue
		var face := node.get_node("Face") as MeshInstance3D
		var label := node.get_node("FaceLabel") as Label3D
		if face.visible or face.material_override != null or label.text != "":
			return false
	return true


func test_la_mesa_pone_las_cartas_en_el_bar() -> void:
	var s := _setup()
	var table: Table3D = s[2]
	assert_not_null(table)
	assert_eq(table.card_nodes().size(), 6, "tres tuyas y tres del rival")
	assert_true(_dealer_faces_hidden(table))
	var screen: BaseScreen = s[1]
	assert_null(screen.find_child("Card0", true, false), "en 3D no hay botones de cartas")


func test_se_juega_una_mano_con_clics_en_las_cartas() -> void:
	var s := _setup()
	var rc: RunController = s[0]
	var screen: BaseScreen = s[1]
	var table: Table3D = s[2]
	var start_scores := rc.table().truco_match.scores.duplicate()
	var hands_before := 0
	for i in MAX_STEPS:
		var p := table.presenter
		if p.hand_finished():
			break
		assert_true(_dealer_faces_hidden(table), "una carta del rival en la mano mostró su cara")
		if p.dealer_should_play():
			screen._on_dealer_timer()
			continue
		if p.in_show_decision():
			screen.find_child("Continue", true, false).pressed.emit()
			continue
		var played := false
		for idx in p.hand().cards[0].size():
			if p.card_action(idx) != null:
				table.player_card(idx).press()
				played = true
				break
		if played:
			continue
		var buttons := screen.find_children("Act_*", "Button", true, false)
		if not buttons.is_empty():
			(buttons[0] as Button).pressed.emit()
			continue
		var declare := screen.find_child("Declare", true, false) as Button
		assert_not_null(declare, "no había nada para hacer")
		declare.pressed.emit()
	assert_true(table.presenter.hand_finished())
	assert_ne(rc.table().truco_match.scores, start_scores, "alguien sumó")


func _rig() -> Array:
	var bar: Bar3D = BAR.instantiate()
	add_child_autofree(bar)
	var cam := CameraRig.new()
	cam.edge_look = false
	bar.add_child(cam)
	cam.setup(bar)
	bar.camera = cam
	return [bar, cam]


func test_vistas_sentado() -> void:
	var r := _rig()
	var cam: CameraRig = r[1]
	cam.go_to(&"CamSeat", true)
	assert_eq(cam.view, CameraRig.View.HAND)
	cam.navigate(&"up")
	assert_eq(cam.view, CameraRig.View.RIVAL)
	cam.navigate(&"left")
	assert_eq(cam.view, CameraRig.View.LEFT)
	cam.navigate(&"left")
	assert_eq(cam.view, CameraRig.View.BACK)
	cam.navigate(&"down")
	assert_eq(cam.view, CameraRig.View.HAND)


func test_camina_rodeando_la_mesa() -> void:
	var r := _rig()
	var bar: Bar3D = r[0]
	var cam: CameraRig = r[1]
	cam.go_to(&"CamSeat", true)
	cam.go_to(&"CamShop")
	assert_false(cam.seated())
	assert_eq(cam.target_marker, &"CamShop")
	var route: Array = CameraRig.ROUTES[[&"CamSeat", &"CamShop"]]
	assert_has(route, &"PathSide", "pasa por el costado de la mesa")
	for stop: StringName in route:
		assert_not_null(bar.marker(String(stop)))
	cam.navigate(&"up")
	assert_eq(cam.view, CameraRig.View.HAND, "caminando no se cambia de vista")


func test_la_mano_baja_si_no_miras_tus_cartas() -> void:
	var s := _setup()
	var bar: Bar3D = s[3]
	var table: Table3D = s[2]
	var cam := CameraRig.new()
	cam.edge_look = false
	bar.add_child(cam)
	cam.setup(bar)
	bar.camera = cam
	cam.go_to(&"CamSeat", true)
	assert_true(table.hand_should_be_raised())
	cam.set_view(CameraRig.View.RIVAL, true)
	assert_false(table.hand_should_be_raised())
	table._process(0.0)
	assert_false(table.hand_raised())


func test_el_complice_se_ve_atras() -> void:
	var s := _setup()
	var rc: RunController = s[0]
	var table: Table3D = s[2]
	var bar: Bar3D = s[3]
	assert_false(bar.slot("accomplice").visible)
	rc.table().active_cheat = Cheat.make(Cheat.Kind.ACCOMPLICE)
	table.sync()
	assert_true(bar.slot("accomplice").visible)

func test_al_ganar_elegis_quedarte_en_la_mesa() -> void:
	var rc := RunController.new(Economy.load_from(), MetaState.new(), 4, META_PATH)
	rc.start_run(&"normal")
	rc.enter_match()
	var m := rc.table().truco_match
	m.start_hand()
	m.award(1, 3)
	m.award(0, m.target)
	rc.finish_match()
	rc.skip_one_more()
	var r := _rig()
	var router := ScreenRouter.new()
	router.world = r[0]
	add_child_autofree(router)
	router.setup(rc)
	assert_eq(rc.phase, RunController.Phase.SHOP)
	assert_eq(router.camera_marker(), &"CamSeat", "todavía sentado: elegís antes de levantarte")
	assert_not_null(router.find_child("GoShop", true, false))
	router.find_child("Stay", true, false).pressed.emit()
	assert_eq(rc.phase, RunController.Phase.BAR)
	assert_eq(rc.state.round, 2)
	assert_eq(router.camera_marker(), &"CamSeat", "el rival nuevo te encuentra sentado")


func test_al_ganar_ir_a_la_barra_abre_la_tienda() -> void:
	var rc := RunController.new(Economy.load_from(), MetaState.new(), 4, META_PATH)
	rc.start_run(&"normal")
	rc.enter_match()
	var m := rc.table().truco_match
	m.start_hand()
	m.award(1, 3)
	m.award(0, m.target)
	rc.finish_match()
	rc.skip_one_more()
	var r := _rig()
	var router := ScreenRouter.new()
	router.world = r[0]
	add_child_autofree(router)
	router.setup(rc)
	router.find_child("GoShop", true, false).pressed.emit()
	assert_eq(router.camera_marker(), &"CamShop")
	assert_not_null(router.find_child("Next", true, false))