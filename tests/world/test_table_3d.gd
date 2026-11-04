extends GutTest
## La mesa 3D se juega con clics en las cartas y los botones de abajo (Plan 7, Tareas 4 y 5).

const META_PATH := "user://test_meta_table_3d.json"
const SCENE := preload("res://ui/screens/table_screen.tscn")
const BAR := preload("res://world/bar_3d.tscn")
const MAX_STEPS := 3000


func before_all() -> void:
	Table3D.animate_deals = false


func after_all() -> void:
	Table3D.animate_deals = true


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
		if node == null or card in table.showing():
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
	cam.mouse_look = false
	bar.add_child(cam)
	cam.setup(bar)
	bar.camera = cam
	return [bar, cam]


func _hold(cam: CameraRig, m: Vector2, seconds: float) -> void:
	for i in int(seconds * 60):
		cam.look(m, 1.0 / 60.0)


func test_zonas_de_la_pantalla() -> void:
	assert_eq(CameraRig.zone_at(Vector2(0.5, 0.9)), CameraRig.Zone.CARDS)
	assert_eq(CameraRig.zone_at(Vector2(0.5, 0.3)), CameraRig.Zone.TABLE)
	assert_eq(CameraRig.zone_at(Vector2(0.05, 0.2)), CameraRig.Zone.AROUND)


func test_sobre_tus_cartas_casi_no_se_mueve() -> void:
	var cam: CameraRig = _rig()[1]
	cam.go_to(&"CamSeat", true)
	_hold(cam, Vector2(0.68, 0.95), 3.0)
	var t := cam.turn_degrees()
	assert_lt(absf(t.y), 3.5)
	assert_lt(t.x, -10.0, "sigue mirando las cartas")
	assert_true(cam.looking_at_hand())


func test_en_el_medio_mira_al_rival() -> void:
	var cam: CameraRig = _rig()[1]
	cam.go_to(&"CamSeat", true)
	_hold(cam, Vector2(0.5, 0.2), 3.0)
	assert_gt(cam.turn_degrees().x, 0.0)
	assert_false(cam.looking_at_hand())


func test_el_borde_gira_sin_dar_la_vuelta() -> void:
	var cam: CameraRig = _rig()[1]
	cam.go_to(&"CamSeat", true)
	_hold(cam, Vector2(1.0, 0.45), 8.0)
	var yaw := cam.turn_degrees().y
	assert_lt(yaw, -110.0, "llega a mirar atrás")
	assert_gte(yaw, -CameraRig.MAX_YAW - 0.5, "no gira más que una persona")
	_hold(cam, Vector2(0.5, 0.9), 6.0)
	assert_gt(cam.turn_degrees().y, -5.0, "soltando el borde vuelve")


func test_afuera_se_agita_y_tarda_en_calmarse() -> void:
	var cam: CameraRig = _rig()[1]
	cam.go_to(&"CamSeat", true)
	assert_false(cam.agitated())
	for i in 30:
		cam.look(Vector2(0.1 if i % 10 < 5 else 0.9, 0.15), 1.0 / 60.0)
	assert_true(cam.agitated())
	_hold(cam, Vector2(0.5, 0.9), 0.8)
	assert_true(cam.agitated(), "pasar por adentro no alcanza")
	_hold(cam, Vector2(0.5, 0.9), 1.5)
	assert_false(cam.agitated())


func test_camina_rodeando_la_mesa() -> void:
	var r := _rig()
	var bar: Bar3D = r[0]
	var cam: CameraRig = r[1]
	cam.go_to(&"CamSeat", true)
	cam.go_to(&"CamShop")
	assert_false(cam.seated())
	assert_eq(cam.target_marker, &"CamShop")
	var route: Array = CameraRig.ROUTES[[&"CamSeat", &"CamShop"]]
	assert_has(route, &"PathLeft", "pasa por el costado de la mesa, hacia la barra")
	for stop: StringName in route:
		assert_not_null(bar.marker(String(stop)))
	var before := cam.turn_degrees()
	cam.look(Vector2(0.5, 0.2), 0.5)
	assert_eq(cam.turn_degrees(), before, "caminando el mouse no mueve la cabeza")


