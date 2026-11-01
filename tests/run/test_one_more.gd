extends GutTest
## Una mano más después de ganar (DISENO §6, Plan 5c decisión 7).

const META_PATH := "user://test_meta_one_more.json"
const T := TrucoAction.Type
const P := RunController.Phase

var _economy: Economy


func before_all() -> void:
	_economy = Economy.load_from()


func after_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(META_PATH))


func _types(events: Array[GameEvent]) -> Array:
	return events.map(func(e: GameEvent) -> StringName: return e.type)


## Gana la ronda 1 (premio 450, el rival suma puntos) y queda en la fase ONE_MORE.
func _won(s := 4) -> RunController:
	var rc := RunController.new(_economy, MetaState.new(), s, META_PATH)
	rc.start_run(&"normal")
	rc.enter_match()
	var m := rc.table().truco_match
	m.start_hand()
	m.award(1, 3)
	m.award(0, m.target)
	rc.finish_match()
	return rc


func _end_hand(rc: RunController, player_points: int, rival_points: int) -> Array[GameEvent]:
	var m := rc.table().truco_match
	m.apply(TrucoAction.make(T.MAZO, m.hand.current_player()))
	m.scores.assign([player_points, rival_points])
	return rc.finish_one_more()


func test_se_ofrece_despues_de_ganar() -> void:
	var rc := _won()
	assert_eq(rc.phase, P.ONE_MORE)
	assert_eq(rc.one_more_options(), [112, 225, 450] as Array[int])


func test_ganar_recupera_el_doble() -> void:
	var rc := _won()
	var money := rc.state.money
	assert_has(_types(rc.one_more(0.5)), &"one_more_started")
	assert_eq(rc.state.money, money - 225)
	assert_has(_types(_end_hand(rc, 2, 1)), &"one_more_won")
	assert_eq(rc.state.money, money + 225)
	assert_eq(rc.phase, P.SHOP)
	assert_eq(rc.shop.offers.size(), 3)


func test_perder_no_mata() -> void:
	var rc := _won()
	var money := rc.state.money
	rc.one_more(1.0)
	assert_has(_types(_end_hand(rc, 0, 3)), &"one_more_lost")
	assert_eq(rc.state.money, money - 450)
	assert_eq(rc.phase, P.SHOP)


func test_empate_es_del_rival() -> void:
	var rc := _won()
	rc.one_more(0.25)
	assert_has(_types(_end_hand(rc, 1, 1)), &"one_more_lost")


func test_saltear_va_a_la_tienda() -> void:
	var rc := _won()
	var money := rc.state.money
	assert_has(_types(rc.skip_one_more()), &"one_more_skipped")
	assert_eq(rc.phase, P.SHOP)
	assert_eq(rc.state.money, money)


func test_fraccion_invalida_y_fases_ilegales() -> void:
	var rc := _won()
	assert_eq(rc.one_more(0.3)[0].type, &"illegal_action")
	assert_eq(rc.finish_one_more()[0].type, &"illegal_action", "sin apuesta no hay mano que cerrar")
	rc.one_more(0.5)
	assert_eq(rc.one_more(0.5)[0].type, &"illegal_action", "no se apuesta dos veces")
	assert_eq(rc.skip_one_more()[0].type, &"illegal_action", "con la apuesta hecha no se saltea")
	assert_eq(rc.finish_one_more()[0].type, &"illegal_action", "la mano no terminó")
	assert_eq(rc.die()[0].type, &"illegal_action", "en una mano más no se muere")
	assert_eq(rc.phase, P.ONE_MORE)


func test_premio_neto_cero_se_saltea() -> void:
	var rc := RunController.new(_economy, MetaState.new(), 4, META_PATH)
	rc.start_run(&"normal")
	rc.enter_match()
	rc.state.fiado = 100000
	var m := rc.table().truco_match
	m.start_hand()
	m.award(0, m.target)
	# Retiene el 25%: el resto (338) sigue siendo premio neto.
	rc.finish_match()
	assert_eq(rc.phase, P.ONE_MORE)
	var broke := RunController.new(_economy, MetaState.new(), 4, META_PATH)
	broke.start_run(&"normal")
	broke.enter_match()
	var m2 := broke.table().truco_match
	m2.start_hand()
	m2.award(0, m2.target)
	broke.economy.fiado_retention = 1.0
	broke.state.fiado = 100000
	broke.finish_match()
	broke.economy.fiado_retention = 0.25
	assert_eq(broke.phase, P.SHOP, "todo el premio fue al fiado: no hay nada que arriesgar")


func test_no_aparece_en_la_final() -> void:
	var rc := RunController.new(_economy, MetaState.new(), 4, META_PATH)
	rc.start_run(&"normal")
	rc.state.round = 9
	rc.state.money = 100000
	rc.enter_match()
	var m := rc.table().truco_match
	m.start_hand()
	m.award(0, m.target)
	assert_false(&"one_more_offered" in _types(rc.finish_match()))
	assert_eq(rc.phase, P.FREE)


func test_otra_mano_no_salva_la_apuesta() -> void:
	var rc := _won()
	rc.one_more(0.5)
	var m := rc.table().truco_match
	m.apply(TrucoAction.make(T.MAZO, m.hand.current_player()))
	rc.systems.start_hand()
	m.scores.assign([4, 0])
	assert_has(_types(rc.finish_one_more()), &"one_more_lost")
