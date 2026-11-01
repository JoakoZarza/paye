extends GutTest
## Reglas especiales de las versiones (DISENO §5.5), trampas preferidas y ruido.

const E := Card.Suit.ESPADA
const B := Card.Suit.BASTO
const O := Card.Suit.ORO
const C := Card.Suit.COPA
const T := TrucoAction.Type
const K := Cheat.Kind
const TRIALS := 400
const ALL_CHEATS: Array[Cheat.Kind] = [K.SLEEVE, K.DUPLICATE, K.ACCOMPLICE]


func _cards(spec: Array) -> Array[Card]:
	var out: Array[Card] = []
	for pair in spec:
		out.append(Card.new(pair[0], pair[1]))
	return out


func _profile(extra: Dictionary = {}) -> RivalProfile:
	var d := {
		"id": "test", "aggression": 0.5, "lying": 0.3, "cheating": 0.5,
		"stubbornness": 0.5, "tell_reliability": 0.9, "cheat_budget": 0,
	}
	d.merge(extra, true)
	return RivalProfile.from_dict(d)


func _brain(p: RivalProfile, s := 11) -> DealerBrain:
	var rng := RandomNumberGenerator.new()
	rng.seed = s
	var brain := DealerBrain.new(p, rng)
	brain.start_match()
	return brain


func _apply(h: TrucoHand, type: T, player: int) -> void:
	var events := h.apply(TrucoAction.make(type, player))
	assert_ne(events[0].type, &"illegal_action")


## El jugador 0 canta y el dealer (jugador 1) tiene que responder con un tanto flojo.
func _envido_answer_hand(call: T) -> TrucoHand:
	var h := TrucoHand.new([_cards([[E, 4], [B, 5], [C, 6]]), _cards([[O, 4], [C, 11], [B, 2]])], 0, 15)
	_apply(h, call, 0)
	return h


func _cheats_done(brain: DealerBrain, available: Array[Cheat.Kind]) -> Dictionary:
	var count := {-1: 0, K.SLEEVE: 0, K.DUPLICATE: 0, K.ACCOMPLICE: 0}
	for i in TRIALS:
		brain.cheat_budget = 1000
		count[brain.decide_cheat(available)] += 1
	return count


# --- Rencor ---

func test_rencor_el_tilt_no_baja() -> void:
	var brain := _brain(_profile({"special": "rencor"}))
	brain.mood.on_hand_result(false)
	var after_loss := brain.mood.tilt
	brain.mood.on_hand_result(true)
	assert_almost_eq(brain.mood.tilt, after_loss, 0.0001)
	var plain := _brain(_profile())
	plain.mood.on_hand_result(false)
	plain.mood.on_hand_result(true)
	assert_lt(plain.mood.tilt, after_loss)


func test_rencor_hace_mas_trampa_con_tilt() -> void:
	var rencor := _brain(_profile({"special": "rencor", "cheating": 1.0}))
	var plain := _brain(_profile({"cheating": 1.0}))
	rencor.mood.tilt = 0.8
	plain.mood.tilt = 0.8
	var with_rule: int = TRIALS - _cheats_done(rencor, ALL_CHEATS)[-1]
	var without: int = TRIALS - _cheats_done(plain, ALL_CHEATS)[-1]
	assert_gt(with_rule, without * 1.4, "rencor %d vs normal %d" % [with_rule, without])


func test_multiplicador_de_tilt() -> void:
	var hot := _brain(_profile({"tilt_multiplier": 2.0}))
	hot.mood.on_hand_result(false)
	assert_almost_eq(hot.mood.tilt, DealerMood.HAND_LOST_TILT * 2.0, 0.0001)
	hot.start_match()
	assert_eq(hot.mood.tilt_multiplier, 2.0, "el humor nuevo conserva el multiplicador")


# --- Insaciable ---

func test_insaciable_nunca_rechaza_envido() -> void:
	var hungry := _brain(_profile({"special": "insaciable"}))
	var plain := _brain(_profile())
	var plain_rejects := 0
	for i in TRIALS:
		var a := hungry.choose(HandView.new(_envido_answer_hand(T.ENVIDO), 1))
		assert_ne(a.type, T.NO_QUIERO)
		if plain.choose(HandView.new(_envido_answer_hand(T.ENVIDO), 1)).type == T.NO_QUIERO:
			plain_rejects += 1
	assert_gt(plain_rejects, TRIALS / 2, "sin la regla, con tanto flojo, rechaza")


func test_insaciable_sin_subida_quiere() -> void:
	var hungry := _brain(_profile({"special": "insaciable"}))
	for i in TRIALS:
		var a := hungry.choose(HandView.new(_envido_answer_hand(T.FALTA_ENVIDO), 1))
		assert_eq(a.type, T.QUIERO)


# --- Siesta ---

