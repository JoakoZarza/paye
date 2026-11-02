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
	# Se va el que perdió el envido: el ganador todavía tiene que mostrar.
	_do(h, T.PLAY_CARD, 0, 0)
	_do(h, T.MAZO, 1)
	assert_eq(h.phase, TrucoHand.Phase.SHOW_DECISION)
	assert_eq(h.current_player(), 1)
	_do(h, T.DEMAND_SHOW, 1)
	assert_true(h.is_over())
	assert_eq(h.envido_points, [0, 2 + TrucoHand.LIE_PENALTY])
	assert_eq(h.truco_points, [1, 0])


func test_pedir_mostrar_y_era_verdad() -> void:
	var h := _hand([[O, 7], [O, 6], [C, 4]], [[E, 5], [E, 10], [B, 4]], 0)
	_do(h, T.ENVIDO, 0)
	_do(h, T.QUIERO, 1)
	_do(h, T.DECLARE_TANTO, 0, -1, 33)
	_do(h, T.SON_BUENAS, 1)
	# Se va el que perdió el envido: el ganador todavía tiene que mostrar.
	_do(h, T.PLAY_CARD, 0, 0)
	_do(h, T.MAZO, 1)
	_do(h, T.DEMAND_SHOW, 1)
	assert_eq(h.envido_points, [2 + TrucoHand.WRONG_SHOW_PENALTY, 0])


func test_aceptar_tanto_sin_pedir() -> void:
	var h := _hand([[O, 12], [O, 11], [C, 4]], [[E, 5], [E, 10], [B, 4]], 0)
	_do(h, T.ENVIDO, 0)
	_do(h, T.QUIERO, 1)
	_do(h, T.DECLARE_TANTO, 0, -1, 33)
	_do(h, T.SON_BUENAS, 1)
	# Se va el que perdió el envido: el ganador todavía tiene que mostrar.
	_do(h, T.PLAY_CARD, 0, 0)
	_do(h, T.MAZO, 1)
	_do(h, T.ACCEPT_TANTO, 1)
	assert_eq(h.envido_points, [2, 0])


func test_empate_de_tanto_gana_el_mano() -> void:
	# Los dos tienen 25 reales; el jugador 1 declara 26 y el mano pide mostrar.
	var h := _hand([[E, 5], [E, 10], [C, 4]], [[O, 5], [O, 10], [B, 4]], 0)
	_do(h, T.ENVIDO, 0)
	_do(h, T.QUIERO, 1)
	_do(h, T.DECLARE_TANTO, 0, -1, 25)
	_do(h, T.DECLARE_TANTO, 1, -1, 26)
	# Se va el que perdió el envido: el ganador todavía tiene que mostrar.
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


func test_envido_ilegal_respondiendo_retruco() -> void:
	var h := _hand([[O, 7], [O, 6], [C, 4]], [[E, 4], [E, 5], [B, 6]], 0)
	_do(h, T.TRUCO, 0)
	_do(h, T.RETRUCO, 1)
	assert_eq(h.current_player(), 0)
	assert_false(_has(h, T.ENVIDO))


func test_lectores_publicos() -> void:
	var h := _hand([[O, 7], [O, 6], [C, 4]], [[E, 4], [E, 5], [B, 6]], 0)
	_do(h, T.TRUCO, 0)
	_do(h, T.ENVIDO, 1)
	_do(h, T.QUIERO, 0)
	_do(h, T.DECLARE_TANTO, 0, -1, 33)
	_do(h, T.SON_BUENAS, 1)
	assert_eq(h.declared_tanto(0), 33)
	assert_eq(h.declared_tanto(1), -1)
	assert_eq(h.truco_level(), 1)
	assert_true(h.truco_pending())
	assert_true(h.envido_called())
	assert_eq(h.envido_winner(), 0)
	assert_eq(h.own_tanto(0), 33)


