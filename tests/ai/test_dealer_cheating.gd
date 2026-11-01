extends GutTest

const E := Card.Suit.ESPADA
const B := Card.Suit.BASTO
const O := Card.Suit.ORO
const C := Card.Suit.COPA
const T := TrucoAction.Type
const ALL_KINDS: Array[Cheat.Kind] = [Cheat.Kind.SLEEVE, Cheat.Kind.DUPLICATE, Cheat.Kind.ACCOMPLICE]


func _cards(spec: Array) -> Array[Card]:
	var out: Array[Card] = []
	for pair in spec:
		out.append(Card.new(pair[0], pair[1]))
	return out


func _brain(cheating: float, budget: int, aggression := 0.5) -> DealerBrain:
	var p := RivalProfile.from_dict({
		"id": "test", "aggression": aggression, "lying": 0.0, "cheating": cheating,
		"stubbornness": 0.5, "tell_reliability": 0.5, "cheat_budget": budget,
	})
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var b := DealerBrain.new(p, rng)
	b.start_match()
	return b


func _cheat_rate(suspicion: float) -> float:
	var b := _brain(1.0, 1)
	b.mood.suspicion = suspicion
	var count := 0
	for i in 2000:
		b.cheat_budget = 1
		if b.decide_cheat(ALL_KINDS) != -1:
			count += 1
	return count / 2000.0


func test_presupuesto_cero_nunca_hace_trampa() -> void:
	var b := _brain(1.0, 0)
	for i in 1000:
		assert_eq(b.decide_cheat(ALL_KINDS), -1)


func test_sin_trampas_disponibles_no_hace() -> void:
	var b := _brain(1.0, 5)
	var none: Array[Cheat.Kind] = []
	for i in 200:
		assert_eq(b.decide_cheat(none), -1)
	assert_eq(b.cheat_budget, 5)


func test_presupuesto_se_gasta() -> void:
	var b := _brain(1.0, 2)
	var count := 0
	for i in 1000:
		if b.decide_cheat(ALL_KINDS) != -1:
			count += 1
	assert_eq(count, 2)
	assert_eq(b.cheat_budget, 0)


func test_sospecha_frena_trampas() -> void:
	assert_lt(_cheat_rate(1.0), _cheat_rate(0.0) * 0.5)


func test_complice_cambia_la_decision_de_truco() -> void:
	var b := _brain(0.0, 0, 0.2)
	for i in 100:
		var h := TrucoHand.new([_cards([[E, 1], [E, 7], [B, 4]]), _cards([[O, 3], [C, 6], [B, 11]])], 0, 15)
		h.apply(TrucoAction.make(T.TRUCO, 0))
		var v := HandView.new(h, 1)
		v.known_opponent_cards = _cards([[E, 1], [E, 7], [B, 4]])
		assert_ne(b.choose(v).type, T.QUIERO)


func test_complice_quiere_el_envido_solo_si_gana() -> void:
	var b := _brain(0.0, 0, 0.9)
	for i in 50:
		var h := TrucoHand.new([_cards([[E, 1], [E, 7], [B, 4]]), _cards([[O, 7], [O, 6], [B, 11]])], 0, 15)
		h.apply(TrucoAction.make(T.ENVIDO, 0))
		var v := HandView.new(h, 1)
		v.known_opponent_cards = _cards([[E, 1], [E, 7], [B, 4]])
		assert_ne(b.choose(v).type, T.NO_QUIERO)


func test_start_match_carga_el_presupuesto() -> void:
	var b := _brain(1.0, 3)
	b.cheat_budget = 0
	b.start_match()
	assert_eq(b.cheat_budget, 3)


func test_humor_de_trampas_en_rango() -> void:
	var m := DealerMood.new()
	for i in 20:
		m.on_accused()
		m.on_caught_player_cheating()
		m.on_caught_cheating()
	for v in [m.confidence, m.tilt, m.suspicion]:
		assert_between(v, 0.0, 1.0)
	assert_eq(m.suspicion, 1.0)


func test_complice_no_quiere_un_envido_que_pierde() -> void:
	var b := _brain(0.0, 0, 0.9)
	for i in 50:
		var h := TrucoHand.new([_cards([[O, 7], [O, 6], [B, 4]]), _cards([[E, 7], [E, 4], [B, 11]])], 0, 15)
		h.apply(TrucoAction.make(T.ENVIDO, 0))
		var v := HandView.new(h, 1)
		v.known_opponent_cards = _cards([[O, 7], [O, 6], [B, 4]])
		assert_eq(b.choose(v).type, T.NO_QUIERO)


func test_sin_complice_la_misma_mano_a_veces_quiere_el_truco() -> void:
	var b := _brain(0.0, 0, 0.2)
	var quiero := 0
	for i in 100:
		var h := TrucoHand.new([_cards([[E, 1], [E, 7], [B, 4]]), _cards([[O, 3], [C, 6], [B, 11]])], 0, 15)
		h.apply(TrucoAction.make(T.TRUCO, 0))
		if b.choose(HandView.new(h, 1)).type == T.QUIERO:
			quiero += 1
	assert_gt(quiero, 0)