func test_la_mano_baja_si_no_miras_tus_cartas() -> void:
	var s := _setup()
	var bar: Bar3D = s[3]
	var table: Table3D = s[2]
	var cam := CameraRig.new()
	cam.mouse_look = false
	bar.add_child(cam)
	cam.setup(bar)
	bar.camera = cam
	cam.go_to(&"CamSeat", true)
	assert_true(table.hand_should_be_raised())
	var raised_y := table.player_card(0).rest_y
	_hold(cam, Vector2(0.5, 0.2), 3.0)
	assert_false(table.hand_should_be_raised())
	table._process(0.0)
	assert_false(table.hand_raised())
	assert_almost_eq(table.player_card(0).rest_y, raised_y + Table3D.HAND_LOWERED.y, 0.001,
		"solo baja la altura, sin apoyarla en la mesa")


func test_las_cartas_van_en_abanico() -> void:
	var c := Vector3.ZERO
	var left: Array = Table3D.fan(c, 0, 3, Table3D.HAND_TILT, 0.0)
	var mid: Array = Table3D.fan(c, 1, 3, Table3D.HAND_TILT, 0.0)
	var right: Array = Table3D.fan(c, 2, 3, Table3D.HAND_TILT, 0.0)
	assert_lt(left[0].x, mid[0].x)
	assert_lt(mid[0].x, right[0].x)
	assert_gt(left[1].z, 0.0, "la de la izquierda se abre a la izquierda")
	assert_lt(right[1].z, 0.0)
	assert_lt(left[0].y, mid[0].y, "las de los costados quedan más bajas, como en la mano")


func test_el_rival_habla_con_subtitulos_que_tiemblan() -> void:
	var s := _setup()
	var table: Table3D = s[2]
	var bar: Bar3D = s[3]
	var speech := bar.marker("SpeechAnchor").get_node("RivalSpeech") as Subtitle3D
	assert_not_null(speech)
	table.presenter.rival_line = "¡Truco!"
	table.presenter.rival_line_id += 1
	table.sync()
	assert_eq(speech.text, "¡Truco!")
	assert_eq(speech.glyph_count(), 7)
	speech.step(0.05)
	assert_lt(speech.visible_glyphs(), 7, "se va escribiendo")
	speech.step(1.0)
	assert_eq(speech.visible_glyphs(), 7)
	var before := speech._glyphs[0].position
	var moved := false
	for i in 10:
		speech.step(Subtitle3D.JITTER_STEP)
		moved = moved or speech._glyphs[0].position != before
	assert_true(moved, "las letras tiemblan")
	speech.step(Subtitle3D.HOLD_SECONDS + Subtitle3D.FADE_SECONDS)
	assert_eq(speech.visible_glyphs(), 0, "se apaga solo")


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
	var shop: Node = null
	for c in router.get_children():
		if c is BaseScreen:
			shop = c
	var items: Array = shop.shop_items()
	assert_eq(items.size(), rc.shop.offers.size(), "las ofertas están en el mantel")
	assert_null(router.find_child("Buy0", true, false), "se compra desde la vista de cerca")
	items[0].hovered.emit(items[0], true)
	assert_eq(shop.hover_text(), shop._name_of(items[0].def.id), "al pasar el mouse dice qué es")
	items[0].hovered.emit(items[0], false)
	assert_eq(shop.hover_text(), "")
	shop.inspect(items[0])
	assert_eq(shop.inspected(), items[0])
	assert_true(items[0].inspecting(), "levita")
	assert_true(items[0].facing().is_equal_approx((r[1] as CameraRig).global_basis.orthonormalized()), "de frente a la vista")
	assert_not_null(router.find_child("Buy0", true, false))
	assert_lt((r[0] as Bar3D).get_node("LampLight").light_energy, 1.0, "el bar se oscurece")
	shop.close_inspect()
	assert_null(shop.inspected())
	assert_false(items[0].inspecting(), "vuelve al mantel")
	assert_null(router.find_child("*ScrollContainer*", true, false), "sin el panel de la tienda 2D")

func test_los_puntos_se_tallan_en_palitos_de_a_cinco() -> void:
	var tally := ScoreTally.new()
	add_child_autofree(tally)
	tally.set_points(7)
	assert_eq(tally.points(), 7)
	var diagonal: Array = ScoreTally.stick_shape(4)
	assert_almost_eq(float(diagonal[2]), PI * 0.25, 0.001, "el quinto cruza en diagonal")
	var next_group: Array = ScoreTally.stick_shape(5)
	assert_gt(next_group[0].z, ScoreTally.SIDE, "el sexto empieza otro cuadrado, debajo")
	tally.set_points(2)
	assert_eq(tally.points(), 2, "partido nuevo: se empieza de cero")


