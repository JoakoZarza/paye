extends GutTest

const E := Card.Suit.ESPADA
const B := Card.Suit.BASTO
const O := Card.Suit.ORO
const C := Card.Suit.COPA
const T := TrucoAction.Type


func _cards(spec: Array) -> Array[Card]:
	var out: Array[Card] = []
	for pair in spec:
		out.append(Card.new(pair[0], pair[1]))
	return out


func _match(target: int, s: int) -> TrucoMatch:
	var rng := RandomNumberGenerator.new()
	rng.seed = s
	return TrucoMatch.new(target, rng)


func _do(m: TrucoMatch, type: T, player: int, value := -1) -> Array[GameEvent]:
	var events := m.apply(TrucoAction.make(type, player, -1, value))
	for e in events:
		assert_ne(e.type, &"illegal_action", "acción ilegal: %s del jugador %d" % [T.keys()[type], player])
	return events


func _types(events: Array[GameEvent]) -> Array[StringName]:
	var out: Array[StringName] = []
	for e in events:
		out.append(e.type)
	return out


## Jugador 0 tiene 33 de tanto; jugador 1 tiene 20.
func _hand_0_has_33() -> Array:
	return [_cards([[O, 7], [O, 6], [C, 4]]), _cards([[E, 12], [E, 11], [B, 4]])]


func test_primer_mano_sorteado_con_semilla() -> void:
	var a := _match(15, 77)
	var b := _match(15, 77)
	a.start_hand()
	b.start_hand()
	assert_eq(a.mano, b.mano)


func test_mano_alterna() -> void:
	var m := _match(15, 5)
	m.start_hand()
	var first := m.mano
	_do(m, T.MAZO, m.hand.current_player())
	m.start_hand()
	assert_eq(m.mano, 1 - first)


func test_reparte_tres_y_tres() -> void:
	var m := _match(15, 9)
	m.start_hand()
	assert_eq(m.hand.cards[0].size(), 3)
	assert_eq(m.hand.cards[1].size(), 3)


func test_falta_envido_a_cero_gana_el_partido() -> void:
	var m := _match(15, 1)
	m.start_hand_with([_cards([[E, 12], [E, 11], [B, 4]]), _cards([[O, 7], [O, 6], [C, 4]])], 0)
	assert_eq(m.falta_points(), 15)
	_do(m, T.FALTA_ENVIDO, 0)
	_do(m, T.QUIERO, 1)
	_do(m, T.DECLARE_TANTO, 0, 20)
	_do(m, T.DECLARE_TANTO, 1, 33)
	_do(m, T.MAZO, 0)
	var events := _do(m, T.ACCEPT_TANTO, 0)
	assert_eq(m.winner(), 1)
	assert_eq(m.scores, [0, 15])
	assert_has(_types(events), &"match_over")


func test_envido_suma_antes_que_truco() -> void:
	var m := _match(15, 1)
	m.scores = [13, 13]
	m.start_hand_with(_hand_0_has_33(), 0)
	_do(m, T.ENVIDO, 0)
	_do(m, T.QUIERO, 1)
	_do(m, T.DECLARE_TANTO, 0, 33)
	_do(m, T.SON_BUENAS, 1)
	_do(m, T.MAZO, 0)
	_do(m, T.ACCEPT_TANTO, 1)
	assert_eq(m.winner(), 0)
	assert_eq(m.scores, [15, 13])


func test_puntaje_no_supera_al_terminar() -> void:
	var m := _match(15, 1)
	m.scores = [14, 0]
	m.start_hand_with(_hand_0_has_33(), 0)
	_do(m, T.ENVIDO, 0)
	_do(m, T.QUIERO, 1)
	_do(m, T.DECLARE_TANTO, 0, 33)
	_do(m, T.SON_BUENAS, 1)
	_do(m, T.MAZO, 0)
	_do(m, T.ACCEPT_TANTO, 1)
	assert_eq(m.scores, [15, 0])


func test_partido_sigue_si_nadie_llega() -> void:
	var m := _match(30, 3)
	m.start_hand()
	_do(m, T.MAZO, m.hand.current_player())
	assert_eq(m.winner(), -1)


func test_accion_despues_de_terminar_la_mano_no_suma_de_nuevo() -> void:
	var m := _match(15, 1)
	m.start_hand_with(_hand_0_has_33(), 0)
	_do(m, T.MAZO, 0)
	assert_eq(m.scores, [0, 1])
	var events := m.apply(TrucoAction.make(T.MAZO, 0))
	assert_eq(events[0].type, &"illegal_action")
	assert_eq(m.scores, [0, 1])


func test_award_suma_con_tope_y_termina() -> void:
	var m := _match(15, 1)
	m.scores = [13, 0]
	m.start_hand()
	var events := m.award(0, 3)
	assert_eq(m.scores, [15, 0])
	assert_has(_types(events), &"match_over")


func test_finish_forced_hand_suma_la_mano_forzada() -> void:
	var m := _match(15, 1)
	m.start_hand_with(_hand_0_has_33(), 0)
	m.hand.force_end(1, 0)
	m.finish_forced_hand()
	assert_eq(m.scores, [0, 1])


func test_el_mazo_queda_accesible() -> void:
	var m := _match(15, 1)
	m.start_hand()
	assert_eq(m.deck.remaining(), 34)
