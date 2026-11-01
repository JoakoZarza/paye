extends GutTest

const H := preload("res://tests/cheats/cheat_test_helpers.gd")
const K := Cheat.Kind


## Mano para la duplicada: el jugador abre con el ancho de espada; el dealer
## termina jugando la copia en la tercera baza, con la mano todavía en curso.
func _duplicate_cards() -> Array:
	return [H.cards([[H.E, 1], [H.C, 4], [H.O, 5]]), H.cards([[H.B, 4], [H.B, 5], [H.B, 6]])]


func test_manga_deja_cuatro_cartas_y_evidencia() -> void:
	var t := H.table(H.profile(0.0, 0))
	t.start_hand(K.SLEEVE)
	assert_eq(t.truco_match.hand.total_cards(1), 4)
	assert_eq(t.evidence().size(), 1)
	assert_eq(t.evidence()[0].kind, K.SLEEVE)


func test_manga_sin_mazo_no_esta_disponible() -> void:
	var t := H.table(H.profile(0.0, 0))
	t.start_hand(-1)
	t.truco_match.deck.draw(40)
	assert_false(K.SLEEVE in t.available_cheats())


func test_complice_da_cartas_y_evidencia() -> void:
	var t := H.table(H.profile(0.0, 0))
	var events := t.start_hand(K.ACCOMPLICE)
	assert_eq(t.dealer_known_cards().size(), 3)
	assert_eq(t.evidence().size(), 1)
	var types := events.map(func(e: GameEvent) -> StringName: return e.type)
	assert_has(types, &"cheat_tell")


func test_sin_complice_el_dealer_no_conoce_nada() -> void:
	var t := H.table(H.profile(0.0, 0))
	t.start_hand(-1)
	assert_eq(t.dealer_known_cards().size(), 0)


func test_duplicada_aparece_al_jugarse() -> void:
	var t := H.table(H.profile(0.0, 0))
	t.start_hand(K.DUPLICATE, _duplicate_cards(), 0)
	var copy_played := func() -> bool:
		var keys: Array = t.truco_match.hand.played[1].map(func(c: Card) -> String: return c.key())
		return "1_ESPADA" in keys
	H.advance(t, func() -> bool:
		if not copy_played.call():
			assert_eq(t.evidence().size(), 0, "sin evidencia antes de jugar la copia")
		return copy_played.call())
	assert_true(copy_played.call(), "el dealer tiene que jugar la copia")
	assert_eq(t.evidence().size(), 1)
	assert_eq(t.evidence()[0].card_key, "1_ESPADA")


func test_duplicada_no_jugada_no_es_evidencia() -> void:
	var t := H.table(H.profile(0.0, 0))
	t.start_hand(K.DUPLICATE, _duplicate_cards(), 0)
	t.player_action(TrucoAction.make(H.T.MAZO, 0))
	assert_eq(t.evidence().size(), 0)


func test_presupuesto_cero_mano_limpia() -> void:
	var t := H.table(H.profile(1.0, 0))
	for i in 200:
		if t.truco_match.winner() != -1:
			t = H.table(H.profile(1.0, 0), i)
		t.start_hand()
		assert_null(t.active_cheat)
		H.advance(t, func() -> bool: return false)


func test_dealer_step_fuera_de_turno_es_ilegal() -> void:
	var t := H.table(H.profile(0.0, 0))
	t.start_hand(-1, _duplicate_cards(), 0)
	assert_eq(t.dealer_step()[0].type, &"illegal_action")
