extends GutTest

const H := preload("res://tests/cheats/cheat_test_helpers.gd")
const K := Cheat.Kind
const A := Accusation.Target


func _types(events: Array[GameEvent]) -> Array:
	return events.map(func(e: GameEvent) -> StringName: return e.type)


func test_acusar_la_manga_gana_la_mano() -> void:
	var t := H.table(H.profile(0.0, 0))
	t.start_hand(K.SLEEVE)
	var events := t.accuse(Accusation.make(A.DEALER_HAND))
	assert_has(_types(events), &"accusation_right")
	assert_true(t.truco_match.hand.is_over())
	assert_eq(t.truco_match.scores, [1, 0])
	assert_gt(t.brain.mood.tilt, 0.0)


func test_acusar_al_complice_gana_la_mano() -> void:
	var t := H.table(H.profile(0.0, 0))
	t.start_hand(K.ACCOMPLICE)
	assert_has(_types(t.accuse(Accusation.make(A.ACCOMPLICE))), &"accusation_right")
	assert_eq(t.truco_match.scores[0], 1)


func test_acusar_la_duplicada_jugada_gana_la_mano() -> void:
	var t := H.table(H.profile(0.0, 0))
	var cards := [H.cards([[H.E, 1], [H.C, 4], [H.O, 5]]), H.cards([[H.B, 4], [H.B, 5], [H.B, 6]])]
	t.start_hand(K.DUPLICATE, cards, 0)
	H.advance(t, func() -> bool: return t.evidence().size() > 0)
	assert_false(t.truco_match.hand.is_over(), "la mano sigue cuando aparece la evidencia")
	var events := t.accuse(Accusation.make(A.HISTORY_CARD, "1_ESPADA"))
	assert_has(_types(events), &"accusation_right")


func test_acusar_sin_trampa_paga_tres() -> void:
	var t := H.table(H.profile(0.0, 0))
	t.start_hand(-1)
	var events := t.accuse(Accusation.make(A.DEALER_HAND))
	assert_has(_types(events), &"accusation_wrong")
	assert_eq(t.truco_match.scores, [0, CheatTable.WRONG_ACCUSATION_POINTS])
	assert_false(t.truco_match.hand.is_over())
	assert_gt(t.brain.mood.suspicion, 0.0)


func test_acusar_la_carta_equivocada_paga_tres() -> void:
	var t := H.table(H.profile(0.0, 0))
	t.start_hand(K.SLEEVE)
	assert_has(_types(t.accuse(Accusation.make(A.ACCOMPLICE))), &"accusation_wrong")


func test_segunda_acusacion_es_ilegal() -> void:
	var t := H.table(H.profile(0.0, 0))
	t.start_hand(-1)
	t.accuse(Accusation.make(A.DEALER_HAND))
	var events := t.accuse(Accusation.make(A.DEALER_HAND))
	assert_eq(events[0].type, &"illegal_action")
	assert_eq(t.truco_match.scores, [0, CheatTable.WRONG_ACCUSATION_POINTS])


func test_acusar_con_la_mano_terminada_es_ilegal() -> void:
	var t := H.table(H.profile(0.0, 0))
	t.start_hand(K.SLEEVE)
	if t.is_dealer_turn():
		t.dealer_step()
	t.player_action(TrucoAction.make(H.T.MAZO, 0))
	if not t.truco_match.hand.is_over():
		H.advance(t, func() -> bool: return false)
	var before := t.truco_match.scores.duplicate()
	assert_eq(t.accuse(Accusation.make(A.DEALER_HAND))[0].type, &"illegal_action")
	assert_eq(t.truco_match.scores, before)


func test_acusar_durante_la_declaracion() -> void:
	var t := H.table(H.profile(0.0, 0))
	var cards := [H.cards([[H.E, 4], [H.B, 5], [H.C, 6]]), H.cards([[H.O, 7], [H.O, 6], [H.C, 4]])]
	t.start_hand(K.SLEEVE, cards, 0)
	t.player_action(TrucoAction.make(H.T.ENVIDO, 0))
	H.advance(t, func() -> bool: return t.truco_match.hand.phase == TrucoHand.Phase.TANTO_DECLARATION)
	assert_eq(t.truco_match.hand.phase, TrucoHand.Phase.TANTO_DECLARATION)
	assert_has(_types(t.accuse(Accusation.make(A.DEALER_HAND))), &"accusation_right")
	assert_true(t.truco_match.hand.is_over())
