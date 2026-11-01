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


func _brain(reliability: float) -> DealerBrain:
	var p := RivalProfile.from_dict({
		"id": "test", "aggression": 0.5, "lying": 0.5, "cheating": 0.0,
		"stubbornness": 0.5, "tell_reliability": reliability, "cheat_budget": 0,
	})
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	return DealerBrain.new(p, rng)


## Mano donde el dealer (jugador 1) responde un envido: siempre emite pista.
func _envido_response_hand() -> TrucoHand:
	var h := TrucoHand.new([_cards([[E, 4], [B, 5], [C, 6]]), _cards([[O, 7], [C, 10], [B, 11]])], 0, 15)
	h.apply(TrucoAction.make(T.ENVIDO, 0))
	return h


func test_confiabilidad_se_respeta() -> void:
	var brain := _brain(0.8)
	for i in 2000:
		brain.choose(_envido_response_hand(), 1)
	var rate: float = float(brain.stats[&"honest_tells"]) / brain.stats[&"tells"]
	assert_between(rate, 0.75, 0.85)


func test_icono_angry_con_tilt() -> void:
	var brain := _brain(0.5)
	brain.mood.tilt = 0.6
	brain.choose(_envido_response_hand(), 1)
	assert_eq(brain.last_tell.icon, &"angry")


func test_decision_sin_pista() -> void:
	var brain := _brain(0.5)
	var h := TrucoHand.new([_cards([[O, 2], [B, 5], [C, 6]]), _cards([[C, 3], [E, 1], [B, 4]])], 0, 15)
	# Vale cuatro querido: nadie puede cantar más, solo queda jugar cartas.
	h.apply(TrucoAction.make(T.TRUCO, 0))
	h.apply(TrucoAction.make(T.RETRUCO, 1))
	h.apply(TrucoAction.make(T.VALE_CUATRO, 0))
	h.apply(TrucoAction.make(T.QUIERO, 1))
	h.apply(TrucoAction.make(T.PLAY_CARD, 0, 0))
	var a := brain.choose(h, 1)
	assert_eq(a.type, T.PLAY_CARD)
	assert_null(brain.last_tell)


func test_clave_de_texto_coincide_con_categoria() -> void:
	var brain := _brain(0.5)
	for i in 100:
		brain.choose(_envido_response_hand(), 1)
		var prefix := "TELL_STRONG_" if brain.last_tell.category == &"strong" else "TELL_WEAK_"
		assert_true(String(brain.last_tell.text_key).begins_with(prefix))


func test_csv_tiene_todas_las_claves() -> void:
	var text := FileAccess.get_file_as_string("res://data/i18n/tells.csv")
	for kind in ["STRONG", "WEAK"]:
		for n in range(1, 5):
			assert_string_contains(text, "TELL_%s_%d," % [kind, n])