func test_la_mesa_talla_los_puntos_de_cada_uno() -> void:
	var s := _setup()
	var rc: RunController = s[0]
	var table: Table3D = s[2]
	var bar: Bar3D = s[3]
	rc.table().truco_match.scores[0] = 3
	rc.table().truco_match.scores[1] = 6
	table.sync()
	var sheet := bar.marker("ScoreSheet").get_node("Sheet") as ScoreSheet
	assert_eq(sheet.tally(0).points(), 3, "NOS")
	assert_eq(sheet.tally(1).points(), 6, "ELLOS")
	assert_eq((sheet.get_node("HeaderNOS") as Label3D).text, "NOS")


func test_el_canto_del_rival_espera_tu_respuesta() -> void:
	var s := _setup()
	var table: Table3D = s[2]
	var bar: Bar3D = s[3]
	var p := table.presenter
	var speech := bar.marker("SpeechAnchor").get_node("RivalCall") as Subtitle3D
	p._apply([GameEvent.make(&"call_made", {"player": TablePresenter.DEALER, "call": TrucoAction.Type.TRUCO})] as Array[GameEvent])
	assert_true(p.rival_waiting)
	table.sync()
	speech.step(Subtitle3D.HOLD_SECONDS * 3)
	assert_gt(speech.visible_glyphs(), 0, "sigue escrito mientras no respondas")
	p._apply([GameEvent.make(&"call_accepted", {"player": TablePresenter.PLAYER})] as Array[GameEvent])
	assert_false(p.rival_waiting)
	table.sync()
	speech.step(Subtitle3D.FADE_SECONDS + 0.01)
	assert_eq(speech.visible_glyphs(), 0, "respondiste: se apaga")


func test_el_balbuceo_suena_cada_pocas_letras() -> void:
	var b := Babble.new()
	add_child_autofree(b)
	b.set_voice("La Ira")
	assert_not_null(b.stream)
	var other := Babble.new()
	add_child_autofree(other)
	other.set_voice("La Gula")
	assert_ne(b.base_pitch, other.base_pitch, "cada rival tiene su tono")


func test_sobre_un_boton_la_cabeza_no_se_mueve() -> void:
	var cam: CameraRig = _rig()[1]
	cam.go_to(&"CamSeat", true)
	cam.ui_hold = true
	var before := cam.turn_degrees()
	_hold(cam, Vector2(0.1, 0.2), 1.0)
	assert_eq(cam.turn_degrees(), before)


func test_el_giro_acelera_un_poco() -> void:
	var cam: CameraRig = _rig()[1]
	cam.go_to(&"CamSeat", true)
	cam.look(Vector2(0.5, 0.45), 1.0 / 60.0, 1)
	var first := absf(cam._twist)
	_hold_turn(cam, 2.0)
	var t0 := cam._twist
	cam.look(Vector2(0.5, 0.45), 1.0 / 60.0, 1)
	var late := absf(cam._twist - t0)
	assert_gt(late, first * 1.3, "acelera")
	assert_lt(late, first * 2.0, "pero no al doble")


func _hold_turn(cam: CameraRig, seconds: float) -> void:
	for i in int(seconds * 60):
		cam.look(Vector2(0.5, 0.45), 1.0 / 60.0, 1)
		cam._twist = 0.0


func test_inclinarse_sobre_la_mesa() -> void:
	var cam: CameraRig = _rig()[1]
	cam.go_to(&"CamSeat", true)
	var seat := cam.global_position
	for i in 60:
		cam.look(Vector2(0.5, 0.9), 1.0 / 60.0, 0, true)
	cam._apply()
	assert_true(cam.leaning())
	assert_lt(cam.global_position.z, seat.z - 0.15, "se adelanta")
	assert_false(cam.looking_at_hand(), "inclinado, la mano se baja")


func test_los_amuletos_estan_sobre_la_mesa() -> void:
	var s := _setup()
	var rc: RunController = s[0]
	var screen: BaseScreen = s[1]
	var table: Table3D = s[2]
	rc.systems.loadout.equip(AmuletDef.load_all()[&"mirror"])
	table.sync()
	assert_eq(table.amulet_tokens().size(), 1)
	var amulets := screen.find_child("Amulet_mirror", true, false) as Control
	assert_true(amulets == null or not amulets.is_visible_in_tree(), "no hay botón de amuletos en 3D")


