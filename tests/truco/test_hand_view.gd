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


func _hand() -> TrucoHand:
	return TrucoHand.new([_cards([[O, 7], [O, 6], [C, 4]]), _cards([[E, 1], [E, 5], [B, 6]])], 0, 15)


func test_vista_no_expone_cartas_del_rival() -> void:
	var v := HandView.new(_hand(), 0)
	for forbidden in ["opponent_cards", "cards", "opponent_tanto", "own_tanto", "hand"]:
		assert_false(v.has_method(forbidden), "HandView no debe tener %s()" % forbidden)
	assert_eq(v.known_opponent_cards.size(), 0)


func test_vista_refleja_la_mano() -> void:
	var h := _hand()
	h.apply(TrucoAction.make(T.PLAY_CARD, 0, 2))
	var v := HandView.new(h, 1)
	assert_eq(v.me, 1)
	assert_eq(v.my_cards().size(), 3)
	assert_eq(v.my_cards()[0].key(), "1_ESPADA")
	assert_eq(v.played(0).size(), 1)
	assert_eq(v.played(0)[0].key(), "4_COPA")
	assert_eq(v.mano(), 0)
	assert_eq(v.current_player(), 1)
	assert_eq(v.phase(), TrucoHand.Phase.PLAYING)
	assert_eq(v.truco_level(), 0)
	assert_eq(v.my_tanto(), 26)
	assert_eq(v.legal_actions().size(), h.legal_actions().size())
	assert_eq(v.baza_results(), h.baza_results)


func test_opponent_card_count() -> void:
	var h := _hand()
	h.apply(TrucoAction.make(T.PLAY_CARD, 0, 0))
	assert_eq(HandView.new(h, 1).opponent_card_count(), 2)


func test_mis_cartas_son_una_copia() -> void:
	var h := _hand()
	var v := HandView.new(h, 0)
	v.my_cards().clear()
	assert_eq(h.cards[0].size(), 3)
