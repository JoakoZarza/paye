extends GutTest
## Partidos completos entre cerebros del dealer y contra un jugador al azar.

const SEED := 7
const MATCHES := 200
const MAX_ACTIONS_PER_HAND := 60
const MVP_RIVALS: Array[StringName] = [&"agresivo", &"mentiroso", &"tramposo"]

var _profiles: Dictionary
var _illegal := 0
var _long_hands := 0


func before_all() -> void:
	_profiles = RivalProfile.load_all("res://tests/fixtures/legacy_rivals.json")


func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


func _extreme(v: float) -> RivalProfile:
	return RivalProfile.from_dict({
		"id": "extremo", "aggression": v, "lying": v, "cheating": v,
		"stubbornness": v, "tell_reliability": v, "cheat_budget": 0,
	})


## brains[p] == null significa jugador al azar. Devuelve el ganador; si se pasa
## `log`, agrega cada acción del dealer como texto.
func _play_match(brains: Array, target: int, s: int, log: Array = []) -> int:
	var m := TrucoMatch.new(target, _rng(s))
	var picker := _rng(s + 1)
	for b in brains:
		if b != null:
			b.start_match()
	while m.winner() == -1:
		m.start_hand()
		var actions := 0
		while not m.hand.is_over():
			var p := m.hand.current_player()
			var a: TrucoAction
			if brains[p] == null:
				var legal := m.hand.legal_actions()
				a = legal[picker.randi_range(0, legal.size() - 1)]
			else:
				a = brains[p].choose(HandView.new(m.hand, p))
				log.append("%d:%d:%d:%d" % [p, a.type, a.card_index, a.value])
			var events := m.apply(a)
			if events[0].type == &"illegal_action":
				_illegal += 1
				return -1
			for q in 2:
				if brains[q] != null:
					brains[q].observe(events, q)
			actions += 1
			if actions > MAX_ACTIONS_PER_HAND:
				_long_hands += 1
				return -1
	return m.winner()


func _brain(id: StringName, s: int) -> DealerBrain:
	return DealerBrain.new(_profiles[id], _rng(s))


func _rate(stats: Dictionary, num: StringName, den: StringName) -> float:
	return float(stats[num]) / maxi(stats[den], 1)


func test_rivales_le_ganan_al_azar() -> void:
	for id in MVP_RIVALS:
		var wins := 0
		for n in MATCHES:
			# Alterna el asiento para que el sorteo del mano no favorezca a nadie.
			var seat := n % 2
			var brains: Array = [null, null]
			brains[seat] = _brain(id, SEED * 1000 + n)
			if _play_match(brains, 15, SEED + n) == seat:
				wins += 1
		var rate := float(wins) / MATCHES
		gut.p("%s contra azar: %.2f" % [id, rate])
		assert_gte(rate, 0.7, "%s gana %.2f contra el azar" % [id, rate])
	assert_eq(_illegal, 0)


func test_mentiroso_miente_mas_y_agresivo_canta_mas_truco() -> void:
	var liar := _brain(&"mentiroso", SEED)
	var aggro := _brain(&"agresivo", SEED + 1)
	var liar_wins := 0
	for n in MATCHES:
		# Cerebros persistentes: el humor y la memoria se acumulan como en una run.
		var brains: Array = [liar, aggro] if n % 2 == 0 else [aggro, liar]
		if brains[_play_match(brains, 15, SEED + n)] == liar:
			liar_wins += 1
	var liar_lies := _rate(liar.stats, &"lies", &"declarations")
	var aggro_lies := _rate(aggro.stats, &"lies", &"declarations")
	var liar_truco := _rate(liar.stats, &"truco_calls", &"truco_chances")
	var aggro_truco := _rate(aggro.stats, &"truco_calls", &"truco_chances")
	gut.p("mentira: mentiroso %.2f, agresivo %.2f" % [liar_lies, aggro_lies])
	gut.p("truco/oportunidad: mentiroso %.2f, agresivo %.2f" % [liar_truco, aggro_truco])
	gut.p("mentiroso gana %.2f contra agresivo" % [float(liar_wins) / MATCHES])
	assert_gt(liar_lies - aggro_lies, 0.15)
	assert_gt(aggro_truco, liar_truco)
	assert_eq(_illegal, 0)


func test_perfiles_extremos_no_se_traban() -> void:
	for n in 100:
		var brains: Array = [DealerBrain.new(_extreme(0.0), _rng(n)), DealerBrain.new(_extreme(1.0), _rng(n + 500))]
		_play_match(brains, 15, SEED + n)
	assert_eq(_illegal, 0)
	assert_eq(_long_hands, 0)


func test_determinismo() -> void:
	var runs: Array = []
	for run in 2:
		var log: Array = []
		for n in 20:
			var brains: Array = [_brain(&"tramposo", n), null]
			_play_match(brains, 15, SEED + n, log)
		runs.append(log)
	assert_gt(runs[0].size(), 0)
	assert_eq(runs[0], runs[1])