func test_el_tanto_se_elige_con_flechitas() -> void:
	var dial := TantoDial.new([0, 4, 5, 20, 21, 27, 33] as Array[int], 27)
	add_child_autofree(dial)
	assert_eq(dial.value, 27)
	dial.nudge(1, 1)
	assert_eq(dial.value, 33, "salta al siguiente que se puede declarar")
	dial.nudge(10, -1)
	assert_eq(dial.value, 21)
	dial.nudge(1, -1)
	assert_eq(dial.value, 20)
	dial.nudge(10, -1)
	assert_eq(dial.value, 5)
	var got := [-1]
	dial.declared.connect(func(v: int) -> void: got[0] = v)
	(dial.find_child("Declare", true, false) as Button).pressed.emit()
	assert_eq(got[0], 5)


func test_el_mazo_va_a_la_derecha_del_pie() -> void:
	var s := _setup()
	var table: Table3D = s[2]
	var h := table.presenter.hand()
	h.mano = TablePresenter.PLAYER
	table.sync()
	var deck := (s[3] as Bar3D).marker("Deck")
	assert_lt(deck.position.x, 0.0, "sos mano: a la derecha del rival, que te queda a la izquierda")
	assert_lt(deck.position.z, 0.0, "del lado del rival")
	h.mano = TablePresenter.DEALER
	table.sync()
	assert_gt(deck.position.x, 0.0, "es mano el rival: a tu derecha")
	assert_gt(deck.position.z, 0.0, "de tu lado")


func test_fichas_por_rival_vencido_y_porotos_del_truco() -> void:
	var s := _setup()
	var rc: RunController = s[0]
	var table: Table3D = s[2]
	assert_eq(table.props().chips(), rc.state.round - 1, "primer rival: ninguna ficha")
	rc.state.round = 3
	table.sync()
	assert_eq(table.props().chips(), 2)
	table.props().set_stake(3)
	assert_eq(table.props().beans(), 3)
	table.props().set_stake(0)
	assert_eq(table.props().beans(), 0)


func test_tus_amuletos_van_de_tu_lado() -> void:
	for spot: Vector3 in Table3D.AMULET_SPOTS:
		assert_gt(spot.z, 0.0)


func test_los_cantos_se_quedan_con_tu_mano() -> void:
	var s := _setup()
	var screen: BaseScreen = s[1]
	var bar: Bar3D = s[3]
	var cam := CameraRig.new()
	cam.mouse_look = false
	bar.add_child(cam)
	cam.setup(bar)
	bar.camera = cam
	cam.go_to(&"CamSeat", true)
	cam._apply()
	screen.follow_hand()
	var ring := screen.find_child("Ring", true, false) as Control
	var at_cards := ring.position.y
	_hold(cam, Vector2(0.5, 0.1), 3.0)
	cam._apply()
	screen.follow_hand()
	assert_gt(ring.position.y, at_cards + 150.0, "mirando arriba los cantos bajan con la mano")
	assert_false(ring.visible, "y no se ven")


func test_los_cantos_quedan_parejos_sobre_el_arco() -> void:
	var spots: Array = load("res://ui/screens/table_screen.gd").ring_spots(6)
	var gaps: Array[float] = []
	for i in range(1, spots.size()):
		gaps.append(((spots[i] - spots[i - 1]) * Vector2(16, 9)).length())
	for g in gaps:
		assert_almost_eq(g, gaps[0], gaps[0] * 0.1, "misma distancia entre cantos")


func test_inclinado_las_cartas_jugadas_dicen_que_son() -> void:
	var s := _setup()
	var table: Table3D = s[2]
	var bar: Bar3D = s[3]
	var cam := CameraRig.new()
	cam.mouse_look = false
	bar.add_child(cam)
	cam.setup(bar)
	bar.camera = cam
	cam.go_to(&"CamSeat", true)
	var p := table.presenter
	while p.card_action(0) == null:
		if p.dealer_should_play():
			p.dealer_step()
		elif not p.call_buttons().is_empty():
			p.act(p.call_buttons()[0]["action"])
		else:
			break
	p.act(p.card_action(0))
	var played: Card = p.hand().played[TablePresenter.PLAYER][0]
	var node: Card3D = table._cards[played]
	node.set_hover(true)
	assert_eq(table.peeked_text(), "", "sentado derecho no pasa nada")
	for i in 60:
		cam.look(Vector2(0.5, 0.9), 1.0 / 60.0, 0, true)
	node.set_hover(true)
	assert_eq(table.peeked_text(), TablePresenter.card_text(played))
	node.set_hover(false)
	assert_eq(table.peeked_text(), "")


