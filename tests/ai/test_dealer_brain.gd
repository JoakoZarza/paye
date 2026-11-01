extends GutTest

const E := Card.Suit.ESPADA
const B := Card.Suit.BASTO
const O := Card.Suit.ORO
const C := Card.Suit.COPA
const T := TrucoAction.Type
const TRIALS := 500


func _cards(spec: Array) -> Array[Card]:
	var out: Array[Card] = []
	for pair in spec:
		out.append(Card.new(pair[0], pair[1]))
	return out


func _profile(aggression: float, lying: float, stubbornness := 0.5, reliability := 0.5) -> RivalProfile:
	return RivalProfile.from_dict({
		"id": "test", "aggression": aggression, "lying": lying, "cheating": 0.0,
		"stubbornness": stubbornness, "tell_reliability": reliability, "cheat_budget": 0,
	})


func _brain(p: RivalProfile, s := 11) -> DealerBrain:
	var rng := RandomNumberGenerator.new()
	rng.seed = s
	return DealerBrain.new(p, rng)


func _apply(h: TrucoHand, type: T, player: int, value := -1) -> void:
	var events := h.apply(TrucoAction.make(type, player, -1, value))
	assert_ne(events[0].type, &"illegal_action")


func _is_legal(h: TrucoHand, a: TrucoAction) -> bool:
	for l in h.legal_actions():
		if l.equals(a):
			return true
	return false


## Mano del dealer (jugador 1, mano) con envido ya querido, lista para declarar.
func _declaration_hand(dealer_cards: Array) -> TrucoHand:
	var h := TrucoHand.new([_cards([[E, 4], [B, 5], [C, 6]]), _cards(dealer_cards)], 1, 15)
	_apply(h, T.ENVIDO, 1)
	_apply(h, T.QUIERO, 0)
	return h


func _lie_rate(lying: float) -> float:
	var brain := _brain(_profile(0.5, lying))
	for i in TRIALS:
		var h := _declaration_hand([[O, 5], [C, 10], [B, 11]])
		brain.choose(HandView.new(h, 1))
	return float(brain.stats[&"lies"]) / brain.stats[&"declarations"]


func test_siempre_elige_accion_legal() -> void:
	var deal_rng := RandomNumberGenerator.new()
	deal_rng.seed = 3
	var brains := [_brain(_profile(0.7, 0.7), 1), _brain(_profile(0.3, 0.3), 2)]
	for n in 300:
		var deck := Deck.new(deal_rng)
		deck.shuffle()
		var h := TrucoHand.new([deck.draw(3), deck.draw(3)], n % 2, 15)
		var steps := 0
		while not h.is_over() and steps < 60:
			var p := h.current_player()
			var a: TrucoAction = brains[p].choose(HandView.new(h, p))
			assert_true(_is_legal(h, a), "acción ilegal en fase %d" % h.phase)
			h.apply(a)
			steps += 1
		assert_true(h.is_over())


func test_mano_33_segundo_dice_son_buenas() -> void:
	var brain := _brain(_profile(0.9, 1.0))
	for i in 50:
		var h := TrucoHand.new([_cards([[O, 7], [O, 6], [C, 4]]), _cards([[E, 5], [E, 10], [B, 4]])], 0, 15)
		_apply(h, T.ENVIDO, 0)
		_apply(h, T.QUIERO, 1)
		_apply(h, T.DECLARE_TANTO, 0, 33)
		assert_eq(brain.choose(HandView.new(h, 1)).type, T.SON_BUENAS)


func test_nunca_miente_con_mentira_0() -> void:
	assert_eq(_lie_rate(0.0), 0.0)


func test_mentiroso_miente_mas_que_honesto() -> void:
	assert_gt(_lie_rate(0.85) - _lie_rate(0.1), 0.3)


func test_agresivo_canta_truco_mas() -> void:
	var calls := []
	for aggression in [0.9, 0.1]:
		var brain := _brain(_profile(aggression, 0.0))
		var count := 0
		for i in TRIALS:
			var h := TrucoHand.new([_cards([[E, 4], [B, 5], [C, 6]]), _cards([[O, 3], [C, 6], [B, 11]])], 1, 15)
			if brain.choose(HandView.new(h, 1)).type == T.TRUCO:
				count += 1
		calls.append(count)
	assert_gt(calls[0], calls[1])


func test_responde_baza_con_la_mas_baja_que_gana() -> void:
	var h := TrucoHand.new([_cards([[O, 2], [B, 5], [C, 6]]), _cards([[C, 3], [E, 1], [B, 4]])], 0, 15)
	h.apply(TrucoAction.make(T.PLAY_CARD, 0, 0))
	var brain := _brain(_profile(0.5, 0.5))
	assert_eq(brain.pick_card(HandView.new(h, 1)), 0)


