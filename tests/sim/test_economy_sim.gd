extends GutTest
## Simulación de economía sin Truco, con la estructura v2: 9 rondas, una
## probabilidad de ganar por ronda (la curva en V), tienda creciente y la cuenta
## final con la mano contra el Gualicho. Usa RunState, Shop, Prize y Economy
## reales, así que mide la economía tal como está en data/economy.json.

enum Policy { NONE, SAFE, GREEDY }
enum Outcome { FREE_PAID, FREE_SOLD, FREE_HAND, DIED_HAND, DIED_MATCH, DIED_BROKE }

const SEED := 99
const RUNS := 4000
## Probabilidad de ganar cada ronda con un jugador promedio (DISENO §6: la V).
const WIN_CURVE: Array[float] = [0.55, 0.8, 0.7, 0.85, 0.85, 0.65, 0.6, 0.8, 0.5]
const GUALICHO_WIN := 0.45
const AMULET_BONUS := 0.03
const MAX_P := 0.95
const FLAWLESS_CHANCE := 0.15
const UNDETECTED_CHEAT_CHANCE := 0.2
const CALLED_ENVIDO_CHANCE := 0.5
## Deudas arrastradas de runs anteriores para ver cuándo aparece "La cuenta".
const START_DEBTS: Array[int] = [10000, 40000, 100000]

var _economy: Economy
var _defs: Dictionary
var _normal: RunDeck


func before_all() -> void:
	_economy = Economy.load_from()
	_defs = AmuletDef.load_all()
	_normal = RunDeck.load_all()[&"normal"]


## Una run. Devuelve {outcome, round, money_by_round, amulets}.
func _run(policy: Policy, rng: RandomNumberGenerator, start_debt: int) -> Dictionary:
	var st := RunState.new()
	st.money = _economy.start_money
	st.debt = start_debt
	st.deck = _normal
	var shop := Shop.new(_economy, _defs, rng)
	var money_by_round: Array[int] = []
	var result := func(outcome: Outcome) -> Dictionary:
		return {"outcome": outcome, "round": st.round, "money_by_round": money_by_round,
			"amulets": st.loadout.equipped().size(), "fiado": st.fiado}
	while true:
		if not st.pay_entry(_economy):
			return result.call(Outcome.DIED_BROKE)
		var p_win := minf(WIN_CURVE[st.round - 1] + AMULET_BONUS * st.loadout.equipped().size(), MAX_P)
		if rng.randf() >= p_win:
			return result.call(Outcome.DIED_MATCH)
		var final := _economy.is_final(st.round)
		var prize := Prize.compute(_economy.base_prize(st.round),
			0 if rng.randf() < FLAWLESS_CHANCE else 5,
			1 if rng.randf() < UNDETECTED_CHEAT_CHANCE else 0, 0,
			rng.randf() < CALLED_ENVIDO_CHANCE, st.loadout, st.deck, _economy, final)
		st.collect_prize(prize["total"])
		money_by_round.append(st.money)
		if final:
			return result.call(_settle(st, rng))
		shop.open(st)
		_shop(policy, shop, st)
		st.round += 1
	return {}


## Misma lógica que RunController._settle_bill, sin eventos.
func _settle(st: RunState, rng: RandomNumberGenerator) -> Outcome:
	var bill := st.bill(_economy)
	if st.money >= bill:
		return Outcome.FREE_PAID
	for def in st.loadout.equipped():
		st.money += _economy.sell_value(st.paid_for.get(def.id, 0))
	if st.money >= bill:
		return Outcome.FREE_SOLD
	return Outcome.FREE_HAND if rng.randf() < GUALICHO_WIN else Outcome.DIED_HAND


## SAFE: compra la oferta más barata si después le sigue alcanzando para la
## próxima entrada, sin fiado. GREEDY: compra todo lo que puede, fiado incluido.
func _shop(policy: Policy, shop: Shop, st: RunState) -> void:
	if policy == Policy.NONE:
		return
	var bought := true
	while bought and not shop.offers.is_empty():
		bought = false
		var cheapest := 0
		for i in shop.offers.size():
			if shop.price_of(shop.offers[i], st) < shop.price_of(shop.offers[cheapest], st):
				cheapest = i
		var price := shop.price_of(shop.offers[cheapest], st)
		var next_entry := _economy.entry(st.round + 1)
		if policy == Policy.SAFE and st.money - price < next_entry:
			return
		bought = shop.buy(cheapest, st)["ok"]