func test_force_end_paga_el_truco_y_quita_el_envido() -> void:
	var h := _hand([[E, 1], [B, 1], [C, 4]], [[E, 4], [E, 5], [E, 6]], 1)
	_do(h, T.ENVIDO, 1)
	_do(h, T.NO_QUIERO, 0)
	_do(h, T.TRUCO, 1)
	_do(h, T.QUIERO, 0)
	assert_eq(h.envido_points, [0, 1])
	h.force_end(0, 1)
	assert_true(h.is_over())
	assert_eq(h.truco_points, [2, 0])
	assert_eq(h.envido_points, [0, 0])


func test_force_end_con_truco_pendiente_paga_lo_asegurado() -> void:
	var h := _hand([[E, 1], [B, 1], [C, 4]], [[E, 4], [E, 5], [E, 6]], 0)
	_do(h, T.TRUCO, 0)
	h.force_end(1, 0)
	assert_eq(h.truco_points, [0, 1])


func test_force_end_durante_declaracion() -> void:
	var h := _hand([[O, 7], [O, 6], [C, 4]], [[E, 4], [E, 5], [B, 6]], 0)
	_do(h, T.ENVIDO, 0)
	_do(h, T.QUIERO, 1)
	var events := h.force_end(0, 1)
	assert_eq(h.phase, TrucoHand.Phase.OVER)
	assert_eq(events.back().type, &"hand_over")
	assert_eq(h.envido_points, [0, 0])


func test_force_end_da_el_envido_al_acusador_si_lo_ganaba() -> void:
	var h := _hand([[O, 7], [O, 6], [C, 4]], [[E, 4], [E, 5], [B, 6]], 0)
	_do(h, T.ENVIDO, 0)
	_do(h, T.QUIERO, 1)
	_do(h, T.DECLARE_TANTO, 0, -1, 33)
	_do(h, T.SON_BUENAS, 1)
	h.force_end(0, 1)
	assert_eq(h.envido_points, [2, 0])


func test_force_end_en_mano_terminada_es_ilegal() -> void:
	var h := _hand([[E, 1], [B, 1], [C, 4]], [[E, 4], [E, 5], [E, 6]], 0)
	_do(h, T.MAZO, 0)
	var events := h.force_end(0, 1)
	assert_eq(events[0].type, &"illegal_action")
	assert_eq(h.truco_points, [0, 1])


func test_agregar_y_reemplazar_cartas() -> void:
	var h := _hand([[E, 1], [B, 1], [C, 4]], [[E, 4], [E, 5], [E, 6]], 0)
	h.add_card(1, Card.new(O, 7))
	assert_eq(h.total_cards(1), 4)
	h.replace_card(1, 0, Card.new(C, 3))
	assert_eq(h.cards[1][0].key(), "3_COPA")


func test_force_end_no_paga_un_envido_mentido_al_acusador() -> void:
	var h := _hand([[O, 12], [O, 11], [C, 4]], [[E, 5], [E, 10], [B, 4]], 0)
	_do(h, T.ENVIDO, 0)
	_do(h, T.QUIERO, 1)
	_do(h, T.DECLARE_TANTO, 0, -1, 33)
	_do(h, T.SON_BUENAS, 1)
	h.force_end(0, 1)
	assert_eq(h.envido_points, [0, 0])


func test_rosario_anula_truco() -> void:
	var h := _hand([[E, 1], [B, 1], [C, 4]], [[E, 4], [E, 5], [E, 6]], 1)
	_do(h, T.TRUCO, 1)
	assert_true(h.undo_last_call(0))
	assert_eq(h.phase, TrucoHand.Phase.PLAYING)
	assert_eq(h.truco_level(), 0)
	assert_false(h.truco_pending())
	assert_eq(h.current_player(), 1)


func test_rosario_anula_la_subida_de_envido() -> void:
	var h := _hand([[O, 7], [O, 6], [C, 4]], [[E, 4], [E, 5], [B, 6]], 0)
	_do(h, T.ENVIDO, 0)
	_do(h, T.REAL_ENVIDO, 1)
	assert_true(h.undo_last_call(0))
	assert_eq(h.phase, TrucoHand.Phase.ENVIDO_RESPONSE)
	assert_eq(h.current_player(), 1)
	_do(h, T.NO_QUIERO, 1)
	assert_eq(h.envido_points, [1, 0])


