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


func test_rival_por_ronda() -> void:
	var rc := _controller()
	assert_eq(rc.rival_for(1).id, &"agresivo")
	assert_eq(rc.rival_for(2).id, &"mentiroso")
	assert_eq(rc.rival_for(3).id, &"tramposo")
	var boss := rc.rival_for(4)
	assert_eq(boss.id, &"agresivo")
	assert_gt(boss.aggression, rc.rival_for(1).aggression)
	rc.start_run(&"normal")
	rc.state.round = 4
	rc.state.money = 100000
	var events := rc.enter_match()
	assert_eq(events[0].data["target"], 30)
	assert_true(events[0].data["boss"])


func test_ganar_cobra_y_abre_la_tienda() -> void:
	var rc := _controller()
	rc.start_run(&"normal")
	rc.enter_match()
	assert_eq(rc.state.money, 35)
	_end_match(rc, 0)
	var events := rc.finish_match()
	assert_eq(events[0].type, &"prize_paid")
	assert_eq(events[0].data["total"], 600)
	assert_eq(rc.state.money, 635)
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
	assert_eq(rc.finish_match()[0].data["total"], 1200)


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


func test_retiro_con_10_millones_exactos() -> void:
	var meta := MetaState.new()
	meta.debt = 999
	var rc := _controller(meta)
	rc.start_run(&"normal")
	rc.state.debt = 0
	rc.enter_match()
	_end_match(rc, 0)
	rc.finish_match()
	assert_false(rc.can_retire())
	rc.state.money = _economy.goal
	assert_true(rc.can_retire())
	assert_has(_types(rc.retire()), &"run_retired")
	assert_eq(rc.phase, RunController.Phase.RETIRED)
	assert_eq(meta.debt, 0)


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
	assert_eq(rc.finish_match()[0].data["total"], 1200)


func test_fuera_de_fase_es_ilegal() -> void:
	var rc := _controller()
	rc.start_run(&"normal")
	assert_eq(rc.finish_match()[0].type, &"illegal_action")
	assert_eq(rc.next_round()[0].type, &"illegal_action")
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
	rc.buy(0)
	var fiado := rc.state.fiado
	assert_gt(fiado, 0)
	var loaded := MetaState.load_from(META_PATH)
	assert_true(loaded.run_in_progress)
	var rc2 := _controller(loaded)
	rc2.start_run(&"normal")
	assert_eq(rc2.state.debt, fiado)
	assert_eq(loaded.runs_played, 1)


func test_jefe_abre_la_tienda_especial() -> void:
	var rc := _controller()
	rc.start_run(&"normal")
	rc.state.round = 4
	rc.state.money = 10000
	_win_round(rc)
	for d in rc.shop.offers:
		assert_ne(d.rarity, AmuletDef.Rarity.COMMON)


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
