extends GutTest

const H := preload("res://tests/cheats/cheat_test_helpers.gd")


## El jugador (mano, 20 reales) canta envido y declara 33; el dealer tiene 25.
## Si se llega a que el dealer decida si pide mostrar, devuelve true si lo pidió.
## Devuelve null si la mano no llegó a esa decisión.
func _show_flow(t: CheatTable) -> Variant:
	var cards := [H.cards([[H.O, 12], [H.O, 11], [H.C, 4]]), H.cards([[H.E, 5], [H.E, 10], [H.B, 4]])]
	t.start_hand(-1, cards, 0)
	t.player_action(TrucoAction.make(H.T.ENVIDO, 0))
	H.advance(t, func() -> bool: return t.truco_match.hand.phase == TrucoHand.Phase.TANTO_DECLARATION)
	if t.truco_match.hand.phase != TrucoHand.Phase.TANTO_DECLARATION:
		return null
	t.player_action(TrucoAction.make(H.T.DECLARE_TANTO, 0, -1, 33))
	H.advance(t, func() -> bool: return t.truco_match.hand.phase == TrucoHand.Phase.PLAYING)
	if t.truco_match.hand.envido_winner() != 0 or t.truco_match.hand.is_over():
		return null
		# Se juega la mano hasta que el dealer decide si pide mostrar.
	H.advance(t, func() -> bool: return t.truco_match.hand.phase == TrucoHand.Phase.SHOW_DECISION)
	if t.truco_match.hand.phase != TrucoHand.Phase.SHOW_DECISION:
		return null
	var events := t.dealer_step()
	return events.any(func(e: GameEvent) -> bool: return e.type == &"show_demanded")


func _demand_rate(cigarette: bool, skip: bool) -> float:
	var reached := 0
	var demanded := 0
	for s in 400:
		var t := H.table(H.profile(0.0, 0, 0.9), s)
		t.rules.cigarette = cigarette
		t.rules.skip_next_show = skip
		var r: Variant = _show_flow(t)
		if r == null:
			continue
		reached += 1
		if r:
			demanded += 1
	assert_gt(reached, 50, "la decisión de mostrar tiene que alcanzarse seguido")
	return float(demanded) / maxi(reached, 1)


func test_facon_obliga_a_querer() -> void:
	for s in 50:
		var t := H.table(H.profile(0.0, 0, 0.0), s)
		t.start_hand(-1, [H.cards([[H.E, 1], [H.B, 1], [H.E, 7]]), H.cards([[H.C, 4], [H.O, 5], [H.B, 6]])], 0)
		t.rules.force_accept_next_call = true
		t.player_action(TrucoAction.make(H.T.TRUCO, 0))
		var events := t.dealer_step()
		assert_eq(events[0].type, &"call_accepted")
		assert_false(t.rules.force_accept_next_call)


func test_sin_facon_el_dealer_debil_no_quiere_siempre() -> void:
	var refused := 0
	for s in 50:
		var t := H.table(H.profile(0.0, 0, 0.0), s)
		t.start_hand(-1, [H.cards([[H.E, 1], [H.B, 1], [H.E, 7]]), H.cards([[H.C, 4], [H.O, 5], [H.B, 6]])], 0)
		t.player_action(TrucoAction.make(H.T.TRUCO, 0))
		if t.dealer_step()[0].type != &"call_accepted":
			refused += 1
	assert_gt(refused, 0)


func test_vaso_anula_el_pedido_de_mostrar() -> void:
	assert_gt(_demand_rate(false, false), 0.0)
	assert_eq(_demand_rate(false, true), 0.0)


func test_cigarrillo_reduce_los_pedidos() -> void:
	assert_lt(_demand_rate(true, false), _demand_rate(false, false))


func test_viuda_duplica_el_presupuesto() -> void:
	var t := H.table(H.profile(1.0, 3))
	t.rules.dealer_budget_multiplier = 2
	t.start_match()
	assert_eq(t.brain.cheat_budget, 6)


func test_registra_si_el_jugador_canto_envido() -> void:
	var t := H.table(H.profile(0.0, 0))
	t.start_hand(-1, [H.cards([[H.O, 7], [H.O, 6], [H.C, 4]]), H.cards([[H.E, 5], [H.E, 10], [H.B, 4]])], 0)
	assert_false(t.player_called_envido)
	t.player_action(TrucoAction.make(H.T.ENVIDO, 0))
	assert_true(t.player_called_envido)
	t.start_match()
	assert_false(t.player_called_envido)
