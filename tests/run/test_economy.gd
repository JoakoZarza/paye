extends GutTest

const EconomyScript = preload("res://core/run/economy.gd")
const PRIZES: Array[int] = [450, 450, 1200, 1800, 1500, 6000, 11000, 8000, 10000000]


func test_tabla_de_rondas() -> void:
	var economy: Economy = EconomyScript.load_from()
	assert_eq(economy.rounds_total(), 9)
	assert_eq(economy.entry(1), 100)
	assert_eq(economy.entry(5), 500, "la V: la ronda del alma es más barata")
	assert_eq(economy.entry(9), 8000)
	for r in range(1, 10):
		assert_eq(economy.base_prize(r), PRIZES[r - 1])


func test_puntos_y_final() -> void:
	var economy: Economy = EconomyScript.load_from()
	for r in range(1, 9):
		assert_eq(economy.target_points(r), 15)
		assert_false(economy.is_final(r))
	assert_eq(economy.target_points(9), 30)
	assert_true(economy.is_final(9))


func test_fuera_de_la_tabla_usa_la_ronda_mas_cercana() -> void:
	var economy: Economy = EconomyScript.load_from()
	assert_eq(economy.entry(0), 100)
	assert_eq(economy.entry(12), 8000)


func test_precio_y_cambio() -> void:
	var economy: Economy = EconomyScript.load_from()
	assert_eq(economy.price(AmuletDef.Rarity.RARE, 1), 270, "180% de la entrada de la ronda 2")
	assert_eq(economy.price(AmuletDef.Rarity.LEGENDARY, 9), 28800, "en la final toma su propia entrada")
	assert_eq(economy.reroll_cost(1, 0), 15)
	assert_eq(economy.reroll_cost(1, 1), 22)


func test_precio_crece_con_cada_compra() -> void:
	var economy: Economy = EconomyScript.load_from()
	assert_eq(economy.price(AmuletDef.Rarity.RARE, 1, 0), 270)
	assert_eq(economy.price(AmuletDef.Rarity.RARE, 1, 1), 337)
	assert_eq(economy.price(AmuletDef.Rarity.RARE, 1, 2), 405)


func test_un_solo_redondeo_con_descuento() -> void:
	var economy: Economy = EconomyScript.load_from()
	# 270 × 1,25 × 0,8 = 270 exacto; redondeando en el medio daría 269.
	assert_eq(economy.price(AmuletDef.Rarity.RARE, 1, 1, 0.8), 270)


func test_cambio_de_ofertas_sin_error_de_redondeo() -> void:
	var e := Economy.load_from()
	assert_eq(e.reroll_cost(3, 5), 210)


func test_propina_del_bar() -> void:
	var e := Economy.load_from()
	assert_eq(e.tip(300, 1), 0, "justo 3 entradas: sin propina")
	assert_eq(e.tip(400, 1), 10, "una entrada más: 10% de esa entrada")
	assert_eq(e.tip(20000, 6), 1400)
	assert_eq(e.tip(50, 1), 0)


func test_interes_del_fiado() -> void:
	var e := Economy.load_from()
	assert_eq(e.fiado_with_interest(0), 0)
	assert_eq(e.fiado_with_interest(1), 2, "redondea para arriba")
	assert_eq(e.fiado_with_interest(100), 110)
	assert_eq(e.fiado_with_interest(105), 116)
