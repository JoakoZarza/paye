extends GutTest

const ORO := Card.Suit.ORO
const COPA := Card.Suit.COPA
const BASTO := Card.Suit.BASTO


func test_dos_del_mismo_palo() -> void:
	assert_eq(Envido.tanto([_c(ORO, 7), _c(ORO, 6), _c(COPA, 1)]), 33)


func test_figuras_valen_cero() -> void:
	assert_eq(Envido.tanto([_c(ORO, 12), _c(ORO, 11), _c(COPA, 1)]), 20)


func test_sin_palo_repetido_toma_la_mas_alta() -> void:
	assert_eq(Envido.tanto([_c(ORO, 5), _c(COPA, 7), _c(BASTO, 12)]), 7)


func test_tres_del_mismo_palo_usa_las_dos_mas_altas() -> void:
	assert_eq(Envido.tanto([_c(ORO, 3), _c(ORO, 6), _c(ORO, 5)]), 31)


func test_cuatro_cartas_por_la_manga() -> void:
	assert_eq(Envido.tanto([_c(ORO, 1), _c(COPA, 7), _c(COPA, 6), _c(BASTO, 4)]), 33)


func test_todo_figuras_de_distinto_palo() -> void:
	assert_eq(Envido.tanto([_c(ORO, 12), _c(COPA, 11), _c(BASTO, 10)]), 0)


func _c(suit: Card.Suit, number: int) -> Card:
	return Card.new(suit, number)
