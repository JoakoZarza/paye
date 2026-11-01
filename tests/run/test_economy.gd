extends GutTest

const EconomyScript = preload("res://core/run/economy.gd")


func test_escalera_de_entradas() -> void:
	var economy: Economy = EconomyScript.load_from()
	assert_eq(economy.entry(1), 100)
	assert_eq(economy.entry(4), 2700)
	assert_eq(economy.entry(12), 17714700)


func test_premios_base() -> void:
	var economy: Economy = EconomyScript.load_from()
	assert_eq(economy.base_prize(1), 600)
	assert_eq(economy.base_prize(2), 1650)
	assert_eq(economy.base_prize(9), 2296350)


func test_jefes_y_puntos() -> void:
	var economy: Economy = EconomyScript.load_from()
	for round: int in [4, 8, 12]:
		assert_true(economy.is_boss(round))
		assert_eq(economy.target_points(round), 30)
	assert_false(economy.is_boss(5))
	assert_eq(economy.target_points(5), 15)


func test_precio_y_cambio() -> void:
	var economy: Economy = EconomyScript.load_from()
	assert_eq(economy.price(AmuletDef.Rarity.RARE, 1), 180)
	assert_eq(economy.reroll_cost(1, 0), 30)
	assert_eq(economy.reroll_cost(1, 1), 45)


func test_ronda_13_repite_factor() -> void:
	var economy: Economy = EconomyScript.load_from()
	assert_eq(economy.base_prize(13), floori(float(economy.entry(13)) * 3.5))


func test_cambio_de_ofertas_sin_error_de_redondeo() -> void:
	var e := Economy.load_from()
	assert_eq(e.reroll_cost(3, 5), 945)
