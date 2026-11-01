extends GutTest
## Runs completas por RunController jugando Truco de verdad, con un jugador de
## reglas simples y una política de compra segura.

const META_PATH := "user://test_meta_full_run.json"
const RUNS := 50
const MAX_ACTIONS := 2000
const MAX_STEPS_PER_HAND := 80
const T := TrucoAction.Type
const VALID_PHASES: Array[RunController.Phase] = [RunController.Phase.BAR, RunController.Phase.MATCH,
	RunController.Phase.SHOP, RunController.Phase.DEAD, RunController.Phase.RETIRED]

var _economy: Economy


func before_all() -> void:
	_economy = Economy.load_from()


func after_all() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(META_PATH))


## Reglas simples: juega la carta más alta, quiere con buena mano, declara su
## tanto real y acepta el tanto del dealer.
func _player_action(hand: TrucoHand) -> TrucoAction:
	var legal := hand.legal_actions()
	var find := func(type: T) -> TrucoAction:
		for a in legal:
			if a.type == type:
				return a
		return null
	var best := 0
	var top := 0
	for i in hand.cards[0].size():
		var rank: int = hand.cards[0][i].truco_rank()
		if rank > best:
			best = rank
			top = i
	match hand.phase:
		TrucoHand.Phase.PLAYING:
			return TrucoAction.make(T.PLAY_CARD, 0, top)
		TrucoHand.Phase.TANTO_DECLARATION:
			var a := TrucoAction.make(T.DECLARE_TANTO, 0, -1, hand.own_tanto(0))
			return a if legal.any(func(l: TrucoAction) -> bool: return l.equals(a)) else legal[0]
		TrucoHand.Phase.SHOW_DECISION:
			return find.call(T.ACCEPT_TANTO)
	var answer: TrucoAction = find.call(T.QUIERO) if best >= 10 else find.call(T.NO_QUIERO)
	return answer if answer != null else legal[0]


## Devuelve la cantidad de acciones de la run, o -1 si se trabó.
func _play_run(rc: RunController) -> int:
	var actions := 0
	rc.start_run(&"normal")
	while rc.phase != RunController.Phase.DEAD and rc.phase != RunController.Phase.RETIRED:
		assert_true(rc.phase in VALID_PHASES)
		assert_gte(rc.state.money, 0)
		actions += 1
		if actions > MAX_ACTIONS:
			return -1
		match rc.phase:
			RunController.Phase.BAR:
				rc.enter_match()
			RunController.Phase.MATCH:
				var t := rc.table()
				while t.truco_match.winner() == -1:
					rc.systems.start_hand()
					var steps := 0
					while not t.truco_match.hand.is_over() and t.truco_match.winner() == -1:
						steps += 1
						actions += 1
						if steps > MAX_STEPS_PER_HAND:
							return -1
						if t.is_dealer_turn():
							t.dealer_step()
						else:
							t.player_action(_player_action(t.truco_match.hand))
				rc.finish_match()
			RunController.Phase.SHOP:
				if rc.can_retire():
					rc.retire()
					continue
				_buy_safe(rc)
				rc.next_round()
	return actions


func _buy_safe(rc: RunController) -> void:
	var next_entry := _economy.entry(rc.state.round + 1)
	for i in range(rc.shop.offers.size() - 1, -1, -1):
		if rc.state.money - rc.shop.price_of(rc.shop.offers[i], rc.state) >= next_entry:
			rc.buy(i)


func test_runs_completas_no_se_traban() -> void:
	var meta := MetaState.new()
	var best_round := 0
	for n in RUNS:
		var rc := RunController.new(_economy, meta, 500 + n, META_PATH)
		var actions := _play_run(rc)
		assert_ne(actions, -1, "la run %d se trabó" % n)
		assert_gte(rc.state.money, 0)
		best_round = maxi(best_round, rc.state.round)
		if rc.phase == RunController.Phase.DEAD and not rc.legacy_choices().is_empty():
			rc.choose_legacy(rc.legacy_choices()[0])
	var saved := MetaState.load_from(META_PATH)
	assert_eq(saved.runs_played, RUNS)
	gut.p("jugador simple: mejor ronda alcanzada %d en %d runs; deuda acumulada %d" % [best_round, RUNS, saved.debt])
