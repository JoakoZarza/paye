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


func _hand(c0: Array, c1: Array, mano: int, falta := 15) -> TrucoHand:
	return TrucoHand.new([_cards(c0), _cards(c1)], mano, falta)


func _do(h: TrucoHand, type: T, player: int, idx := -1, value := -1) -> Array[GameEvent]:
	var events := h.apply(TrucoAction.make(type, player, idx, value))
	for e in events:
		assert_ne(e.type, &"illegal_action", "acción ilegal: %s del jugador %d" % [T.keys()[type], player])
	return events


func _has(h: TrucoHand, type: T) -> bool:
	for a in h.legal_actions():
		if a.type == type:
			return true
	return false


func test_mano_simple_gana_quien_gana_dos_bazas() -> void:
	var h := _hand([[E, 1], [B, 1], [C, 4]], [[E, 4], [E, 5], [E, 6]], 0)
	_do(h, T.PLAY_CARD, 0, 0)
	_do(h, T.PLAY_CARD, 1, 0)
	_do(h, T.PLAY_CARD, 0, 0)
	_do(h, T.PLAY_CARD, 1, 0)
	assert_true(h.is_over())
	assert_eq(h.truco_points, [1, 0])


func test_truco_querido_vale_2() -> void:
	var h := _hand([[E, 1], [B, 1], [C, 4]], [[E, 4], [E, 5], [E, 6]], 0)
	_do(h, T.TRUCO, 0)
	_do(h, T.QUIERO, 1)
	for i in 2:
		_do(h, T.PLAY_CARD, 0, 0)
		_do(h, T.PLAY_CARD, 1, 0)
	assert_true(h.is_over())
	assert_eq(h.truco_points, [2, 0])


func test_truco_no_querido_vale_1_y_termina() -> void:
	var h := _hand([[E, 1], [B, 1], [C, 4]], [[E, 4], [E, 5], [E, 6]], 0)
	_do(h, T.TRUCO, 0)
	_do(h, T.NO_QUIERO, 1)
	assert_true(h.is_over())
	assert_eq(h.truco_points, [1, 0])


func test_mazo_con_truco_pendiente_paga_no_querido() -> void:
	var h := _hand([[E, 1], [B, 1], [C, 4]], [[E, 4], [E, 5], [E, 6]], 1)
	_do(h, T.TRUCO, 1)
	_do(h, T.RETRUCO, 0)
	_do(h, T.MAZO, 1)
	assert_true(h.is_over())
	assert_eq(h.truco_points, [2, 0])


func test_envido_ilegal_despues_de_jugar_carta() -> void:
	var h := _hand([[E, 1], [B, 1], [C, 4]], [[E, 4], [E, 5], [E, 6]], 0)
	_do(h, T.PLAY_CARD, 0, 2)
	_do(h, T.TRUCO, 1)
	assert_eq(h.current_player(), 0)
	assert_false(_has(h, T.ENVIDO))
	assert_false(_has(h, T.REAL_ENVIDO))
	assert_false(_has(h, T.FALTA_ENVIDO))


func test_envido_responde_a_truco_en_primera() -> void:
	var h := _hand([[O, 7], [O, 6], [C, 4]], [[E, 4], [E, 5], [B, 6]], 0)
	_do(h, T.TRUCO, 0)
	assert_true(_has(h, T.ENVIDO))
	_do(h, T.ENVIDO, 1)
	_do(h, T.QUIERO, 0)
	_do(h, T.DECLARE_TANTO, 0, -1, 33)
	_do(h, T.SON_BUENAS, 1)
	assert_eq(h.phase, TrucoHand.Phase.TRUCO_RESPONSE)
	assert_eq(h.current_player(), 1)


func test_tanto_fuera_de_rango_es_ilegal() -> void:
	var h := _hand([[O, 7], [O, 6], [C, 4]], [[E, 4], [E, 5], [B, 6]], 0)
	_do(h, T.ENVIDO, 0)
	_do(h, T.QUIERO, 1)
	var events := h.apply(TrucoAction.make(T.DECLARE_TANTO, 0, -1, 34))
	assert_eq(events.size(), 1)
	assert_eq(events[0].type, &"illegal_action")


func test_mentira_pescada() -> void:
	# Jugador 0 (mano) tiene 20 reales y declara 33. Jugador 1 tiene 25.
	var h := _hand([[O, 12], [O, 11], [C, 4]], [[E, 5], [E, 10], [B, 4]], 0)
	_do(h, T.ENVIDO, 0)
	_do(h, T.QUIERO, 1)
	_do(h, T.DECLARE_TANTO, 0, -1, 33)
	_do(h, T.SON_BUENAS, 1)
	_do(h, T.MAZO, 0)
	assert_eq(h.phase, TrucoHand.Phase.SHOW_DECISION)
	assert_eq(h.current_player(), 1)
	_do(h, T.DEMAND_SHOW, 1)
	assert_true(h.is_over())
	assert_eq(h.envido_points, [0, 2 + TrucoHand.LIE_PENALTY])
	assert_eq(h.truco_points, [0, 1])


func test_pedir_mostrar_y_era_verdad() -> void:
	var h := _hand([[O, 7], [O, 6], [C, 4]], [[E, 5], [E, 10], [B, 4]], 0)
	_do(h, T.ENVIDO, 0)
	_do(h, T.QUIERO, 1)
	_do(h, T.DECLARE_TANTO, 0, -1, 33)
	_do(h, T.SON_BUENAS, 1)
	_do(h, T.MAZO, 0)
	_do(h, T.DEMAND_SHOW, 1)
	assert_eq(h.envido_points, [2 + TrucoHand.WRONG_SHOW_PENALTY, 0])


func test_aceptar_tanto_sin_pedir() -> void:
	var h := _hand([[O, 12], [O, 11], [C, 4]], [[E, 5], [E, 10], [B, 4]], 0)
	_do(h, T.ENVIDO, 0)
	_do(h, T.QUIERO, 1)
	_do(h, T.DECLARE_TANTO, 0, -1, 33)
	_do(h, T.SON_BUENAS, 1)
	_do(h, T.MAZO, 0)
	_do(h, T.ACCEPT_TANTO, 1)
	assert_eq(h.envido_points, [2, 0])


func test_empate_de_tanto_gana_el_mano() -> void:
	# Los dos tienen 25 reales; el jugador 1 declara 26 y el mano pide mostrar.
	var h := _hand([[E, 5], [E, 10], [C, 4]], [[O, 5], [O, 10], [B, 4]], 0)
	_do(h, T.ENVIDO, 0)
	_do(h, T.QUIERO, 1)
	_do(h, T.DECLARE_TANTO, 0, -1, 25)
	_do(h, T.DECLARE_TANTO, 1, -1, 26)
	_do(h, T.MAZO, 0)
	assert_eq(h.current_player(), 0)
	_do(h, T.DEMAND_SHOW, 0)
	assert_eq(h.envido_points, [2 + TrucoHand.LIE_PENALTY, 0])


func test_envido_no_querido() -> void:
	var h := _hand([[O, 7], [O, 6], [C, 4]], [[E, 4], [E, 5], [B, 6]], 0)
	_do(h, T.ENVIDO, 0)
	_do(h, T.REAL_ENVIDO, 1)
	_do(h, T.NO_QUIERO, 0)
	assert_eq(h.envido_points, [0, 2])
	assert_eq(h.phase, TrucoHand.Phase.PLAYING)
	assert_eq(h.current_player(), 0)