func _simulate(policy: Policy, start_debt: int = 0) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED + policy * 1000
	var outcomes := {}
	for o in Outcome.values():
		outcomes[o] = 0
	var deaths_by_round: Array[int] = []
	deaths_by_round.resize(_economy.rounds_total() + 1)
	var money: Array = []
	for r in _economy.rounds_total():
		money.append([])
	var amulets := 0
	var fiado_at_final: Array = []
	for i in RUNS:
		var r := _run(policy, rng, start_debt)
		outcomes[r["outcome"]] += 1
		if r["outcome"] in [Outcome.DIED_MATCH, Outcome.DIED_BROKE]:
			deaths_by_round[r["round"]] += 1
		var by_round: Array[int] = r["money_by_round"]
		for k in by_round.size():
			money[k].append(by_round[k])
		amulets += r["amulets"]
		if r["outcome"] in [Outcome.FREE_PAID, Outcome.FREE_SOLD, Outcome.FREE_HAND, Outcome.DIED_HAND]:
			fiado_at_final.append(r["fiado"])
	var free: int = outcomes[Outcome.FREE_PAID] + outcomes[Outcome.FREE_SOLD] + outcomes[Outcome.FREE_HAND]
	return {
		"free_rate": float(free) / RUNS,
		"outcomes": outcomes,
		"deaths_by_round": deaths_by_round,
		"median_money": money.map(func(a: Array) -> int: return _median(a)),
		"avg_amulets": float(amulets) / RUNS,
		"median_fiado_at_final": _median(fiado_at_final),
	}


func _median(values: Array) -> int:
	if values.is_empty():
		return 0
	var sorted := values.duplicate()
	sorted.sort()
	return sorted[sorted.size() / 2]


func _pct(n: int) -> String:
	return "%.1f%%" % (100.0 * n / RUNS)


func test_tabla_de_economia() -> void:
	gut.p("curva de victoria por ronda: %s; mano del Gualicho: %.2f" % [str(WIN_CURVE), GUALICHO_WIN])
	for policy in [Policy.NONE, Policy.SAFE, Policy.GREEDY]:
		var s := _simulate(policy)
		var o: Dictionary = s["outcomes"]
		gut.p("== %s: libres %.1f%% (pagó %s, vendiendo %s, mano ganada %s) | muere en la mano %s | amuletos medios %.2f | fiado mediano en la final %d" % [
			Policy.keys()[policy], s["free_rate"] * 100, _pct(o[Outcome.FREE_PAID]),
			_pct(o[Outcome.FREE_SOLD]), _pct(o[Outcome.FREE_HAND]), _pct(o[Outcome.DIED_HAND]),
			s["avg_amulets"], s["median_fiado_at_final"]])
		var deaths: Array[int] = s["deaths_by_round"]
		var rows: Array[String] = []
		for r in range(1, _economy.rounds_total() + 1):
			rows.append("R%d muere %s, plata mediana %d" % [r, _pct(deaths[r]), s["median_money"][r - 1]])
		gut.p("   " + " | ".join(rows))
		gut.p("   sin plata para entrar: %s" % _pct(o[Outcome.DIED_BROKE]))
	pass_test("tabla impresa")


func test_tabla_con_deuda_arrastrada() -> void:
	gut.p("deuda arrastrada | política | libres | pagó | vendiendo | mano ganada | muere en la mano")
	for debt in START_DEBTS:
		for policy in [Policy.SAFE, Policy.GREEDY]:
			var s := _simulate(policy, debt)
			var o: Dictionary = s["outcomes"]
			gut.p("%d | %s | %.1f%% | %s | %s | %s | %s" % [debt, Policy.keys()[policy], s["free_rate"] * 100,
				_pct(o[Outcome.FREE_PAID]), _pct(o[Outcome.FREE_SOLD]), _pct(o[Outcome.FREE_HAND]),
				_pct(o[Outcome.DIED_HAND])])
	pass_test("tabla impresa")