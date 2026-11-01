extends GutTest

const META_PATH := "user://test_meta_controller.json"

var _economy: Economy


func before_all() -> void:
	_economy = Economy.load_from()


func after_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(META_PATH))


func _controller(meta := MetaState.new(), s := 4) -> RunController:
	return RunController.new(_economy, meta, s, META_PATH)


## Termina el partido en curso a favor de `winner` (sin jugar).
func _end_match(rc: RunController, winner: int, loser_points := 3) -> void:
	var m := rc.table().truco_match
	m.start_hand()
	m.award(1 - winner, loser_points)
	m.award(winner, m.target)


func _types(events: Array[GameEvent]) -> Array:
	return events.map(func(e: GameEvent) -> StringName: return e.type)


func test_run_arranca_con_135_y_deuda_guardada() -> void:
	var meta := MetaState.new()
	meta.debt = 700
	var rc := _controller(meta)
	assert_has(_types(rc.start_run(&"normal")), &"run_started")
	assert_eq(rc.state.money, 135)
	assert_eq(rc.state.debt, 700)
	assert_eq(rc.phase, RunController.Phase.BAR)


func test_legado_se_equipa_y_se_consume() -> void:
	var meta := MetaState.new()
	meta.legacy = &"hat"
	var rc := _controller(meta)
	rc.start_run(&"normal")
	assert_true(rc.state.loadout.has(&"hat"))
	assert_eq(meta.legacy, &"")
	assert_eq(MetaState.load_from(META_PATH).legacy, &"")


func test_nueve_rondas_con_pecados_y_almas() -> void:
	var rc := _controller()
	assert_null(rc.rival_for(1), "sin run no hay rivales")
	rc.start_run(&"normal")
	for r in range(1, 10):
		assert_eq(rc.rival_for(r).sin, RivalCatalog.RUN_ORDER[r - 1])
	rc.state.round = 9
	rc.state.money = 100000
	var events := rc.enter_match()
	assert_eq(events[0].data["target"], 30)
	assert_true(events[0].data["final"])
	assert_eq(events[0].data["sin"], &"soberbia")


func test_misma_semilla_mismos_rivales() -> void:
	var a := _controller(MetaState.new(), 77)
	var b := _controller(MetaState.new(), 77)
	a.start_run(&"normal")
	b.start_run(&"normal")
	for r in range(1, 10):
		assert_eq(a.rival_for(r).id, b.rival_for(r).id)
		assert_eq(a.rival_for(r).aggression, b.rival_for(r).aggression)

func test_ganar_cobra_y_abre_la_tienda() -> void:
	var rc := _controller()
	rc.start_run(&"normal")
	rc.enter_match()
	assert_eq(rc.state.money, 35)
	_end_match(rc, 0)
	var events := rc.finish_match()
	assert_eq(events[0].type, &"prize_paid")
	assert_eq(events[0].data["total"], 450)
	assert_eq(rc.state.money, 485)
	assert_eq(rc.phase, RunController.Phase.SHOP)
	assert_eq(rc.shop.offers.size(), 3)
	rc.next_round()
	assert_eq(rc.state.round, 2)
	assert_eq(rc.phase, RunController.Phase.BAR)


func test_partido_perfecto_paga_el_doble() -> void:
	var rc := _controller()
	rc.start_run(&"normal")
	rc.enter_match()
	_end_match(rc, 0, 0)
	assert_eq(rc.finish_match()[0].data["total"], 900)


func test_perder_es_muerte() -> void:
	var meta := MetaState.new()
	var rc := _controller(meta)
	rc.start_run(&"normal")
	rc.enter_match()
	_end_match(rc, 1)
	assert_has(_types(rc.finish_match()), &"run_died")
	assert_eq(rc.phase, RunController.Phase.DEAD)
	assert_eq(meta.runs_played, 1)


