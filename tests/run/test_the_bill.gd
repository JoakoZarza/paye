extends GutTest
## La cuenta final del bar y la mano contra el Gualicho (Plan 5b, Tarea 5).

const META_PATH := "user://test_meta_bill.json"
const BILL := 10000000
const FINAL_ENTRY := 8000
const T := TrucoAction.Type

var _economy: Economy
var _defs: Dictionary


func before_all() -> void:
	_economy = Economy.load_from()
	_defs = AmuletDef.load_all()


func after_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(META_PATH))


func _types(events: Array[GameEvent]) -> Array:
	return events.map(func(e: GameEvent) -> StringName: return e.type)


func _event(events: Array[GameEvent], type: StringName) -> GameEvent:
	for e in events:
		if e.type == type:
			return e
	return null


## Lleva la run a la final y la gana. `extra` es la plata de más sobre la entrada.
func _win_final(rc: RunController, extra: int, fiado := 0, debt := 0) -> Array[GameEvent]:
	rc.start_run(&"normal")
	rc.state.round = 9
	rc.state.money = FINAL_ENTRY + extra
	rc.state.fiado = fiado
	rc.state.debt = debt
	rc.enter_match()
	var m := rc.table().truco_match
	m.start_hand()
	m.award(0, m.target)
	return rc.finish_match()


## Termina la mano contra el Gualicho con el marcador dado.
func _end_bill_hand(rc: RunController, player_points: int, gualicho_points: int) -> Array[GameEvent]:
	var m := rc.table().truco_match
	m.apply(TrucoAction.make(T.MAZO, m.hand.current_player()))
	assert_true(m.hand.is_over())
	m.scores.assign([player_points, gualicho_points])
	return rc.finish_bill_hand()


func _controller(meta := MetaState.new()) -> RunController:
	return RunController.new(_economy, meta, 9, META_PATH)


func test_premio_final_es_fijo() -> void:
	var rc := _controller()
	var events := _win_final(rc, 0)
	assert_eq(_event(events, &"prize_paid").data["total"], BILL)


func test_cuenta_exacta_se_paga_sin_evento() -> void:
	var rc := _controller()
	var events := _win_final(rc, 0)
	var types := _types(events)
	assert_false(&"bill_amulets_sold" in types)
	assert_false(&"bill_hand_started" in types)
	assert_eq(_event(events, &"bill_paid").data, {"bill": BILL, "left": 0})
	assert_eq(rc.phase, RunController.Phase.FREE)
	assert_eq(rc.state.money, 0)


func test_sobra_plata_y_te_retiras() -> void:
	var meta := MetaState.new()
	var rc := _controller(meta)
	var events := _win_final(rc, 700, 100, 200)
	assert_eq(_event(events, &"bill_paid").data, {"bill": BILL + 300, "left": 400})
	assert_true(rc.can_retire())
	assert_has(_types(rc.retire()), &"run_retired")
	assert_eq(rc.phase, RunController.Phase.RETIRED)
	assert_eq(meta.debt, 0)
	assert_false(meta.run_in_progress)


func test_sobra_plata_y_te_condenas() -> void:
	var meta := MetaState.new()
	var rc := _controller(meta)
	_win_final(rc, 500)
	assert_has(_types(rc.condemn()), &"run_condemned")
	assert_eq(rc.phase, RunController.Phase.CONDEMNED)
	assert_eq(meta.debt, 0)
	assert_eq(rc.condemn()[0].type, &"illegal_action", "no se condena dos veces")
	assert_eq(rc.retire()[0].type, &"illegal_action")
	assert_eq(rc.die()[0].type, &"illegal_action")
	assert_eq(meta.runs_played, 1)


