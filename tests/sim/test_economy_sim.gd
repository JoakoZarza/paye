extends GutTest
## Simulación de economía sin Truco, con la estructura v2: 9 rondas, una
## probabilidad de ganar por ronda (la curva en V), tienda creciente y la cuenta
## final con la mano contra el Gualicho. Plan 5c: propina, interés y retención
## del fiado, mejoras de amuletos y una mano más. Usa RunState, Shop, Prize y Economy
## reales, así que mide la economía tal como está en data/economy.json.

enum Policy { NONE, SAFE, GREEDY }
enum Outcome { FREE_PAID, FREE_SOLD, FREE_HAND, DIED_HAND, DIED_MATCH, DIED_BROKE }

const SEED := 99
const RUNS := 4000
## Victoria por ronda medida en test_full_run_sim (jugador IA medio, sin acusar).
const WIN_CURVE: Array[float] = [0.44, 0.61, 0.53, 0.53, 0.57, 0.43, 0.42, 0.53, 0.39]
## Ventaja de un humano que lee pistas y acusa trampas, sumada a cada ronda.
const SKILL_EDGES: Array[float] = [0.15, 0.25]
const GUALICHO_WIN := 0.45
const AMULET_BONUS := 0.03
const MAX_P := 0.95
const FLAWLESS_CHANCE := 0.15
const UNDETECTED_CHEAT_CHANCE := 0.2
const CALLED_ENVIDO_CHANCE := 0.5
## Deudas arrastradas de runs anteriores para ver cuándo aparece "La cuenta".
const START_DEBTS: Array[int] = [10000, 40000, 100000]
const ONE_MORE_WIN := 0.5
const ONE_MORE_FRACTION := 0.5

var _economy: Economy
var _defs: Dictionary
var _normal: RunDeck


func before_all() -> void:
	_economy = Economy.load_from()
	_defs = AmuletDef.load_all()
	_normal = RunDeck.load_all()[&"normal"]


## Una run. Devuelve {outcome, round, money_by_round, amulets}.
## bold: juega una mano más al 50% cuando le sobran 3 entradas siguientes.
func _run(policy: Policy, rng: RandomNumberGenerator, start_debt: int, edge: float, bold := false) -> Dictionary:
	var st := RunState.new()
	st.money = _economy.start_money
	st.debt = start_debt
	st.deck = _normal
	var shop := Shop.new(_economy, _defs, rng)
	var money_by_round: Array[int] = []
	var fiado_by_round: Array[int] = []
	var result := func(outcome: Outcome) -> Dictionary:
		return {"outcome": outcome, "round": st.round, "money_by_round": money_by_round, "fiado_by_round": fiado_by_round,
			"amulets": st.loadout.equipped().size(), "fiado": st.fiado}
	while true:
		if not st.pay_entry(_economy):
			return result.call(Outcome.DIED_BROKE)
		var p_win := minf(WIN_CURVE[st.round - 1] + edge + AMULET_BONUS * _levels(st), MAX_P)
		if rng.randf() >= p_win:
			return result.call(Outcome.DIED_MATCH)
		var final := _economy.is_final(st.round)
		var prize := Prize.compute(_economy.base_prize(st.round),
			0 if rng.randf() < FLAWLESS_CHANCE else 5,
			1 if rng.randf() < UNDETECTED_CHEAT_CHANCE else 0, 0,
			rng.randf() < CALLED_ENVIDO_CHANCE, st.loadout, st.deck, _economy, final)
		var kept: int = st.collect_prize(prize["total"], _economy, final)["kept"]
		if final:
			money_by_round.append(st.money)
			fiado_by_round.append(st.fiado)
			return result.call(_settle(st, rng))
		if bold and st.money > 3 * _economy.entry(st.round + 1):
			var stake := floori(kept * ONE_MORE_FRACTION)
			st.money += stake if rng.randf() < ONE_MORE_WIN else -stake
		money_by_round.append(st.money)
		fiado_by_round.append(st.fiado)
		shop.open(st)
		_shop(policy, shop, st)
		st.round += 1
		st.apply_interest(_economy)
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
	# Una mejora por tienda, al amuleto de mejora más barata.
	var target := &""
	for def in st.loadout.equipped():
		var p := shop.upgrade_price(def.id, st)
		if p >= 0 and (target == &"" or p < shop.upgrade_price(target, st)):
			target = def.id
	if target == &"":
		return
	if policy == Policy.SAFE and st.money - shop.upgrade_price(target, st) < _economy.entry(st.round + 1):
		return
	shop.upgrade(target, st)


