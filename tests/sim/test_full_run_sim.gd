extends GutTest
## Runs completas por RunController jugando Truco de verdad. El jugador es un
## DealerBrain con rasgos promedio y sin trampas: un jugador "medio" que no acusa.
## También mide cuánto gana ese jugador contra cada ronda, para calibrar la V.

const META_PATH := "user://test_meta_full_run.json"
const RUNS := 50
const MATCHES_PER_ROUND := 120
const MAX_ACTIONS := 4000
const MAX_STEPS_PER_HAND := 80
const P := RunController.Phase
const VALID_PHASES: Array[RunController.Phase] = [P.BAR, P.MATCH, P.SHOP, P.BILL_HAND, P.FREE,
	P.DEAD, P.RETIRED, P.CONDEMNED]
const PLAYER_TRAITS := {
	"id": "jugador", "aggression": 0.5, "lying": 0.3, "cheating": 0.0,
	"stubbornness": 0.5, "tell_reliability": 0.5, "cheat_budget": 0,
}

var _economy: Economy


func before_all() -> void:
	_economy = Economy.load_from()


func after_all() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(META_PATH))


func _player_brain(seed: int) -> DealerBrain:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var brain := DealerBrain.new(RivalProfile.from_dict(PLAYER_TRAITS), rng)
	brain.start_match()
	return brain


## Juega la mano en curso hasta que termine. Devuelve false si se trabó.
func _play_hand(t: CheatTable, player: DealerBrain) -> bool:
	var steps := 0
	while not t.truco_match.hand.is_over() and t.truco_match.winner() == -1:
		steps += 1
		if steps > MAX_STEPS_PER_HAND:
			return false
		if t.is_dealer_turn():
			t.dealer_step()
		else:
			var events := t.player_action(player.choose(HandView.new(t.truco_match.hand, 0)))
			player.observe(events, 0)
	return true


## Juega el partido entero. Devuelve false si se trabó.
func _play_match(rc: RunController, player: DealerBrain) -> bool:
	var t := rc.table()
	player.start_match()
	while t.truco_match.winner() == -1:
		rc.systems.start_hand()
		if not _play_hand(t, player):
			return false
	return true


## Devuelve la cantidad de acciones de la run, o -1 si se trabó.
func _play_run(rc: RunController, player: DealerBrain) -> int:
	var actions := 0
	rc.start_run(&"normal")
	while not rc.phase in [P.DEAD, P.RETIRED, P.CONDEMNED]:
		assert_true(rc.phase in VALID_PHASES)
		assert_gte(rc.state.money, 0)
		actions += 1
		if actions > MAX_ACTIONS:
			return -1
		match rc.phase:
			P.BAR:
				rc.enter_match()
			P.MATCH:
				if not _play_match(rc, player):
					return -1
				rc.finish_match()
			P.SHOP:
				_buy_safe(rc)
				rc.next_round()
			P.BILL_HAND:
				rc.systems.start_hand()
				if not _play_hand(rc.table(), player):
					return -1
				rc.finish_bill_hand()
			P.FREE:
				rc.retire()
	return actions


func _buy_safe(rc: RunController) -> void:
	var next_entry := _economy.entry(rc.state.round + 1)
	for i in range(rc.shop.offers.size() - 1, -1, -1):
		if rc.state.money - rc.shop.price_of(rc.shop.offers[i], rc.state) >= next_entry:
			rc.buy(i)


func test_runs_completas_no_se_traban() -> void:
	var meta := MetaState.new()
	var best_round := 0
	var retired := 0
	for n in RUNS:
		var rc := RunController.new(_economy, meta, 500 + n, META_PATH)
		var actions := _play_run(rc, _player_brain(900 + n))
		assert_ne(actions, -1, "la run %d se trabó" % n)
		assert_gte(rc.state.money, 0)
		best_round = maxi(best_round, rc.state.round)
		if rc.phase == P.RETIRED:
			retired += 1
		if rc.phase == P.DEAD and not rc.legacy_choices().is_empty():
			rc.choose_legacy(rc.legacy_choices()[0])
	var saved := MetaState.load_from(META_PATH)
	assert_eq(saved.runs_played, RUNS)
	gut.p("jugador medio: mejor ronda %d, retirados %d de %d; deuda acumulada %d" % [best_round, retired, RUNS, saved.debt])


## Cuánto gana el jugador medio contra el rival de cada ronda, sin amuletos.
func test_victoria_por_ronda() -> void:
	var rates: Array[String] = []
	for r in range(1, _economy.rounds_total() + 1):
		var wins := 0
		for n in MATCHES_PER_ROUND:
			var rc := RunController.new(_economy, MetaState.new(), 3000 + n * 17 + r, META_PATH)
			rc.start_run(&"normal")
			rc.state.round = r
			rc.state.money = 1000000
			rc.enter_match()
			assert_true(_play_match(rc, _player_brain(7000 + n)), "partido trabado en la ronda %d" % r)
			if rc.table().truco_match.winner() == 0:
				wins += 1
		rates.append("R%d %s %.2f" % [r, RivalCatalog.RUN_ORDER[r - 1], float(wins) / MATCHES_PER_ROUND])
	gut.p("victoria del jugador medio: " + " | ".join(rates))
	pass_test("tabla impresa")