func _envido_calls(brain: DealerBrain, my_score: int, their_score: int) -> int:
	var calls := 0
	for i in TRIALS:
		# Tanto 27: a veces canta, a veces no.
		var h := TrucoHand.new([_cards([[E, 4], [B, 5], [C, 6]]), _cards([[O, 7], [O, 10], [B, 4]])], 1, 15)
		brain.set_match_context(my_score, their_score, 15)
		var a := brain.choose(HandView.new(h, 1))
		if a.type in DealerBrain.ENVIDO_TYPES:
			calls += 1
	return calls


func test_siesta_juega_dormido_hasta_despertar() -> void:
	var asleep := _envido_calls(_brain(_profile({"special": "siesta"})), 0, 0)
	var awake := _envido_calls(_brain(_profile({"special": "siesta"})), 9, 0)
	var plain := _envido_calls(_brain(_profile()), 0, 0)
	assert_lt(asleep, plain * 0.7, "dormido %d vs normal %d" % [asleep, plain])
	assert_almost_eq(float(awake), float(plain), plain * 0.25)


# --- Resentida ---

func _leads_highest(brain: DealerBrain) -> bool:
	var h := TrucoHand.new([_cards([[E, 4], [B, 5], [C, 6]]), _cards([[O, 4], [C, 7], [E, 1]])], 1, 15)
	var view := HandView.new(h, 1)
	return view.my_cards()[brain.pick_card(view)].truco_rank() == Card.new(E, 1).truco_rank()


func test_resentida_se_pone_agresiva_si_pierde() -> void:
	var brain := _brain(_profile({"special": "resentida", "aggression": 0.4}))
	brain.set_match_context(5, 5, 15)
	assert_false(_leads_highest(brain))
	brain.set_match_context(5, 8, 15)
	assert_true(_leads_highest(brain))
	var plain := _brain(_profile({"aggression": 0.4}))
	plain.set_match_context(5, 8, 15)
	assert_false(_leads_highest(plain))


# --- Encantadora ---

func _honest_rate(brain: DealerBrain) -> float:
	for i in TRIALS:
		brain._emit_tell(0.8)
	return float(brain.stats[&"honest_tells"]) / brain.stats[&"tells"]


func test_encantadora_traiciona_desde_la_mitad() -> void:
	var early := _brain(_profile({"special": "encantadora"}))
	early.set_match_context(3, 7, 15)
	assert_gt(_honest_rate(early), 0.8)
	var late := _brain(_profile({"special": "encantadora"}))
	late.set_match_context(3, 8, 15)
	assert_lt(_honest_rate(late), 0.2)
	var plain := _brain(_profile())
	plain.set_match_context(3, 8, 15)
	assert_gt(_honest_rate(plain), 0.8)


# --- Trampas preferidas y ruido ---

func test_pesos_eligen_la_trampa_preferida() -> void:
	var brain := _brain(_profile({"cheating": 1.0, "cheat_weights": {"DUPLICATE": 1.0}}))
	var count := _cheats_done(brain, ALL_CHEATS)
	assert_gt(count[K.DUPLICATE], 0)
	assert_eq(count[K.SLEEVE], 0)
	assert_eq(count[K.ACCOMPLICE], 0)


func test_pesos_mezclados_reparten() -> void:
	var brain := _brain(_profile({"cheating": 1.0, "cheat_weights": {"DUPLICATE": 0.5, "ACCOMPLICE": 0.5}}))
	var count := _cheats_done(brain, ALL_CHEATS)
	assert_eq(count[K.SLEEVE], 0)
	assert_gt(count[K.DUPLICATE], 30)
	assert_gt(count[K.ACCOMPLICE], 30)


func test_sin_peso_no_hace_trampa() -> void:
	var brain := _brain(_profile({"cheating": 1.0, "cheat_weights": {"SLEEVE": 1.0}}))
	var only_others: Array[Cheat.Kind] = [K.DUPLICATE, K.ACCOMPLICE]
	brain.cheat_budget = 3
	for i in TRIALS:
		assert_eq(brain.decide_cheat(only_others), -1)
	assert_eq(brain.cheat_budget, 3)


func test_perfil_sin_pesos_usa_todas() -> void:
	var brain := _brain(_profile({"cheating": 1.0}))
	var count := _cheats_done(brain, ALL_CHEATS)
	for kind in ALL_CHEATS:
		assert_gt(count[kind], 0)


func _max_deviation(brain: DealerBrain) -> float:
	var worst := 0.0
	for i in TRIALS:
		worst = maxf(worst, absf(brain._perceived(0.5) - 0.5))
	return worst


func test_ruido_del_novato_es_mayor() -> void:
	var novato := _max_deviation(_brain(_profile({"noise": 0.45})))
	var plain := _max_deviation(_brain(_profile()))
	assert_lte(plain, 0.15 + 0.0001)
	assert_gt(novato, 0.3)


func test_la_mesa_le_pasa_el_marcador() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var m := TrucoMatch.new(15, rng)
	var brain := DealerBrain.new(_profile(), rng)
	var table := CheatTable.new(m, brain, 1, rng)
	table.start_match()
	m.scores.assign([4, 9])
	table.start_hand()
	assert_eq(brain._my_score, 9)
	assert_eq(brain._their_score, 4)
	assert_eq(brain._target, 15)
