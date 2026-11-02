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


func test_camara_por_fase() -> void:
	var bar: Bar3D = BAR.instantiate()
	add_child_autofree(bar)
	var cam := CameraRig.new()
	cam.mouse_look = false
	bar.add_child(cam)
	cam.setup(bar)
	cam.go_to_phase(RunController.Phase.MATCH, true)
	assert_eq(cam.target_marker, &"CamSeat")
	assert_almost_eq(cam.global_position.distance_to(bar.marker("CamSeat").global_position), 0.0, 0.001)
	cam.go_to_phase(RunController.Phase.SHOP, true)
	assert_eq(cam.target_marker, &"CamShop")
	assert_eq(CameraRig.marker_for(RunController.Phase.BAR), &"CamBar")
