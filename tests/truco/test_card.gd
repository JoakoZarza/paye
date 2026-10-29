extends GutTest

func test_rangos_de_la_jerarquia() -> void:
	assert_eq(Card.new(Card.Suit.ESPADA, 1).truco_rank(), 14)
	assert_eq(Card.new(Card.Suit.BASTO, 1).truco_rank(), 13)
	assert_eq(Card.new(Card.Suit.ESPADA, 7).truco_rank(), 12)
	assert_eq(Card.new(Card.Suit.ORO, 7).truco_rank(), 11)
	assert_eq(Card.new(Card.Suit.COPA, 3).truco_rank(), 10)
	assert_eq(Card.new(Card.Suit.ORO, 2).truco_rank(), 9)
	assert_eq(Card.new(Card.Suit.COPA, 1).truco_rank(), 8)
	assert_eq(Card.new(Card.Suit.ORO, 1).truco_rank(), 8)
	assert_eq(Card.new(Card.Suit.BASTO, 12).truco_rank(), 7)
	assert_eq(Card.new(Card.Suit.BASTO, 11).truco_rank(), 6)
	assert_eq(Card.new(Card.Suit.BASTO, 10).truco_rank(), 5)
	assert_eq(Card.new(Card.Suit.COPA, 7).truco_rank(), 4)
	assert_eq(Card.new(Card.Suit.BASTO, 7).truco_rank(), 4)
	assert_eq(Card.new(Card.Suit.ESPADA, 6).truco_rank(), 3)
	assert_eq(Card.new(Card.Suit.ESPADA, 5).truco_rank(), 2)
	assert_eq(Card.new(Card.Suit.ESPADA, 4).truco_rank(), 1)

func test_valor_de_tanto() -> void:
	assert_eq(Card.new(Card.Suit.ORO, 7).envido_value(), 7)
	assert_eq(Card.new(Card.Suit.ORO, 12).envido_value(), 0)
	assert_eq(Card.new(Card.Suit.ORO, 10).envido_value(), 0)

func test_modificador_cambia_rango() -> void:
	var c := Card.new(Card.Suit.COPA, 4)
	var m := CardModifier.new()
	m.new_number = 7
	m.new_suit = Card.Suit.ESPADA
	m.scope = CardModifier.Scope.MATCH
	assert_true(c.add_modifier(m))
	assert_eq(c.truco_rank(), 12)
	assert_eq(c.key(), "4_COPA")

func test_modificador_invalido_se_rechaza() -> void:
	var c := Card.new(Card.Suit.COPA, 4)
	var m := CardModifier.new()
	m.new_number = 8
	assert_false(c.add_modifier(m))
	assert_eq(c.effective_number(), 4)

func test_limpiar_modificadores_de_mano() -> void:
	var c := Card.new(Card.Suit.COPA, 4)
	var m := CardModifier.new()
	m.new_number = 5
	m.scope = CardModifier.Scope.HAND
	c.add_modifier(m)
	c.clear_modifiers(CardModifier.Scope.HAND)
	assert_eq(c.effective_number(), 4)
