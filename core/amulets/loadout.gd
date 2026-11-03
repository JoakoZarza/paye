class_name Loadout
extends RefCounted
## Administra los amuletos equipados y sus cargas por partido.

const SLOTS := 2
var _amulets: Dictionary = {}
var _charges: Dictionary = {}
var _levels: Dictionary = {}


func equip(def: AmuletDef) -> bool:
	if def == null or _amulets.size() >= SLOTS or _amulets.has(def.id):
		return false
	_amulets[def.id] = def
	_levels[def.id] = 1
	_charges[def.id] = int(def.value("charges", 1, def.charges))
	return true


func unequip(id: StringName) -> AmuletDef:
	if not _amulets.has(id):
		return null
	var def: AmuletDef = _amulets[id]
	_amulets.erase(id)
	_charges.erase(id)
	_levels.erase(id)
	return def


func has(id: StringName) -> bool:
	return _amulets.has(id)


func level(id: StringName) -> int:
	if not _amulets.has(id):
		return 0
	return int(_levels.get(id, 1))


func upgrade(id: StringName) -> bool:
	if not _amulets.has(id) or level(id) >= AmuletDef.MAX_LEVEL:
		return false
	_levels[id] = level(id) + 1
	var def: AmuletDef = _amulets[id]
	_charges[id] = int(def.value("charges", level(id), def.charges))
	return true


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
		_charges[id] = int(def.value("charges", level(StringName(id)), def.charges))


func equipped() -> Array[AmuletDef]:
	var result: Array[AmuletDef] = []
	for id: Variant in _amulets:
		result.append(_amulets[id])
	return result


func shop_price_multiplier() -> float:
	if has(&"red_ribbon"):
		var def: AmuletDef = _amulets[&"red_ribbon"]
		return float(def.value("price_multiplier", level(&"red_ribbon"), 1.0))
	return 1.0


func prize_multiplier(player_called_envido: bool) -> float:
	if has(&"train_coin") and not player_called_envido:
		var def: AmuletDef = _amulets[&"train_coin"]
		return float(def.value("prize_multiplier", level(&"train_coin"), 1.0))
	return 1.0


## Pone un amuleto equipado en un nivel (al sacarlo del guardarropas).
func set_level(id: StringName, value: int) -> void:
	if not _amulets.has(id):
		return
	while level(id) < mini(value, AmuletDef.MAX_LEVEL):
		upgrade(id)
