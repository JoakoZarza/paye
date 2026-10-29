extends GutTest

func test_mazo_completo_tiene_40_cartas_unicas() -> void:
	var cards := Deck.full_deck()
	assert_eq(cards.size(), 40)
	var keys := {}
	for c in cards:
		keys[c.key()] = true
	assert_eq(keys.size(), 40)

func test_misma_semilla_mismo_orden() -> void:
	var a := _draw_all(1234)
	var b := _draw_all(1234)
	assert_eq(a, b)
	assert_ne(a, _draw_all(999))

func test_draw_descuenta() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var d := Deck.new(rng)
	d.shuffle()
	assert_eq(d.draw(3).size(), 3)
	assert_eq(d.remaining(), 37)

func _draw_all(s: int) -> Array[String]:
	var rng := RandomNumberGenerator.new()
	rng.seed = s
	var d := Deck.new(rng)
	d.shuffle()
	var out: Array[String] = []
	for c in d.draw(40):
		out.append(c.key())
	return out
