extends GutTest
## Simulación de economía sin Truco: cada partido se gana con probabilidad p
## (más un poco por cada amuleto equipado). Usa RunState, Shop, Prize y Economy
## reales, así que mide la economía tal como está en data/economy.json.

enum Policy { NONE, SAFE, GREEDY }

const SEED := 99
const RUNS := 2000
const MAX_ROUNDS := 20
const AMULET_BONUS := 0.03
const MAX_P := 0.95
const FLAWLESS_CHANCE := 0.15
const UNDETECTED_CHEAT_CHANCE := 0.2
const CALLED_ENVIDO_CHANCE := 0.5
const P_VALUES: Array[float] = [0.5, 0.7, 0.85]

var _economy: Economy
var _defs: Dictionary
var _normal: RunDeck


func before_all() -> void:
	_economy = Economy.load_from()
	_defs = AmuletDef.load_all()
	_normal = RunDeck.load_all()[&"normal"]


## Una run. Devuelve {reached: bool, round: int (ronda en la que llegó o murió), money_by_round: Array}.
func _run(p: float, policy: Policy, rng: RandomNumberGenerator) -> Dictionary:
	var st := RunState.new()
	st.money = _economy.start_money
	st.deck = _normal
	var shop := Shop.new(_economy, _defs, rng)
	var money_by_round: Array = []
	while st.round <= MAX_ROUNDS:
		if not st.pay_entry(_economy):
			return {"reached": false, "round": st.round, "money_by_round": money_by_round, "broke": true}
		var p_win := minf(p + AMULET_BONUS * st.loadout.equipped().size(), MAX_P)
		if rng.randf() >= p_win:
			return {"reached": false, "round": st.round, "money_by_round": money_by_round, "broke": false}
		var prize := Prize.compute(_economy.base_prize(st.round),
			0 if rng.randf() < FLAWLESS_CHANCE else 5,
			1 if rng.randf() < UNDETECTED_CHEAT_CHANCE else 0, 0,
			rng.randf() < CALLED_ENVIDO_CHANCE, st.loadout, st.deck, _economy)
		st.collect_prize(prize["total"], _economy)
		money_by_round.append(st.money)
		if st.money >= _economy.goal:
			return {"reached": true, "round": st.round, "money_by_round": money_by_round, "broke": false}
		shop.open(st)
		_shop(policy, shop, st)
		st.round += 1
	return {"reached": false, "round": st.round, "money_by_round": money_by_round, "broke": false}


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


func _simulate(p: float, policy: Policy) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED + int(p * 100) + policy * 1000
	var reached := 0
	var broke := 0
	var rounds_reached: Array = []
	var death_rounds := 0
	for i in RUNS:
		var r := _run(p, policy, rng)
		if r["reached"]:
			reached += 1
			rounds_reached.append(r["round"])
		else:
			death_rounds += r["round"]
			if r["broke"]:
				broke += 1
	var dead := RUNS - reached
	return {
		"reach_rate": float(reached) / RUNS,
		"broke_rate": float(broke) / RUNS,
		"avg_death_round": float(death_rounds) / maxi(dead, 1),
		"rounds_reached": rounds_reached,
	}


func _round_histogram(rounds: Array) -> String:
	var counts := {}
	for r in rounds:
		counts[r] = counts.get(r, 0) + 1
	var keys := counts.keys()
	keys.sort()
	return ", ".join(keys.map(func(k: int) -> String: return "R%d: %d" % [k, counts[k]]))


func test_tabla_de_economia() -> void:
	gut.p("política | p | llega a 10M | sin plata para entrar | ronda media de muerte | ronda en que llega")
	for policy in [Policy.NONE, Policy.SAFE, Policy.GREEDY]:
		for p in P_VALUES:
			var s := _simulate(p, policy)
			gut.p("%s | %.2f | %.1f%% | %.1f%% | %.1f | %s" % [Policy.keys()[policy], p, s["reach_rate"] * 100,
				s["broke_rate"] * 100, s["avg_death_round"], _round_histogram(s["rounds_reached"])])
	pass_test("tabla impresa")


func test_escalera_sola_no_alcanza() -> void:
	assert_lt(_simulate(0.7, Policy.NONE)["reach_rate"], 0.10)


func test_comprar_ayuda() -> void:
	var none: float = _simulate(0.7, Policy.NONE)["reach_rate"]
	var best := maxf(_simulate(0.7, Policy.SAFE)["reach_rate"], _simulate(0.7, Policy.GREEDY)["reach_rate"])
	assert_gt(best, none)
