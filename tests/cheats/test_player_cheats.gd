extends GutTest

const H := preload("res://tests/cheats/cheat_test_helpers.gd")
const P := CheatTable.PlayerCheat
const TRIALS := 2000


func _cards() -> Array:
	return [H.cards([[H.E, 4], [H.B, 5], [H.C, 6]]), H.cards([[H.O, 7], [H.E, 1], [H.C, 4]])]


func _caught_rate(kind: P, suspicion: float) -> float:
	var caught := 0
	for i in TRIALS:
		var t := H.table(H.profile(0.0, 0), i)
		t.start_hand(-1, _cards(), 0)
		t.brain.mood.suspicion = suspicion
		if t.use_player_cheat(kind)[0].type == &"player_caught":
			caught += 1
	return float(caught) / TRIALS


## Usa la trampa hasta que no lo pesquen y devuelve el evento de información.
func _info(kind: P) -> GameEvent:
	for s in 200:
		var t := H.table(H.profile(0.0, 0), s)
		t.start_hand(-1, _cards(), 0)
		var e: GameEvent = t.use_player_cheat(kind)[0]
		if e.type == &"player_cheat_info":
			return e
	return null


func test_espejo_revela_la_mano() -> void:
	var e := _info(P.MIRROR)
	var keys: Array = e.data["cards"].map(func(c: Card) -> String: return c.key())
	assert_eq(keys, ["7_ORO", "1_ESPADA", "4_COPA"])


func test_marcadas_revela_el_rango_mas_alto() -> void:
	assert_eq(_info(P.MARKED).data["best_rank"], 14)


func test_riesgo_sube_con_la_sospecha() -> void:
	var calm := _caught_rate(P.MIRROR, 0.0)
	var wary := _caught_rate(P.MIRROR, 1.0)
	assert_almost_eq(calm, CheatTable.MIRROR_RISK, 0.04)
	assert_gt(wary, calm + 0.15)


func test_marcadas_cada_vez_mas_riesgosa() -> void:
	var first := 0
	var third := 0
	for i in TRIALS:
		var t := H.table(H.profile(0.0, 0), i)
		t.start_hand(-1, _cards(), 0)
		if t.use_player_cheat(P.MARKED)[0].type == &"player_caught":
			first += 1
			continue
		if t.use_player_cheat(P.MARKED)[0].type == &"player_caught":
			continue
		if t.use_player_cheat(P.MARKED)[0].type == &"player_caught":
			third += 1
	assert_gt(third, first * 1.5)


func test_pescado_pierde_la_mano() -> void:
	for i in TRIALS:
		var t := H.table(H.profile(0.0, 0), i)
		t.start_hand(-1, _cards(), 0)
		var events := t.use_player_cheat(P.MIRROR)
		if events[0].type != &"player_caught":
			continue
		assert_true(t.truco_match.hand.is_over())
		assert_eq(t.truco_match.scores, [0, 1])
		assert_gt(t.brain.mood.suspicion, 0.0)
		assert_gt(t.brain.mood.tilt, 0.0)
		return
	fail_test("nunca lo pescaron en %d intentos" % TRIALS)


func test_trampa_con_la_mano_terminada_es_ilegal() -> void:
	var t := H.table(H.profile(0.0, 0))
	t.start_hand(-1, _cards(), 0)
	t.player_action(TrucoAction.make(H.T.MAZO, 0))
	assert_eq(t.use_player_cheat(P.MIRROR)[0].type, &"illegal_action")