func test_rosario_anula_retruco_y_vuelve_al_truco_pendiente() -> void:
	var h := _hand([[E, 1], [B, 1], [C, 4]], [[E, 4], [E, 5], [E, 6]], 0)
	_do(h, T.TRUCO, 0)
	_do(h, T.RETRUCO, 1)
	assert_true(h.undo_last_call(0))
	assert_eq(h.truco_level(), 1)
	assert_true(h.truco_pending())
	assert_eq(h.current_player(), 1)


func test_rosario_sin_canto_pendiente_no_hace_nada() -> void:
	var h := _hand([[E, 1], [B, 1], [C, 4]], [[E, 4], [E, 5], [E, 6]], 1)
	_do(h, T.TRUCO, 1)
	_do(h, T.QUIERO, 0)
	assert_false(h.undo_last_call(0))
	assert_eq(h.truco_level(), 1)


func test_rosario_no_anula_un_canto_propio() -> void:
	var h := _hand([[E, 1], [B, 1], [C, 4]], [[E, 4], [E, 5], [E, 6]], 0)
	_do(h, T.TRUCO, 0)
	assert_false(h.undo_last_call(0))
	assert_true(h.truco_pending())


func test_marcar_no_duplica_una_carta() -> void:
	var h := _hand([[O, 7], [O, 6], [C, 4]], [[E, 4], [E, 5], [B, 6]], 0)
	assert_false(h.can_mark(0, 1, 7))
	assert_true(h.can_mark(0, 1, 5))
	assert_false(h.can_mark(0, 1, 8))
	assert_false(h.can_mark(0, 5, 5))


func test_rosario_no_anula_truco_despues_de_un_envido_resuelto() -> void:
	var h := _hand([[O, 7], [O, 6], [C, 4]], [[E, 4], [E, 5], [B, 6]], 1)
	_do(h, T.TRUCO, 1)
	_do(h, T.ENVIDO, 0)
	_do(h, T.NO_QUIERO, 1)
	assert_eq(h.phase, TrucoHand.Phase.TRUCO_RESPONSE)
	assert_false(h.can_undo_last_call(0))
	assert_false(h.undo_last_call(0))


func test_marcar_no_duplica_una_carta_ya_jugada() -> void:
	var h := _hand([[O, 7], [O, 6], [C, 4]], [[E, 4], [E, 5], [B, 6]], 0)
	_do(h, T.PLAY_CARD, 0, 0)
	assert_false(h.can_mark(0, 0, 7), "el 7 de oro ya se jugó")


func test_declaracion_es_mentira_sigue_la_regla_de_mostrar() -> void:
	var h := _hand([[O, 12], [O, 11], [C, 4]], [[E, 5], [E, 10], [B, 4]], 0)
	_do(h, T.ENVIDO, 0)
	_do(h, T.QUIERO, 1)
	_do(h, T.DECLARE_TANTO, 0, -1, 33)
	_do(h, T.SON_BUENAS, 1)
	assert_true(h.declaration_is_lie(0))
	var h2 := _hand([[O, 7], [O, 5], [C, 4]], [[E, 5], [E, 10], [B, 4]], 0)
	_do(h2, T.ENVIDO, 0)
	_do(h2, T.QUIERO, 1)
	_do(h2, T.DECLARE_TANTO, 0, -1, 33)
	_do(h2, T.SON_BUENAS, 1)
	assert_false(h2.declaration_is_lie(0), "declaró de más pero igual gana: no es mentira que se castigue")


func test_rosario_prohibe_repetir_el_canto_anulado() -> void:
	var h := _hand([[E, 1], [B, 1], [C, 4]], [[E, 4], [E, 5], [E, 6]], 1)
	_do(h, T.TRUCO, 1)
	h.undo_last_call(0)
	assert_false(_has(h, T.TRUCO), "el dealer no puede volver a cantar truco en esta mano")
	_do(h, T.PLAY_CARD, 1, 0)
	assert_true(_has(h, T.TRUCO), "el jugador sí puede cantar truco")


