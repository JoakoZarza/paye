extends GutTest

const AmuletDef = preload("res://core/amulets/amulet_def.gd")
const Loadout = preload("res://core/amulets/loadout.gd")

var amulets: Dictionary

func before_each() -> void:
	amulets = AmuletDef.load_all()


func test_dos_espacios() -> void:
	var loadout := Loadout.new()
	for amulet_id: StringName in [&"marker", &"spare_deck"]:
		assert_true(loadout.equip(amulets[amulet_id]))
	assert_false(loadout.equip(amulets[&"hat"]))
	assert_eq(loadout.equipped().size(), 2)


func test_no_repite() -> void:
	var loadout := Loadout.new()
	assert_true(loadout.equip(amulets[&"marker"]))
	assert_false(loadout.equip(amulets[&"marker"]))


func test_gastar_y_reponer_cargas() -> void:
	var loadout := Loadout.new()
	loadout.equip(amulets[&"spare_deck"])
	assert_true(loadout.spend(&"spare_deck"))
	assert_eq(loadout.charges_left(&"spare_deck"), 1)
	loadout.reset_charges()
	assert_eq(loadout.charges_left(&"spare_deck"), 2)


func test_pasivo_no_gasta() -> void:
	var loadout := Loadout.new()
	loadout.equip(amulets[&"cigarette"])
	assert_false(loadout.spend(&"cigarette"))


func test_cinta_roja_descuenta() -> void:
	var loadout := Loadout.new()
	assert_eq(loadout.shop_price_multiplier(), 1.0)
	loadout.equip(amulets[&"red_ribbon"])
	assert_almost_eq(loadout.shop_price_multiplier(), 0.8, 0.0001)


func test_moneda_multiplica_solo_sin_envido() -> void:
	var loadout := Loadout.new()
	loadout.equip(amulets[&"train_coin"])
	assert_eq(loadout.prize_multiplier(true), 1.0)
	assert_eq(loadout.prize_multiplier(false), 1.5)


func test_mejora_hasta_nivel_tres() -> void:
	var loadout := Loadout.new()
	assert_false(loadout.upgrade(&"marker"))
	loadout.equip(amulets[&"marker"])
	assert_eq(loadout.level(&"marker"), 1)
	assert_true(loadout.upgrade(&"marker"))
	assert_true(loadout.upgrade(&"marker"))
	assert_eq(loadout.level(&"marker"), 3)
	assert_false(loadout.upgrade(&"marker"))
	loadout.unequip(&"marker")
	assert_eq(loadout.level(&"marker"), 0)
	loadout.equip(amulets[&"marker"])
	assert_eq(loadout.level(&"marker"), 1)


func test_cargas_segun_nivel_al_reiniciar_partido() -> void:
	var loadout := Loadout.new()
	loadout.equip(amulets[&"rosary"])
	assert_true(loadout.upgrade(&"rosary"))
	assert_true(loadout.upgrade(&"rosary"))
	loadout.spend(&"rosary")
	loadout.reset_charges()
	assert_eq(loadout.charges_left(&"rosary"), 3)


func test_multiplicadores_segun_nivel() -> void:
	var loadout := Loadout.new()
	loadout.equip(amulets[&"red_ribbon"])
	assert_true(loadout.upgrade(&"red_ribbon"))
	assert_true(loadout.upgrade(&"red_ribbon"))
	assert_almost_eq(loadout.shop_price_multiplier(), 0.6, 0.0001)
	var coin_loadout := Loadout.new()
	coin_loadout.equip(amulets[&"train_coin"])
	assert_true(coin_loadout.upgrade(&"train_coin"))
	assert_almost_eq(coin_loadout.prize_multiplier(false), 1.75, 0.0001)
