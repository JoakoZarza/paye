class_name Economy extends RefCounted
## Lee y consulta los valores de la economía de una run.

var start_money: int = 135
var base_entry: int = 100
var entry_multiplier: int = 3
var prize_factors: Array[float] = [6.0, 5.5, 5.0, 5.0, 4.5, 4.0, 4.0, 4.0, 3.5, 3.5, 3.5, 3.5]
var boss_rounds: Array[int] = [4, 8, 12]
var points_normal: int = 15
var points_boss: int = 30
var goal: int = 10000000
var shop_offers: int = 3
var reroll_base: float = 0.10
var reroll_step: float = 0.05
var sell_ratio: float = 0.5
var rarity_price: Dictionary = {"COMMON": 0.3, "RARE": 0.6, "LEGENDARY": 1.2}
var rarity_weight: Dictionary = {"COMMON": 0.6, "RARE": 0.3, "LEGENDARY": 0.1}
var fiado_limit: float = 2.0
var creditor_cut: float = 0.5
var flawless_multiplier: float = 2.0
var undetected_cheat_multiplier: float = 1.5


static func load_from(path: String = "res://data/economy.json") -> Economy:
	var economy := Economy.new()
	if not FileAccess.file_exists(path):
		return economy
	var parsed: Variant = _parse_json(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return economy
	var data: Dictionary = parsed
	economy.start_money = int(data.get("start_money", economy.start_money))
	economy.base_entry = int(data.get("base_entry", economy.base_entry))
	economy.entry_multiplier = int(data.get("entry_multiplier", economy.entry_multiplier))
	economy.prize_factors = _float_array(data.get("prize_factors", economy.prize_factors))
	economy.boss_rounds = _int_array(data.get("boss_rounds", economy.boss_rounds))
	economy.points_normal = int(data.get("points_normal", economy.points_normal))
	economy.points_boss = int(data.get("points_boss", economy.points_boss))
	economy.goal = int(data.get("goal", economy.goal))
	economy.shop_offers = int(data.get("shop_offers", economy.shop_offers))
	economy.reroll_base = float(data.get("reroll_base", economy.reroll_base))
	economy.reroll_step = float(data.get("reroll_step", economy.reroll_step))
	economy.sell_ratio = float(data.get("sell_ratio", economy.sell_ratio))
	economy.rarity_price = _float_dictionary(data.get("rarity_price", economy.rarity_price))
	economy.rarity_weight = _float_dictionary(data.get("rarity_weight", economy.rarity_weight))
	economy.fiado_limit = float(data.get("fiado_limit", economy.fiado_limit))
	economy.creditor_cut = float(data.get("creditor_cut", economy.creditor_cut))
	economy.flawless_multiplier = float(data.get("flawless_multiplier", economy.flawless_multiplier))
	economy.undetected_cheat_multiplier = float(data.get("undetected_cheat_multiplier", economy.undetected_cheat_multiplier))
	return economy


static func _float_array(value: Variant) -> Array[float]:
	var result: Array[float] = []
	if value is Array:
		for item: Variant in value:
			result.append(float(item))
	return result


static func _int_array(value: Variant) -> Array[int]:
	var result: Array[int] = []
	if value is Array:
		for item: Variant in value:
			result.append(int(item))
	return result


static func _float_dictionary(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if value is Dictionary:
		for key: Variant in value:
			result[String(key)] = float(value[key])
	return result


func entry(round: int) -> int:
	var result: int = base_entry
	for _step: int in range(maxi(round - 1, 0)):
		result *= entry_multiplier
	return result


func base_prize(round: int) -> int:
	if prize_factors.is_empty():
		return 0
	var factor_index: int = clampi(round, 1, prize_factors.size()) - 1
	return floori(float(entry(round)) * prize_factors[factor_index])


func is_boss(round: int) -> bool:
	return boss_rounds.has(round)


func target_points(round: int) -> int:
	return points_boss if is_boss(round) else points_normal


func price(rarity: AmuletDef.Rarity, round: int) -> int:
	var rarity_name: String = AmuletDef.Rarity.keys()[rarity]
	return floori(float(entry(round + 1)) * float(rarity_price.get(rarity_name, 0.0)))


func reroll_cost(round: int, rerolls_done: int) -> int:
	# En centésimos enteros: 0.10 + 0.05 * k en float da 0.3499... y redondea mal.
	var percent := roundi((reroll_base + reroll_step * float(rerolls_done)) * 100.0)
	return entry(round + 1) * percent / 100


## JSON.new().parse no ensucia el log con un error de motor si el archivo está mal.
static func _parse_json(text: String) -> Variant:
	var json := JSON.new()
	return json.data if json.parse(text) == OK else null


func sell_value(paid: int) -> int:
	return floori(float(paid) * sell_ratio)