func test_los_cantos_no_se_pisan() -> void:
	var s := _setup()
	var screen: BaseScreen = s[1]
	var items: Array[Control] = []
	for old in screen._ring.get_children():
		screen._ring.remove_child(old)
		old.free()
	for t in ["Quiero", "No quiero", "Quiero retruco", "Envido", "Real envido", "Falta envido",
			"Me voy al mazo", "Acusar…", "Mostrar el tanto"]:
		var b := Button.new()
		b.text = t
		screen._actions.add_child(b)
	screen._arrange_ring()
	for c in screen._ring.get_children():
		items.append(c as Control)
	var rects: Array[Rect2] = []
	for c in items:
		rects.append(c.get_global_rect())
	for i in rects.size():
		for j in range(i + 1, rects.size()):
			assert_false(rects[i].intersects(rects[j]), "%s pisa a %s" % [items[i].name, items[j].name])


func test_el_rival_muestra_las_cartas_del_tanto() -> void:
	var cards: Array[Card] = [Card.new(Card.Suit.ORO, 7), Card.new(Card.Suit.ORO, 6), Card.new(Card.Suit.ESPADA, 1)]
	var best := TablePresenter.envido_cards(cards)
	assert_eq(best.size(), 2)
	assert_true(cards[0] in best and cards[1] in best, "7 y 6 de oro: 33")
	var s := _setup()
	var table: Table3D = s[2]
	var p := table.presenter
	p._apply([GameEvent.make(&"tanto_shown", {"player": TablePresenter.DEALER, "points": 30})] as Array[GameEvent])
	table.sync()
	assert_false(table.showing().is_empty(), "el rival pone sus cartas del tanto en la mesa")
	var shown: Card = table.showing()[0]
	var node: Card3D = table._cards[shown]
	assert_true(node.get_node("Face").visible, "boca arriba")
	node.set_hover(true)
	assert_eq(table.peeked_text(), TablePresenter.card_text(shown), "sin inclinarte, dice qué carta mostró")
	node.set_hover(false)
	table._show_until = 0.0
	table._process(0.0)
	assert_true(table.showing().is_empty())
	if shown in p.hand().cards[TablePresenter.DEALER]:
		assert_false(node.get_node("Face").visible, "vuelve a su mano tapada")


func test_se_reparte_de_a_una_empezando_por_el_mano() -> void:
	var s := _setup()
	var table: Table3D = s[2]
	var h := table.presenter.hand()
	var order := Table3D.deal_order(h)
	assert_eq(order.size(), h.cards[0].size() + h.cards[1].size() + h.played[0].size() + h.played[1].size())
	assert_true(order[0] in h.cards[h.mano] or order[0] in h.played[h.mano], "la primera es del mano")
	assert_true(order[1] in h.cards[1 - h.mano] or order[1] in h.played[1 - h.mano], "la segunda del pie")


func test_la_mano_nueva_espera_el_reparto() -> void:
	Table3D.animate_deals = true
	var s := _setup()
	Table3D.animate_deals = false
	var table: Table3D = s[2]
	assert_true(table.dealing(), "arranca mezclando")
	for c in table.card_nodes():
		assert_false(c.visible, "nadie tiene cartas hasta que se reparten")
	await wait_seconds(Table3D.SHUFFLE_RISE + Table3D.SHUFFLE_SECONDS + Table3D.SHUFFLE_DROP + 8 * Table3D.DEAL_STEP + 0.5)
	assert_false(table.dealing())
	for c in table.card_nodes():
		assert_true(c.visible)


func test_textos_largos_vecinos_se_intercalan() -> void:
	assert_true(BaseScreen.too_close("Arriesgar $112", "Arriesgar $225"))
	assert_false(BaseScreen.too_close("Truco", "Arriesgar $225"))
	var spots := BaseScreen.row_spots(["Arriesgar $112", "Arriesgar $225", "Arriesgar $450"] as Array[String], 0.2, 0.1)
	assert_ne(spots[0].z, spots[1].z, "uno más atrás que el otro")
	assert_ne(spots[1].z, spots[2].z)


func test_quedarte_sentado_el_bar_te_deja_jugar_desde_la_mesa() -> void:
	var rc := RunController.new(Economy.load_from(), MetaState.new(), 4, META_PATH)
	rc.start_run(&"normal")
	var r := _rig()
	var router := ScreenRouter.new()
	router.world = r[0]
	router.stay_seated = true
	add_child_autofree(router)
	router.setup(rc)
	assert_eq(router.camera_marker(), &"CamSeat")
	var screen := router.get_child(router.get_child_count() - 2) as Control
	for c in router.get_children():
		if c is BaseScreen:
			screen = c
	assert_eq(screen.mouse_filter, Control.MOUSE_FILTER_IGNORE, "la pantalla no le tapa el mouse a la cámara")
	var sit := router.find_child("Sit", true, false) as Button
	assert_not_null(sit)
	assert_eq(sit.text, UiText.t("UI_BAR_PLAY"))
	assert_string_contains(router.hud_text(), "deuda")
	sit.pressed.emit()
	assert_eq(rc.phase, RunController.Phase.MATCH)


