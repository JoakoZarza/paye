extends GutTest

var _economy: Economy
var _defs: Dictionary


func before_all() -> void:
	_economy = Economy.load_from()
	_defs = AmuletDef.load_all()


func _shop(s := 1) -> Shop:
	var rng := RandomNumberGenerator.new()
	rng.seed = s
	return Shop.new(_economy, _defs, rng)


func _state(money: int, ids: Array = []) -> RunState:
	var st := RunState.new()
	st.money = money
	for id in ids:
		st.loadout.equip(_defs[StringName(id)])
	return st


func _offer(shop: Shop, id: StringName) -> void:
	shop.offers.clear()
	shop.offers.append(_defs[id])


func test_tres_ofertas_sin_repetir_ni_equipados() -> void:
	for s in 100:
		var shop := _shop(s)
		var st := _state(0, ["glasses", "hat"])
		shop.open(st)
		assert_eq(shop.offers.size(), 3)
		var ids := shop.offers.map(func(d: AmuletDef) -> StringName: return d.id)
		assert_false(&"glasses" in ids)
		assert_false(&"hat" in ids)
		assert_ne(ids[0], ids[1])
		assert_ne(ids[1], ids[2])
		assert_ne(ids[0], ids[2])


func test_comprar_con_plata() -> void:
	var shop := _shop()
	var st := _state(1000)
	_offer(shop, &"rosary")
	var r := shop.buy(0, st)
	assert_true(r["ok"])
	assert_eq(r["paid"], 180)
	assert_eq(st.money, 820)
	assert_true(st.loadout.has(&"rosary"))
	assert_eq(shop.offers.size(), 0)


func test_comprar_fiado_dentro_del_limite() -> void:
	var shop := _shop()
	var st := _state(100)
	_offer(shop, &"rosary")
	var r := shop.buy(0, st)
	assert_true(r["ok"])
	assert_eq(r["paid"], 100)
	assert_eq(r["fiado"], 80)
	assert_eq(st.money, 0)
	assert_eq(st.fiado, 80)


func test_fiado_fuera_del_limite_falla_sin_cambiar_nada() -> void:
	var shop := _shop()
	var st := _state(50)
	_offer(shop, &"hat")
	var r := shop.buy(0, st)
	assert_false(r["ok"])
	assert_eq(r["reason"], &"no_credit")
	assert_eq(st.money, 50)
	assert_eq(st.fiado, 0)
	assert_false(st.loadout.has(&"hat"))
	assert_eq(shop.offers.size(), 1)


func test_sin_espacio_falla() -> void:
	var shop := _shop()
	var st := _state(100000, ["glasses", "hat", "mirror", "facon"])
	_offer(shop, &"rosary")
	assert_eq(shop.buy(0, st)["reason"], &"no_slot")


func test_cinta_roja_descuenta() -> void:
	var shop := _shop()
	assert_eq(shop.price_of(_defs[&"rosary"], _state(0, ["red_ribbon"])), 144)


func test_cambio_de_ofertas_cuesta_cada_vez_mas() -> void:
	var shop := _shop()
	var st := _state(100)
	shop.open(st)
	assert_true(shop.reroll(st))
	assert_eq(st.money, 70)
	assert_true(shop.reroll(st))
	assert_eq(st.money, 25)
	assert_false(shop.reroll(st))
	assert_eq(st.money, 25)


func test_vender_devuelve_la_mitad_de_lo_pagado() -> void:
	var shop := _shop()
	var st := _state(1000)
	_offer(shop, &"rosary")
	shop.buy(0, st)
	assert_eq(shop.sell(&"rosary", st), 90)
	assert_eq(st.money, 910)
	assert_false(st.loadout.has(&"rosary"))
	assert_eq(shop.sell(&"rosary", st), 0)


func test_rarezas_respetan_los_pesos() -> void:
	var counts := {AmuletDef.Rarity.COMMON: 0, AmuletDef.Rarity.RARE: 0, AmuletDef.Rarity.LEGENDARY: 0}
	var shop := _shop(9)
	var st := _state(0)
	for i in 5000:
		shop.open(st)
		counts[shop.offers[0].rarity] += 1
	assert_almost_eq(counts[AmuletDef.Rarity.COMMON] / 5000.0, 0.6, 0.03)
	assert_almost_eq(counts[AmuletDef.Rarity.RARE] / 5000.0, 0.3, 0.03)
	assert_almost_eq(counts[AmuletDef.Rarity.LEGENDARY] / 5000.0, 0.1, 0.03)