func _levels(st: RunState) -> int:
	var total := 0
	for def in st.loadout.equipped():
		total += st.loadout.level(def.id)
	return total


func _simulate(policy: Policy, start_debt: int = 0, edge: float = SKILL_EDGES[0], bold := false) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED + policy * 1000
	var outcomes := {}
	for o in Outcome.values():
		outcomes[o] = 0
	var deaths_by_round: Array[int] = []
	deaths_by_round.resize(_economy.rounds_total() + 1)
	var money: Array = []
	var fiados: Array = []
	for r in _economy.rounds_total():
		money.append([])
		fiados.append([])
	var amulets := 0
	var fiado_at_final: Array = []
	for i in RUNS:
		var r := _run(policy, rng, start_debt, edge, bold)
		outcomes[r["outcome"]] += 1
		if r["outcome"] in [Outcome.DIED_MATCH, Outcome.DIED_BROKE]:
			deaths_by_round[r["round"]] += 1
		var by_round: Array[int] = r["money_by_round"]
		for k in by_round.size():
			money[k].append(by_round[k])
		var fiado_rounds: Array[int] = r["fiado_by_round"]
		for k in fiado_rounds.size():
			fiados[k].append(fiado_rounds[k])
		amulets += r["amulets"]
		if r["outcome"] in [Outcome.FREE_PAID, Outcome.FREE_SOLD, Outcome.FREE_HAND, Outcome.DIED_HAND]:
			fiado_at_final.append(r["fiado"])
	var free: int = outcomes[Outcome.FREE_PAID] + outcomes[Outcome.FREE_SOLD] + outcomes[Outcome.FREE_HAND]
	return {
		"free_rate": float(free) / RUNS,
		"outcomes": outcomes,
		"deaths_by_round": deaths_by_round,
		"median_money": money.map(func(a: Array) -> int: return _median(a)),
		"median_fiado": fiados.map(func(a: Array) -> int: return _median(a)),
		"p90_money": money.map(func(a: Array) -> int: return _percentile(a, 0.9)),
		"avg_amulets": float(amulets) / RUNS,
		"median_fiado_at_final": _median(fiado_at_final),
	}


func _median(values: Array) -> int:
	return _percentile(values, 0.5)


func _percentile(values: Array, q: float) -> int:
	if values.is_empty():
		return 0
	var sorted := values.duplicate()
	sorted.sort()
	return sorted[mini(sorted.size() - 1, int(sorted.size() * q))]


func _pct(n: int) -> String:
	return "%.1f%%" % (100.0 * n / RUNS)


func test_tabla_de_economia() -> void:
	gut.p("curva de victoria por ronda: %s; mano del Gualicho: %.2f" % [str(WIN_CURVE), GUALICHO_WIN])
	for edge in SKILL_EDGES:
		gut.p("### ventaja del jugador +%.2f" % edge)
		_print_policies(edge)
	pass_test("tabla impresa")


func _print_policies(edge: float) -> void:
	for row in [[Policy.NONE, false], [Policy.SAFE, false], [Policy.GREEDY, false], [Policy.GREEDY, true]]:
		var policy: Policy = row[0]
		var s := _simulate(policy, 0, edge, row[1])
		var o: Dictionary = s["outcomes"]
		gut.p("== %s%s: libres %.1f%% (pagó %s, vendiendo %s, mano ganada %s) | muere en la mano %s | amuletos medios %.2f | fiado mediano en la final %d" % [
			Policy.keys()[policy], " + una mano más" if row[1] else "", s["free_rate"] * 100, _pct(o[Outcome.FREE_PAID]),
			_pct(o[Outcome.FREE_SOLD]), _pct(o[Outcome.FREE_HAND]), _pct(o[Outcome.DIED_HAND]),
			s["avg_amulets"], s["median_fiado_at_final"]])
		var deaths: Array[int] = s["deaths_by_round"]
		var rows: Array[String] = []
		for r in range(1, _economy.rounds_total() + 1):
			rows.append("R%d muere %s, plata %d (p90 %d), fiado %d" % [r, _pct(deaths[r]), s["median_money"][r - 1],
				s["p90_money"][r - 1], s["median_fiado"][r - 1]])
		gut.p("   " + " | ".join(rows))
		gut.p("   sin plata para entrar: %s" % _pct(o[Outcome.DIED_BROKE]))


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