func test_al_enderezarte_vuelven_tus_cartas() -> void:
	var cam: CameraRig = _rig()[1]
	cam.go_to(&"CamSeat", true)
	for i in 60:
		cam.look(Vector2(0.5, 0.35), 1.0 / 60.0, 0, true)
	for i in 120:
		cam.look(Vector2(0.5, 0.35), 1.0 / 60.0, 0, false)
	assert_true(cam.looking_at_hand(), "sin bajar el mouse, la cabeza vuelve a las cartas")
	_hold(cam, Vector2(0.5, 0.2), 3.0)
	assert_false(cam.looking_at_hand(), "moviendo el mouse se mira otra cosa")


func test_las_pantallas_del_bar_se_escriben_sobre_los_objetos() -> void:
	var rc := RunController.new(Economy.load_from(), MetaState.new(), 4, META_PATH)
	var r := _rig()
	var router := ScreenRouter.new()
	router.world = r[0]
	add_child_autofree(router)
	router.setup(rc)
	var deck := router.find_child("Deck_normal", true, false) as Button
	assert_not_null(deck, "inicio: los mazos sobre la mesa")
	assert_null(router.find_child("*DeckPicker*", true, false), "sin la lista 2D")
	deck.pressed.emit()
	assert_eq(rc.phase, RunController.Phase.BAR)


func test_el_bar_esta_vivo_y_el_rival_te_espera() -> void:
	var bar: Bar3D = BAR.instantiate()
	add_child_autofree(bar)
	var life := bar.life
	assert_not_null(life.bartender, "hay cantinero")
	assert_eq(life.souls.size(), BarLife.SOUL_COUNT)
	var start := life.souls[0].position
	for i in 600:
		life.step(1.0 / 30.0)
	assert_ne(life.souls[0].position, start, "las almas caminan")
	for soul in life.souls:
		assert_gt(Vector2(soul.position.x, soul.position.z).length(), 1.2, "lejos de la mesa")
	bar.set_rival_pose(&"away", true)
	assert_false(bar.slot("rival").visible, "en el menú la mesa está vacía")
	bar.set_rival_pose(&"waiting", true)
	assert_true(bar.slot("rival").visible)
	assert_gt(bar.slot("rival").position.x, 0.3, "parado al lado de su silla")
	bar.set_rival_pose(&"seated", true)
	assert_almost_eq(bar.slot("rival").position.x, 0.0, 0.001)


func test_el_menu_de_inicio_tiene_velo_y_panel() -> void:
	var rc := RunController.new(Economy.load_from(), MetaState.new(), 4, META_PATH)
	var r := _rig()
	var router := ScreenRouter.new()
	router.world = r[0]
	add_child_autofree(router)
	router.setup(rc)
	assert_not_null(router.find_child("MenuPanel", true, false), "el menú a la izquierda")
	assert_not_null(router.find_child("MenuInfo", true, false), "tus datos a la derecha")
	assert_true(router._backdrop.visible, "velo negro entre el menú y el bar")
	assert_lt(router._backdrop.color.a, 0.7, "translúcido: el bar se ve detrás")
	assert_eq((r[0] as Bar3D).rival_pose(), &"away")
	(router.find_child("Deck_normal", true, false) as Button).pressed.emit()
	assert_eq((r[0] as Bar3D).rival_pose(), &"waiting", "el rival ya está, a medio sentarse")


func test_acusar_abre_una_flor() -> void:
	var s := _setup()
	var screen: BaseScreen = s[1]
	var options := [{"text": "Carta de más", "name": "Acc_A", "accusation": null},
		{"text": "Cartas marcadas", "name": "Acc_B", "accusation": null},
		{"text": "Cómplice", "name": "Acc_C", "accusation": null}]
	screen.bloom(options)
	assert_not_null(screen.find_child("Flower", true, false))
	assert_not_null(screen.find_child("Acc_B", true, false), "cada acusación es un pétalo")
	for c in screen._ring.get_children():
		if c.name != "Flower":
			assert_false((c as Control).visible, "los cantos se esconden")
	(screen.find_child("CancelAccuse", true, false) as Button).pressed.emit()
	assert_null(screen._flower, "cancelar cierra la flor")