func test_sin_entrada_es_muerte_y_el_fiado_es_deuda() -> void:
	var meta := MetaState.new()
	var rc := _controller(meta)
	rc.start_run(&"normal")
	rc.state.money = 50
	rc.state.fiado = 80
	assert_has(_types(rc.enter_match()), &"run_died")
	assert_eq(meta.debt, 80)
	assert_eq(MetaState.load_from(META_PATH).debt, 80)


func test_morir_sin_amuletos() -> void:
	var rc := _controller()
	rc.start_run(&"normal")
	rc.state.money = 0
	rc.enter_match()
	assert_eq(rc.legacy_choices().size(), 0)
	assert_false(rc.choose_legacy(&"hat"))
	assert_eq(rc.meta.legacy, &"")


func test_elegir_legado_al_morir() -> void:
	var meta := MetaState.new()
	meta.legacy = &"glasses"
	var rc := _controller(meta)
	rc.start_run(&"normal")
	rc.state.money = 0
	rc.enter_match()
	assert_true(rc.choose_legacy(&"glasses"))
	assert_eq(MetaState.load_from(META_PATH).legacy, &"glasses")


func test_viuda_duplica_premio_y_presupuesto() -> void:
	var rc := _controller()
	rc.start_run(&"widow")
	rc.enter_match()
	assert_eq(rc.table().brain.cheat_budget, rc.rival_for(1).cheat_budget * 2)
	_end_match(rc, 0)
	assert_eq(rc.finish_match()[0].data["total"], 900)


func test_fuera_de_fase_es_ilegal() -> void:
	var rc := _controller()
	rc.start_run(&"normal")
	assert_eq(rc.finish_match()[0].type, &"illegal_action")
	assert_eq(rc.next_round()[0].type, &"illegal_action")
	assert_eq(rc.retire()[0].type, &"illegal_action")
	assert_eq(rc.condemn()[0].type, &"illegal_action")
	assert_eq(rc.finish_bill_hand()[0].type, &"illegal_action")
	_win_round(rc)
	assert_eq(rc.phase, RunController.Phase.SHOP)
	assert_false(rc.can_retire(), "retirarse solo después de pagar la cuenta")
	assert_eq(rc.retire()[0].type, &"illegal_action")


func _win_round(rc: RunController) -> void:
	rc.enter_match()
	_end_match(rc, 0)
	rc.finish_match()


func test_tienda_solo_en_su_fase() -> void:
	var rc := _controller()
	rc.start_run(&"normal")
	assert_false(rc.buy(0)["ok"])
	_win_round(rc)
	rc.next_round()
	rc.state.money = 0
	rc.enter_match()
	assert_eq(rc.phase, RunController.Phase.DEAD)
	assert_eq(rc.shop.offers.size(), 0)
	assert_false(rc.buy(0)["ok"])
	assert_eq(rc.sell(&"hat"), 0)
	assert_false(rc.reroll())


func test_legado_solo_entre_los_que_tenias_al_morir() -> void:
	var rc := _controller()
	rc.start_run(&"normal")
	rc.state.money = 0
	rc.enter_match()
	rc.state.loadout.equip(AmuletDef.load_all()[&"hat"])
	assert_false(rc.choose_legacy(&"hat"))


func test_abandonar_la_run_conserva_el_fiado_como_deuda() -> void:
	var meta := MetaState.new()
	var rc := _controller(meta)
	rc.start_run(&"normal")
	_win_round(rc)
	rc.shop.offers.clear()
	rc.shop.offers.append(AmuletDef.load_all()[&"hat"])
	rc.state.money = 300
	rc.buy(0)
	var fiado := rc.state.fiado
	assert_gt(fiado, 0)
	var loaded := MetaState.load_from(META_PATH)
	assert_true(loaded.run_in_progress)
	var rc2 := _controller(loaded)
	rc2.start_run(&"normal")
	assert_eq(rc2.state.debt, fiado)
	assert_eq(loaded.runs_played, 1)


