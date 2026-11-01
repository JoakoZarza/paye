class_name Shop
extends RefCounted
## Tienda entre partidos: ofertas por rareza, compra con fiado, cambio de
## ofertas y venta. Ver DISENO §7.3 y §7.4.

var offers: Array[AmuletDef] = []
var rerolls := 0

var _economy: Economy
var _defs: Dictionary
var _rng: RandomNumberGenerator
var _premium := false


func _init(p_economy: Economy, p_defs: Dictionary, p_rng: RandomNumberGenerator) -> void:
	_economy = p_economy
	_defs = p_defs
	_rng = p_rng


## premium: tienda especial después de un jefe, solo raros y legendarios.
func open(state: RunState, premium: bool = false) -> void:
	rerolls = 0
	_premium = premium
	_generate(state)


func price_of(def: AmuletDef, state: RunState) -> int:
	return floori(_economy.price(def.rarity, state.round) * state.loadout.shop_price_multiplier())


func buy(index: int, state: RunState) -> Dictionary:
	if index < 0 or index >= offers.size():
		return _result(false, &"bad_index")
	if state.loadout.equipped().size() >= Loadout.SLOTS:
		return _result(false, &"no_slot")
	var def := offers[index]
	var price := price_of(def, state)
	# Comprar fiado nunca te deja sin la entrada siguiente (DISENO §7.4: "si sobrevivís").
	var reserve := _economy.entry(state.round + 1)
	var from_money := clampi(state.money - reserve, 0, price)
	var on_credit := price - from_money
	if on_credit > state.credit_available(_economy):
		return _result(false, &"no_credit")
	state.money -= from_money
	state.fiado += on_credit
	state.loadout.equip(def)
	state.paid_for[def.id] = price
	offers.remove_at(index)
	return {"ok": true, "reason": &"", "paid": from_money, "fiado": on_credit}


## Cambiar las ofertas se paga con plata, nunca fiado.
func reroll(state: RunState) -> bool:
	var cost := _economy.reroll_cost(state.round, rerolls)
	if state.money < cost:
		return false
	state.money -= cost
	rerolls += 1
	_generate(state)
	return true


func sell(id: StringName, state: RunState) -> int:
	if not state.loadout.has(id):
		return 0
	state.loadout.unequip(id)
	var value := _economy.sell_value(state.paid_for.get(id, 0))
	state.paid_for.erase(id)
	# Lo que se vende paga primero el fiado: vender no convierte deuda en plata.
	var to_fiado := mini(state.fiado, value)
	state.fiado -= to_fiado
	state.money += value - to_fiado
	return value


## Sortea la rareza con sus pesos entre las que tienen candidatos y después un
## amuleto de esa rareza. Nunca repite ni ofrece uno equipado.
func _generate(state: RunState) -> void:
	offers.clear()
	var pool: Array[AmuletDef] = []
	for def in _defs.values():
		if not state.loadout.has(def.id) and not (_premium and def.rarity == AmuletDef.Rarity.COMMON):
			pool.append(def)
	for i in _economy.shop_offers:
		if pool.is_empty():
			return
		var rarity := _pick_rarity(pool)
		var candidates := pool.filter(func(d: AmuletDef) -> bool: return d.rarity == rarity)
		var pick: AmuletDef = candidates[_rng.randi_range(0, candidates.size() - 1)]
		offers.append(pick)
		pool.erase(pick)


func _pick_rarity(pool: Array[AmuletDef]) -> AmuletDef.Rarity:
	var available: Array[AmuletDef.Rarity] = []
	var total := 0.0
	for def in pool:
		if not def.rarity in available:
			available.append(def.rarity)
			total += _weight(def.rarity)
	var roll := _rng.randf() * total
	for r in available:
		roll -= _weight(r)
		if roll <= 0.0:
			return r
	return available.back()


func _weight(r: AmuletDef.Rarity) -> float:
	return float(_economy.rarity_weight[AmuletDef.Rarity.keys()[r]])


func _result(ok: bool, reason: StringName) -> Dictionary:
	return {"ok": ok, "reason": reason, "paid": 0, "fiado": 0}