func test_irse_al_mazo_con_el_envido_ganado_lo_pierde() -> void:
	var h := TrucoHand.new([_cards([[Card.Suit.ORO, 7], [Card.Suit.ORO, 6], [Card.Suit.COPA, 4]]),
		_cards([[Card.Suit.ESPADA, 4], [Card.Suit.BASTO, 5], [Card.Suit.COPA, 6]])], 0, 15)
	h.apply(TrucoAction.make(TrucoAction.Type.ENVIDO, 0))
	h.apply(TrucoAction.make(TrucoAction.Type.QUIERO, 1))
	h.apply(TrucoAction.make(TrucoAction.Type.DECLARE_TANTO, 0, -1, 33))
	h.apply(TrucoAction.make(TrucoAction.Type.SON_BUENAS, 1))
	var events := h.apply(TrucoAction.make(TrucoAction.Type.MAZO, 0))
	assert_true(events.any(func(e: GameEvent) -> bool: return e.type == &"envido_forfeit"))
	assert_true(h.is_over(), "sin mostrar no hay verificación")
	assert_eq(h.envido_points, [0, 2] as Array[int])
	assert_eq(h.truco_points, [0, 1] as Array[int])

func _envido_won_by_0(declared: int) -> TrucoHand:
	var h := TrucoHand.new([_cards([[Card.Suit.ORO, 7], [Card.Suit.ORO, 6], [Card.Suit.COPA, 4]]),
		_cards([[Card.Suit.ESPADA, 4], [Card.Suit.BASTO, 5], [Card.Suit.COPA, 6]])], 0, 15)
	h.apply(TrucoAction.make(TrucoAction.Type.ENVIDO, 0))
	h.apply(TrucoAction.make(TrucoAction.Type.QUIERO, 1))
	h.apply(TrucoAction.make(TrucoAction.Type.DECLARE_TANTO, 0, -1, declared))
	h.apply(TrucoAction.make(TrucoAction.Type.SON_BUENAS, 1))
	return h


func test_mostrar_el_tanto_y_despues_irse_al_mazo_lo_conserva() -> void:
	var h := _envido_won_by_0(33)
	assert_true(_has(h, T.SHOW_TANTO))
	var events := h.apply(TrucoAction.make(T.SHOW_TANTO, 0))
	assert_true(events.any(func(e: GameEvent) -> bool: return e.type == &"tanto_shown"))
	assert_false(_has(h, T.SHOW_TANTO), "se muestra una sola vez")
	events = h.apply(TrucoAction.make(T.MAZO, 0))
	assert_false(events.any(func(e: GameEvent) -> bool: return e.type == &"envido_forfeit"))
	assert_true(h.is_over(), "ya mostró: no hay que pedir que muestre")
	assert_eq(h.envido_points, [2, 0] as Array[int])
	assert_eq(h.truco_points, [0, 1] as Array[int])


func test_mostrar_un_tanto_mentido_lo_delata() -> void:
	# Tiene 3 de tanto y declara 33; el rival, con 32, se calló.
	var h := TrucoHand.new([_cards([[Card.Suit.ORO, 1], [Card.Suit.COPA, 2], [Card.Suit.BASTO, 3]]),
		_cards([[Card.Suit.ESPADA, 7], [Card.Suit.ESPADA, 5], [Card.Suit.COPA, 6]])], 0, 15)
	h.apply(TrucoAction.make(T.ENVIDO, 0))
	h.apply(TrucoAction.make(T.QUIERO, 1))
	h.apply(TrucoAction.make(T.DECLARE_TANTO, 0, -1, 33))
	h.apply(TrucoAction.make(T.SON_BUENAS, 1))
	var events := h.apply(TrucoAction.make(T.SHOW_TANTO, 0))
	assert_true(events.any(func(e: GameEvent) -> bool: return e.type == &"lie_caught"))
	assert_eq(h.envido_points, [0, 2 + TrucoHand.LIE_PENALTY] as Array[int])


func test_solo_el_ganador_del_envido_puede_mostrar() -> void:
	var h := _envido_won_by_0(33)
	h.apply(TrucoAction.make(T.PLAY_CARD, 0, 0))
	assert_false(_has(h, T.SHOW_TANTO), "el rival no ganó el envido")