func test_observe_pescado_mintiendo_sube_tilt() -> void:
	var brain := _brain(_profile(0.5, 0.5))
	brain.observe([GameEvent.make(&"lie_caught", {"player": 1})], 1)
	assert_almost_eq(brain.mood.tilt, DealerMood.CAUGHT_LYING_TILT, 0.0001)
	brain.observe([GameEvent.make(&"lie_caught", {"player": 0})], 1)
	assert_eq(brain.model.lies_caught, 1)


func test_tilt_aumenta_faroles() -> void:
	var bluffs := []
	for tilt in [0.0, 1.0]:
		var brain := _brain(_profile(0.5, 0.5))
		brain.mood.tilt = tilt
		var count := 0
		for i in TRIALS:
			var h := TrucoHand.new([_cards([[E, 4], [B, 5], [C, 6]]), _cards([[O, 4], [C, 10], [B, 11]])], 1, 15)
			if brain.choose(HandView.new(h, 1)).type in DealerBrain.ENVIDO_TYPES:
				count += 1
		bluffs.append(count)
	assert_gt(bluffs[1], bluffs[0])


func test_start_match_reinicia_humor_y_conserva_memoria() -> void:
	var brain := _brain(_profile(0.5, 0.5))
	brain.observe([GameEvent.make(&"lie_caught", {"player": 1}), GameEvent.make(&"lie_caught", {"player": 0})], 1)
	brain.start_match()
	assert_eq(brain.mood.tilt, 0.0)
	assert_eq(brain.mood.confidence, 0.5)
	assert_eq(brain.model.lies_caught, 1)


func test_cuenta_oportunidades_de_truco() -> void:
	var brain := _brain(_profile(0.9, 0.0))
	var h := TrucoHand.new([_cards([[E, 4], [B, 5], [C, 6]]), _cards([[O, 3], [C, 6], [B, 11]])], 1, 15)
	brain.choose(HandView.new(h, 1))
	assert_eq(brain.stats[&"truco_chances"], 1)


func test_truco_cuenta_la_carta_propia_en_la_mesa() -> void:
	# Tercera baza 1 a 1: el dealer ya tiró el ancho de espada y el rival canta truco.
	var brain := _brain(_profile(0.5, 0.0, 0.0))
	for i in 100:
		var h := TrucoHand.new([_cards([[O, 3], [B, 4], [B, 6]]), _cards([[C, 4], [O, 5], [E, 1]])], 1, 15)
		for idx in [[1, 0], [0, 0], [0, 0], [1, 0], [1, 0]]:
			h.apply(TrucoAction.make(T.PLAY_CARD, idx[0], idx[1]))
		_apply(h, T.TRUCO, 0)
		assert_true(brain.choose(HandView.new(h, 1)).type in [T.QUIERO, T.RETRUCO])


func test_sin_falta_envido_con_poca_agresividad() -> void:
	var brain := _brain(_profile(0.1, 0.0))
	for i in 200:
		var h := TrucoHand.new([_cards([[E, 4], [B, 5], [C, 6]]), _cards([[O, 7], [O, 6], [C, 4]])], 0, 15)
		_apply(h, T.REAL_ENVIDO, 0)
		assert_ne(brain.choose(HandView.new(h, 1)).type, T.FALTA_ENVIDO)


func test_pista_refleja_la_mano_real() -> void:
	# Fuerza real 0.57 (débil), pero la confianza alta la hace parecer fuerte.
	var brain := _brain(_profile(0.5, 0.0, 0.5, 1.0))
	brain.mood.confidence = 0.9
	for i in 100:
		var h := TrucoHand.new([_cards([[E, 4], [B, 5], [C, 6]]), _cards([[O, 3], [B, 11], [C, 4]])], 0, 15)
		_apply(h, T.TRUCO, 0)
		brain.choose(HandView.new(h, 1))
		assert_eq(brain.last_tell.category, &"weak")


func test_memoria_cuenta_los_quiero_del_jugador() -> void:
	var brain := _brain(_profile(0.5, 0.5))
	brain.observe([
		GameEvent.make(&"call_made", {"player": 1, "call": T.TRUCO}),
		GameEvent.make(&"call_accepted", {"player": 0}),
		GameEvent.make(&"call_made", {"player": 1, "call": T.ENVIDO}),
		GameEvent.make(&"call_rejected", {"player": 0}),
	], 1)
	assert_eq(brain.model.truco_offers, 1)
	assert_eq(brain.model.truco_accepts, 1)
	assert_eq(brain.model.envido_offers, 1)
	assert_eq(brain.model.envido_accepts, 0)


func test_acusacion_fallida_del_rival_sube_tilt() -> void:
	var brain := _brain(_profile(0.5, 0.5))
	brain.observe([GameEvent.make(&"show_wrong", {"player": 0})], 1)
	assert_almost_eq(brain.mood.tilt, DealerMood.WRONG_SHOW_TILT, 0.0001)
