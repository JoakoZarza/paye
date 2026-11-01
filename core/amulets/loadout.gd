class_name Loadout
extends RefCounted
## Administra los amuletos equipados y sus cargas por partido.

const SLOTS := 4
const RED_RIBBON_DISCOUNT := 0.2
const TRAIN_COIN_MULTIPLIER := 1.5

var _amulets: Dictionary = {}
var _charges: Dictionary = {}


func equip(def: AmuletDef) -> bool:
	if def == null or _amulets.size() >= SLOTS or _amulets.has(def.id):
		return false
	_amulets[def.id] = def
	_charges[def.id] = def.charges
	return true


func unequip(id: StringName) -> AmuletDef:
	if not _amulets.has(id):
		return null
	var def: AmuletDef = _amulets[id]
	_amulets.erase(id)
	_charges.erase(id)
	return def


func has(id: StringName) -> bool:
	return _amulets.has(id)


func charges_left(id: StringName) -> int:
	return int(_charges.get(id, 0))


func spend(id: StringName) -> bool:
	if not _amulets.has(id):
		return false
	var def: AmuletDef = _amulets[id]
	var remaining: int = charges_left(id)
	if def.kind != AmuletDef.Kind.ACTIVE or remaining <= 0:
		return false
	_charges[id] = remaining - 1
	return true


func reset_charges() -> void:
	for id: Variant in _amulets:
		var def: AmuletDef = _amulets[id]
		_charges[id] = def.charges


func equipped() -> Array[AmuletDef]:
	var result: Array[AmuletDef] = []
	for id: Variant in _amulets:
		result.append(_amulets[id])
	return result


func shop_price_multiplier() -> float:
	if has(&"red_ribbon"):
		return 1.0 - RED_RIBBON_DISCOUNT
	return 1.0


func prize_multiplier(player_called_envido: bool) -> float:
	if has(&"train_coin") and not player_called_envido:
		return TRAIN_COIN_MULTIPLIER
	return 1.0