func test_la_cuenta_vende_amuletos_y_alcanza() -> void:
	var rc := _controller()
	rc.start_run(&"normal")
	rc.state.loadout.equip(_defs[&"rosary"])
	rc.state.paid_for[&"rosary"] = 200
	rc.state.round = 9
	rc.state.money = FINAL_ENTRY
	rc.state.fiado = 100
	rc.enter_match()
	var m := rc.table().truco_match
	m.start_hand()
	m.award(0, m.target)
	var events := rc.finish_match()
	assert_eq(_event(events, &"bill_amulets_sold").data, {"amount": 100, "ids": [&"rosary"]})
	assert_false(&"bill_hand_started" in _types(events))
	assert_eq(rc.phase, RunController.Phase.FREE)
	assert_eq(rc.state.money, 0)
	assert_false(rc.state.loadout.has(&"rosary"))


func test_la_cuenta_sin_amuletos_va_a_la_mano() -> void:
	var meta := MetaState.new()
	var rc := _controller(meta)
	var events := _win_final(rc, 0, 0, 1000)
	assert_false(&"bill_amulets_sold" in _types(events))
	assert_eq(_event(events, &"bill_hand_started").data["missing"], 1000)
	assert_eq(rc.phase, RunController.Phase.BILL_HAND)
	assert_eq(rc.table().brain.profile.sin, &"gualicho")
	assert_eq(meta.debt, 1000, "si abandonás en la mano, debés lo que faltaba")
	assert_false(rc.can_retire())


func test_finish_bill_hand_con_la_mano_sin_terminar_es_ilegal() -> void:
	var rc := _controller()
	_win_final(rc, 0, 0, 1000)
	assert_eq(rc.finish_bill_hand()[0].type, &"illegal_action")
	assert_eq(rc.phase, RunController.Phase.BILL_HAND)


func test_mano_contra_el_gualicho_ganada_te_libera() -> void:
	var meta := MetaState.new()
	var rc := _controller(meta)
	_win_final(rc, 0, 0, 1000)
	assert_has(_types(_end_bill_hand(rc, 2, 1)), &"bill_hand_won")
	assert_eq(rc.phase, RunController.Phase.FREE)
	assert_eq(rc.state.debt, 0)
	assert_eq(meta.debt, 0)
	assert_true(rc.can_retire())


func test_mano_contra_el_gualicho_perdida_arrastra_lo_que_faltaba() -> void:
	var meta := MetaState.new()
	var rc := _controller(meta)
	_win_final(rc, 300, 200, 1000)
	var types := _types(_end_bill_hand(rc, 0, 2))
	assert_has(types, &"bill_hand_lost")
	assert_has(types, &"run_died")
	assert_eq(rc.phase, RunController.Phase.DEAD)
	assert_eq(meta.debt, 900)
	assert_eq(MetaState.load_from(META_PATH).debt, 900)


func test_empate_contra_el_gualicho_es_derrota() -> void:
	var rc := _controller()
	_win_final(rc, 0, 0, 1000)
	assert_has(_types(_end_bill_hand(rc, 1, 1)), &"bill_hand_lost")
	assert_eq(rc.phase, RunController.Phase.DEAD)


func test_morir_antes_del_final_arrastra_el_fiado() -> void:
	var meta := MetaState.new()
	meta.debt = 50
	var rc := _controller(meta)
	rc.start_run(&"normal")
	rc.state.fiado = 80
	rc.enter_match()
	var m := rc.table().truco_match
	m.start_hand()
	m.award(1, m.target)
	assert_has(_types(rc.finish_match()), &"run_died")
	assert_eq(meta.debt, 130)


func test_otra_mano_en_la_cuenta_es_derrota() -> void:
	var rc := _controller()
	_win_final(rc, 0, 0, 1000)
	var m := rc.table().truco_match
	m.apply(TrucoAction.make(T.MAZO, m.hand.current_player()))
	# Repartir otra mano para buscar revancha no vale.
	rc.systems.start_hand()
	m.scores.assign([5, 0])
	assert_has(_types(rc.finish_bill_hand()), &"bill_hand_lost")
