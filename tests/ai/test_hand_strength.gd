extends GutTest

const E := Card.Suit.ESPADA
const B := Card.Suit.BASTO
const O := Card.Suit.ORO
const C := Card.Suit.COPA


func _cards(spec: Array) -> Array[Card]:
	var out: Array[Card] = []
	for pair in spec:
		out.append(Card.new(pair[0], pair[1]))
	return out


func test_envido_normaliza() -> void:
	assert_eq(HandStrength.envido(33), 1.0)
	assert_eq(HandStrength.envido(0), 0.0)


func test_truco_mano_fuerte_y_debil() -> void:
	assert_gt(HandStrength.truco(_cards([[E, 1], [B, 1], [C, 4]]), [], 0), 0.9)
	assert_lt(HandStrength.truco(_cards([[C, 4], [O, 5], [B, 6]]), [], 0), 0.25)


func test_truco_baza_ganada_suma() -> void:
	var cards := _cards([[O, 3], [C, 6], [B, 11]])
	var base := HandStrength.truco(cards, [], 0)
	assert_almost_eq(HandStrength.truco(cards, [0], 0), base + HandStrength.BAZA_WON_BONUS, 0.0001)
	assert_almost_eq(HandStrength.truco(cards, [1], 0), base - HandStrength.BAZA_LOST_PENALTY, 0.0001)


func test_truco_con_cuatro_cartas() -> void:
	var s := HandStrength.truco(_cards([[C, 4], [E, 1], [O, 5], [B, 1]]), [], 0)
	assert_almost_eq(s, (14.0 + 13.0) / 28.0, 0.0001)


func test_truco_sin_cartas() -> void:
	var none: Array[Card] = []
	assert_eq(HandStrength.truco(none, [0, 1, 0], 0), 1.0)
	assert_eq(HandStrength.truco(none, [0, 1, 1], 0), 0.0)