func test_pecado_abre_la_tienda_especial() -> void:
	var rc := _controller()
	rc.start_run(&"normal")
	rc.state.money = 10000
	_win_round(rc)
	for d in rc.shop.offers:
		assert_ne(d.rarity, AmuletDef.Rarity.COMMON)


func test_alma_abre_la_tienda_comun() -> void:
	var common := 0
	for seed in 20:
		var rc := _controller(MetaState.new(), seed)
		rc.start_run(&"normal")
		rc.state.round = 2
		rc.state.money = 10000
		_win_round(rc)
		for d in rc.shop.offers:
			if d.rarity == AmuletDef.Rarity.COMMON:
				common += 1
	assert_gt(common, 0)

func test_no_se_reinicia_una_run_en_curso() -> void:
	var rc := _controller()
	rc.start_run(&"normal")
	rc.state.money = 999
	assert_eq(rc.start_run(&"normal")[0].type, &"illegal_action")
	assert_eq(rc.state.money, 999)


func test_sin_run_es_ilegal() -> void:
	var rc := _controller()
	assert_eq(rc.enter_match()[0].type, &"illegal_action")
	assert_eq(rc.die()[0].type, &"illegal_action")


func test_pasar_de_ronda_cobra_interes_del_fiado() -> void:
	var rc := _controller()
	rc.start_run(&"normal")
	_win_round(rc)
	rc.state.fiado = 100
	var events := rc.next_round()
	assert_eq(events[0].type, &"fiado_interest")
	assert_eq(events[0].data, {"before": 100, "after": 110})
	assert_eq(rc.state.fiado, 110)


func test_premio_retiene_parte_del_fiado() -> void:
	var rc := _controller()
	rc.start_run(&"normal")
	rc.enter_match()
	rc.state.fiado = 1000
	_end_match(rc, 0)
	var e := rc.finish_match()[0]
	assert_eq(e.data["retained"], 112)
	assert_eq(rc.state.fiado, 888)
	assert_eq(rc.state.money, 35 + 450 - 112)


func test_entrada_informa_la_propina() -> void:
	var rc := _controller()
	rc.start_run(&"normal")
	rc.state.money = 1000
	assert_eq(rc.enter_match()[0].data["tip"], 70)


func test_el_chisme_dura_un_partido() -> void:
	var rc := _controller()
	rc.start_run(&"normal")
	rc.state.money = 100000
	rc.enter_match()
	rc.table().player_cheats_caught = 1
	_end_match(rc, 0)
	rc.finish_match()
	rc.next_round()
	rc.enter_match()
	assert_almost_eq(rc.table().brain.mood.suspicion, 0.3, 0.0001)
	_end_match(rc, 0)
	rc.finish_match()
	rc.next_round()
	rc.enter_match()
	assert_almost_eq(rc.table().brain.mood.suspicion, 0.0, 0.0001)


func test_la_plata_atrae_trampas_con_tope() -> void:
	var rc := _controller()
	rc.start_run(&"normal")
	var base := rc.rival_for(1).cheat_budget
	rc.state.money = 100 + 30 + 999
	var e := rc.enter_match()[0]
	assert_eq(e.data["greed_cheats"], 1, "tras entrada y propina quedan 947: una vez 5 entradas")
	assert_eq(rc.table().brain.cheat_budget, base + 1)
	var rich := _controller()
	rich.start_run(&"normal")
	rich.state.money = 1000000
	rich.enter_match()
	assert_eq(rich.table().brain.cheat_budget, rich.rival_for(1).cheat_budget + 2)


func test_las_almas_no_reciben_trampas_extra() -> void:
	var rc := _controller()
	rc.start_run(&"normal")
	rc.state.round = 2
	rc.state.money = 1000000
	assert_eq(rc.enter_match()[0].data["greed_cheats"], 0)
	assert_eq(rc.table().brain.cheat_budget, 0)
