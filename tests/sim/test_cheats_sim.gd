extends GutTest
## Partidos completos con trampas: el dealer contra un jugador al azar que acusa
## según una política.

enum Policy { NEVER, ATTENTIVE, RANDOM }

const SEED := 13
const MATCHES := 300
const RANDOM_ACCUSE_CHANCE := 0.05
const MAX_STEPS := 400

var _profiles: Dictionary
var _evidence_failures := 0
var _budget_failures := 0


func before_all() -> void:
	_profiles = RivalProfile.load_all("res://tests/fixtures/legacy_rivals.json")


func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


## Juega un partido a 15 y devuelve {winner, cheats}.
func _play(id: StringName, policy: Policy, s: int) -> Dictionary:
	var profile: RivalProfile = _profiles[id]
	var t := CheatTable.new(TrucoMatch.new(15, _rng(s)), DealerBrain.new(profile, _rng(s + 1)), 1, _rng(s + 2))
	t.start_match()
	var picker := _rng(s + 3)
	var cheats := 0
	var steps := 0
	while t.truco_match.winner() == -1 and steps < MAX_STEPS:
		t.start_hand()
		if t.active_cheat != null:
			if t.active_cheat.kind != Cheat.Kind.DUPLICATE and t.evidence().is_empty():
				_evidence_failures += 1
		while not t.truco_match.hand.is_over() and t.truco_match.winner() == -1 and steps < MAX_STEPS:
			steps += 1
			if t.is_dealer_turn():
				t.dealer_step()
				_check_duplicate(t)
				continue
			if _maybe_accuse(t, policy, picker):
				continue
			var legal := t.truco_match.hand.legal_actions()
			t.player_action(legal[picker.randi_range(0, legal.size() - 1)])
	cheats = t.cheats_applied
	if cheats > profile.cheat_budget:
		_budget_failures += 1
	return {"winner": t.truco_match.winner(), "cheats": cheats}


## Si la copia ya se jugó (su clave aparece dos veces), tiene que haber evidencia.
func _check_duplicate(t: CheatTable) -> void:
	var c := t.active_cheat
	if c == null or c.kind != Cheat.Kind.DUPLICATE or c.card_key == "":
		return
	var seen := 0
	for p in 2:
		for card in t.truco_match.hand.played[p]:
			if card.key() == c.card_key:
				seen += 1
	if seen >= 2 and t.evidence().is_empty():
		_evidence_failures += 1


func _maybe_accuse(t: CheatTable, policy: Policy, picker: RandomNumberGenerator) -> bool:
	if not t.can_accuse() or policy == Policy.NEVER:
		return false
	var ev := t.evidence()
	if policy == Policy.ATTENTIVE:
		if ev.is_empty():
			return false
		t.accuse(_accusation_for(ev[0]))
		return true
	if picker.randf() >= RANDOM_ACCUSE_CHANCE:
		return false
	t.accuse(Accusation.make(picker.randi_range(0, 2) as Accusation.Target))
	return true


func _accusation_for(c: Cheat) -> Accusation:
	match c.kind:
		Cheat.Kind.SLEEVE:
			return Accusation.make(Accusation.Target.DEALER_HAND)
		Cheat.Kind.ACCOMPLICE:
			return Accusation.make(Accusation.Target.ACCOMPLICE)
	return Accusation.make(Accusation.Target.HISTORY_CARD, c.card_key)


func _run(id: StringName, policy: Policy) -> Dictionary:
	var dealer_wins := 0
	var cheats := 0
	for n in MATCHES:
		var r := _play(id, policy, SEED * 1000 + n)
		if r["winner"] == 1:
			dealer_wins += 1
		cheats += r["cheats"]
	return {"dealer_win_rate": float(dealer_wins) / MATCHES, "cheats_per_match": float(cheats) / MATCHES}


func test_toda_trampa_deja_evidencia_y_respeta_el_presupuesto() -> void:
	for policy in [Policy.NEVER, Policy.RANDOM]:
		_run(&"tramposo", policy)
	assert_eq(_evidence_failures, 0)
	assert_eq(_budget_failures, 0)


func test_tramposo_hace_mas_trampa() -> void:
	var cheater := _run(&"tramposo", Policy.NEVER)
	var aggro := _run(&"agresivo", Policy.NEVER)
	gut.p("trampas por partido: tramposo %.2f, agresivo %.2f" % [cheater["cheats_per_match"], aggro["cheats_per_match"]])
	assert_gt(cheater["cheats_per_match"], aggro["cheats_per_match"])


func test_acusador_atento_gana_mas() -> void:
	var never := _run(&"tramposo", Policy.NEVER)
	var attentive := _run(&"tramposo", Policy.ATTENTIVE)
	var random := _run(&"tramposo", Policy.RANDOM)
	gut.p("el tramposo gana: nunca acusa %.2f, acusa atento %.2f, acusa al azar %.2f" % [
		never["dealer_win_rate"], attentive["dealer_win_rate"], random["dealer_win_rate"]])
	assert_lt(attentive["dealer_win_rate"], never["dealer_win_rate"])
	assert_eq(_evidence_failures, 0)