func test_al_terminar_la_mesa_la_cabeza_queda_libre() -> void:
	var rc := RunController.new(Economy.load_from(), MetaState.new(), 4, META_PATH)
	rc.start_run(&"normal")
	rc.enter_match()
	var r := _rig()
	var cam: CameraRig = r[1]
	var screen: BaseScreen = SCENE.instantiate()
	screen.world = r[0]
	add_child(screen)
	screen.setup(rc)
	cam.go_to(&"CamSeat", true)
	cam.ui_hold = true
	screen.free()
	assert_false(cam.ui_hold, "ganar con el mouse sobre un botón no traba la cámara")
	var before := cam.turn_degrees()
	_hold(cam, Vector2(0.02, 0.4), 3.0)
	assert_gt(cam.turn_degrees().y, before.y + 60.0, "se puede girar hacia la barra")


func test_el_guardarropas_de_la_barra() -> void:
	var rc := RunController.new(Economy.load_from(), MetaState.new(), 4, META_PATH)
	rc.start_run(&"normal")
	rc.enter_match()
	var m := rc.table().truco_match
	m.start_hand()
	m.award(0, m.target)
	rc.finish_match()
	if rc.phase == RunController.Phase.ONE_MORE:
		rc.skip_one_more()
	rc.state.loadout.equip(AmuletDef.load_all()[&"hat"])
	var r := _rig()
	var router := ScreenRouter.new()
	router.world = r[0]
	add_child_autofree(router)
	router.setup(rc)
	router.find_child("GoShop", true, false).pressed.emit()
	assert_not_null((r[0] as Bar3D).find_child("WardrobeBox", true, false), "la caja está sobre la barra")
	var shop: Node = null
	for c in router.get_children():
		if c is BaseScreen:
			shop = c
	var hat: ShopItem = null
	for it: ShopItem in shop.shop_items():
		if it.owned and it.def.id == &"hat":
			hat = it
	shop.inspect(hat)
	(router.find_child("Store_hat", true, false) as Button).pressed.emit()
	assert_false(rc.state.loadout.has(&"hat"))
	var stored: ShopItem = null
	for it: ShopItem in shop.shop_items():
		if it.has_meta("wardrobe"):
			stored = it
	assert_not_null(stored, "lo guardado se ve arriba de la caja")
	shop.inspect(stored)
	(router.find_child("Retrieve", true, false) as Button).pressed.emit()
	assert_true(rc.state.loadout.has(&"hat"), "se retira desde la vista de cerca")


func _setup_with(ids: Array) -> Array:
	var rc := RunController.new(Economy.load_from(), MetaState.new(), 4, META_PATH)
	rc.start_run(&"normal")
	for id: StringName in ids:
		rc.state.loadout.equip(AmuletDef.load_all()[id])
	rc.enter_match()
	var bar: Bar3D = BAR.instantiate()
	add_child_autofree(bar)
	var screen: BaseScreen = SCENE.instantiate()
	screen.world = bar
	add_child_autofree(screen)
	screen.setup(rc)
	return [rc, screen]


func test_el_marcador_se_elige_en_flores() -> void:
	var s := _setup_with([&"marker"])
	var rc: RunController = s[0]
	var screen: BaseScreen = s[1]
	screen._on_amulet(&"marker", &"marker")
	assert_not_null(screen.find_child("FlowerTitle", true, false), "la flor dice qué se elige")
	assert_null(screen.find_child("*OptionButton*", true, false), "sin listas 2D")
	assert_null(screen.find_child("PickCard0", true, false), "la carta no es un pétalo")
	screen._table3d.player_card(0).press()
	screen._after_action()  # el rival juega o canta: la flor sigue abierta
	var seven := screen.find_child("PickNumber7", true, false) as Button
	assert_not_null(seven, "después, los números")
	var before := rc.state.loadout.charges_left(&"marker")
	seven.pressed.emit()
	assert_null(screen._flower, "al elegir el número se usa y se cierra")
	assert_null(screen._table3d.focused_card(), "vuelve a la mano con el valor nuevo")
	assert_eq(rc.state.loadout.charges_left(&"marker"), before - 1)
	assert_eq(rc.table().truco_match.hand.cards[0][0].effective_number(), 7)


