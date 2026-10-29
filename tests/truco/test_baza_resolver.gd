extends GutTest


func test_gana_dos_primeras() -> void:
	assert_eq(BazaResolver.hand_winner([0, 0], 1), 0)


func test_una_y_una_decide_tercera() -> void:
	assert_eq(BazaResolver.hand_winner([0, 1], 0), BazaResolver.UNDECIDED)
	assert_eq(BazaResolver.hand_winner([0, 1, 1], 0), 1)


func test_primera_parda_decide_segunda() -> void:
	assert_eq(BazaResolver.hand_winner([BazaResolver.PARDA, 1], 0), 1)


func test_primera_ganada_segunda_parda() -> void:
	assert_eq(BazaResolver.hand_winner([1, BazaResolver.PARDA], 0), 1)


func test_tercera_parda_gana_el_de_primera() -> void:
	assert_eq(BazaResolver.hand_winner([1, 0, BazaResolver.PARDA], 0), 1)


func test_tres_pardas_gana_el_mano() -> void:
	var p := BazaResolver.PARDA
	assert_eq(BazaResolver.hand_winner([p, p, p], 1), 1)


func test_dos_pardas_decide_tercera() -> void:
	var p := BazaResolver.PARDA
	assert_eq(BazaResolver.hand_winner([p, p], 0), BazaResolver.UNDECIDED)
	assert_eq(BazaResolver.hand_winner([p, p, 0], 1), 0)


func test_una_parda_sola_no_decide() -> void:
	assert_eq(BazaResolver.hand_winner([BazaResolver.PARDA], 0), BazaResolver.UNDECIDED)
