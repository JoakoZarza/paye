class_name Economy extends RefCounted
## Lee y consulta los valores de la economía de una run. Las rondas son una
## tabla explícita para poder dibujar la curva en V a mano (DISENO §7).

var start_money: int = 135
## Una entrada por ronda: {"entry": int, "prize": int, "points": int}.
var rounds: Array[Dictionary] = []
var debt_base: int = 10000000
var shop_offers: int = 3
var shop_growth: float = 0.25
var reroll_base: float = 0.10
var reroll_step: float = 0.05
var sell_ratio: float = 0.5
var rarity_price: Dictionary = {"COMMON": 0.3, "RARE": 0.6, "LEGENDARY": 1.2}
var rarity_weight: Dictionary = {"COMMON": 0.6, "RARE": 0.3, "LEGENDARY": 0.1}
var fiado_limit: float = 2.0
var flawless_multiplier: float = 2.0
var undetected_cheat_multiplier: float = 1.5

const PRICE_EPSILON := 0.000001


static func load_from(path: String = "res://data/economy.json") -> Economy:
	var economy := Economy.new()
	if not FileAccess.file_exists(path):
		return economy
	var parsed: Variant = _parse_json(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return economy
	var data: Dictionary = parsed
	economy.start_money = int(data.get("start_money", economy.start_money))
	economy.rounds = _rounds(data.get("rounds", []))
	economy.debt_base = int(data.get("debt_base", economy.debt_base))
	economy.shop_offers = int(data.get("shop_offers", economy.shop_offers))
	economy.shop_growth = float(data.get("shop_growth", economy.shop_growth))
	economy.reroll_base = float(data.get("reroll_base", economy.reroll_base))
	economy.reroll_step = float(data.get("reroll_step", economy.reroll_step))
	economy.sell_ratio = float(data.get("sell_ratio", economy.sell_ratio))
	economy.rarity_price = _float_dictionary(data.get("rarity_price", economy.rarity_price))
	economy.rarity_weight = _float_dictionary(data.get("rarity_weight", economy.rarity_weight))
	economy.fiado_limit = float(data.get("fiado_limit", economy.fiado_limit))
	economy.flawless_multiplier = float(data.get("flawless_multiplier", economy.flawless_multiplier))
	economy.undetected_cheat_multiplier = float(data.get("undetected_cheat_multiplier", economy.undetected_cheat_multiplier))
	return economy


static func _rounds(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if value is Array:
		for item: Variant in value:
			if item is Dictionary:
				result.append({
					"entry": int(item.get("entry", 0)),
					"prize": int(item.get("prize", 0)),
					"points": int(item.get("points", 15)),
				})
	return result


static func _float_dictionary(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if value is Dictionary:
		for key: Variant in value:
			result[String(key)] = float(value[key])
	return result


func rounds_total() -> int:
	return rounds.size()


func is_final(round: int) -> bool:
	return round == rounds_total()


## Fuera de la tabla se usa la ronda más cercana.
func _row(round: int) -> Dictionary:
	if rounds.is_empty():
		return {"entry": 0, "prize": 0, "points": 15}
	return rounds[clampi(round, 1, rounds.size()) - 1]


func entry(round: int) -> int:
	return _row(round)["entry"]


func base_prize(round: int) -> int:
	return _row(round)["prize"]


func target_points(round: int) -> int:
	return _row(round)["points"]


## Los precios de la tienda toman como referencia la entrada siguiente.
func _reference_entry(round: int) -> int:
	return entry(mini(round + 1, rounds_total()))


## purchases: amuletos ya comprados en la run (cada uno encarece shop_growth).
## Un solo redondeo al final para que los descuentos no se coman pesos.
func price(rarity: AmuletDef.Rarity, round: int, purchases: int = 0, multiplier: float = 1.0) -> int:
	var rarity_name: String = AmuletDef.Rarity.keys()[rarity]
	var growth := 1.0 + shop_growth * float(purchases)
	var raw := float(_reference_entry(round)) * float(rarity_price.get(rarity_name, 0.0)) * growth * multiplier
	# El épsilon evita que 89,999… por error de float pierda un peso.
	return floori(raw + PRICE_EPSILON)


func reroll_cost(round: int, rerolls_done: int) -> int:
	# En centésimos enteros: 0.10 + 0.05 * k en float da 0.3499... y redondea mal.
	var percent := roundi((reroll_base + reroll_step * float(rerolls_done)) * 100.0)
	return _reference_entry(round) * percent / 100


## JSON.new().parse no ensucia el log con un error de motor si el archivo está mal.
static func _parse_json(text: String) -> Variant:
	var json := JSON.new()
	return json.data if json.parse(text) == OK else null


func sell_value(paid: int) -> int:
	return floori(float(paid) * sell_ratio)