func test_el_mazo_aparte_se_elige_en_flores() -> void:
	var s := _setup_with([&"spare_deck"])
	var rc: RunController = s[0]
	var screen: BaseScreen = s[1]
	var before := rc.state.loadout.charges_left(&"spare_deck")
	screen._on_amulet(&"spare_deck", &"spare_deck")
	screen._table3d.player_card(1).press()
	var pick := screen.find_child("PickSpare0", true, false) as Button
	if pick != null:
		pick.pressed.emit()
	assert_null(screen._flower)
	assert_eq(rc.state.loadout.charges_left(&"spare_deck"), before - 1)


func test_el_bar_avisa_si_el_guardarropas_tiro_algo() -> void:
	var meta := MetaState.new()
	meta.wardrobe = {"id": &"hat", "level": 1, "paid": 0, "fee": 0, "runs": 2}
	var rc := RunController.new(Economy.load_from(), meta, 4, META_PATH)
	var r := _rig()
	var router := ScreenRouter.new()
	router.world = r[0]
	add_child_autofree(router)
	router.setup(rc)
	(router.find_child("Deck_normal", true, false) as Button).pressed.emit()
	assert_eq(rc.wardrobe_lost, &"hat")
	assert_not_null(router.find_child("WardrobeGone", true, false), "el aviso está en el bar")
	(router.find_child("Sit", true, false) as Button).pressed.emit()
	assert_eq(rc.wardrobe_lost, &"", "se olvida al sentarse")


func test_al_empezar_la_run_la_barra_esta_abierta() -> void:
	var rc := RunController.new(Economy.load_from(), MetaState.new(), 4, META_PATH)
	rc.start_run(&"normal")
	var r := _rig()
	var router := ScreenRouter.new()
	router.world = r[0]
	add_child_autofree(router)
	router.setup(rc)
	assert_eq(router.camera_marker(), &"CamBar")
	router.find_child("GoShop", true, false).pressed.emit()
	assert_eq(rc.phase, RunController.Phase.SHOP)
	assert_eq(router.camera_marker(), &"CamShop", "directo a la barra, sin preguntar")
	router.find_child("Next", true, false).pressed.emit()
	assert_eq(rc.phase, RunController.Phase.BAR)
	assert_eq(rc.state.round, 1)
	assert_eq(router.camera_marker(), &"CamBar", "de vuelta en el bar, de pie")
	assert_not_null(router.find_child("Sit", true, false))


func test_al_ganar_un_solo_cartel_para_ir_a_la_barra() -> void:
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
	var go := 0
	for b in router.find_children("*", "Button", true, false):
		if (b as Button).text.contains(UiText.t("UI_SHOP_GO")):
			go += 1
	assert_eq(go, 1, "el cartel está solo en la barra")
	var hint := router.find_child("GoShopHint", true, false) as Control
	assert_not_null(hint, "una flechita en la mesa avisa")
	assert_eq(hint.mouse_filter, Control.MOUSE_FILTER_IGNORE)


func test_con_el_marcador_tocar_la_carta_no_la_juega() -> void:
	var s := _setup_with([&"marker"])
	var rc: RunController = s[0]
	var screen: BaseScreen = s[1]
	var hand := rc.table().truco_match.hand
	var in_hand: int = hand.cards[0].size()
	screen._on_amulet(&"marker", &"marker")
	var card: Card = hand.cards[0][0]
	screen._table3d.player_card(0).press()
	assert_eq(hand.cards[0].size(), in_hand, "la carta sigue en la mano")
	assert_eq(screen._table3d.focused_card(), card, "la carta vino al frente")
	var lamp := screen.world.get_node_or_null("LampLight") as Light3D
	if lamp != null:
		assert_lt(lamp.light_energy, float(lamp.get_meta("bright")), "el bar se oscurece")
	assert_not_null(screen.find_child("PickNumber7", true, false))
	(screen.find_child("CancelAccuse", true, false) as Button).pressed.emit()
	assert_false(screen._table3d.card_pick.is_valid(), "cancelar vuelve a jugar normal")
	assert_null(screen._table3d.focused_card(), "y la carta vuelve a la mano")
	if lamp != null:
		assert_eq(lamp.light_energy, float(lamp.get_meta("bright")))


func test_los_amuletos_dicen_su_nombre_solo_al_pasar_el_mouse() -> void:
	var s := _setup_with([&"marker"])
	var screen: BaseScreen = s[1]
	var token: AmuletToken = screen._table3d.amulet_tokens()[0]
	assert_false(token._label.visible)
	token._hover(true)
	assert_true(token._label.visible)
	token._hover(false)
	assert_false(token._label.visible)
