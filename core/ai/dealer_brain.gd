class_name DealerBrain
extends RefCounted
## Decide las jugadas del dealer con convicción, no con cálculo: la fuerza
## percibida mezcla la real con el humor y el azar. Ver DISENO §5.

const T := TrucoAction.Type
const ENVIDO_TYPES: Array[TrucoAction.Type] = [T.ENVIDO, T.REAL_ENVIDO, T.FALTA_ENVIDO]
const TRUCO_TYPES: Array[TrucoAction.Type] = [T.TRUCO, T.RETRUCO, T.VALE_CUATRO]

const TILT_AGGRESSION := 0.3
const TILT_LYING := 0.2
const CONFIDENCE_BIAS := 0.4
const NOISE := 0.15

const ENVIDO_CALL := 0.75
const ENVIDO_CALL_AGGR := 0.25
const ENVIDO_BLUFF := 0.35
const FALTA_STRENGTH := 0.95
const FALTA_AGGR := 0.6
const REAL_STRENGTH := 0.85
const ENVIDO_RAISE := 0.9
const ENVIDO_ACCEPT := 0.55
const ENVIDO_ACCEPT_AGGR := 0.15
const ENVIDO_ACCEPT_LIES := 0.2

const LIE_MIN := 26
const LIE_MAX := 32
const SECOND_LIE := 0.6
const SECOND_LIE_SPREAD := 4

const SHOW_BASE := 0.15
const SHOW_LIES := 0.6
const SHOW_HIGH_CLAIM := 31
const SHOW_HIGH_BONUS := 0.2
const SHOW_GAP := 5
const SHOW_GAP_BONUS := 0.2
const SHOW_MAX := 0.9

const TRUCO_CALL := 0.7
const TRUCO_CALL_AGGR := 0.45
const TRUCO_BLUFF := 0.15
const TRUCO_RAISE := 0.85
const TRUCO_RAISE_AGGR := 0.25
const TRUCO_ACCEPT := 0.5
const TRUCO_ACCEPT_AGGR := 0.2
const TRUCO_ACCEPT_STUBBORN := 0.1
const TRUCO_ACCEPT_CALLS := 0.15
const TRUCO_FOLD := 0.1
const FOLD_MAX_STUBBORN := 0.5
const LEAD_HIGH_AGGR := 0.6
const MAZO_STRENGTH := 0.05
const MAZO_MIN_LEVEL := 2

const TELL_STRONG := 0.6
const TELL_ANGRY_TILT := 0.5
const TELL_SMUG_CONFIDENCE := 0.7
const TELL_VARIANTS := 4

var profile: RivalProfile
var mood := DealerMood.new()
var model := PlayerModel.new()
var last_tell: Tell = null
var stats := {
	&"decisions": 0, &"declarations": 0, &"lies": 0, &"envido_calls": 0,
	&"truco_calls": 0, &"truco_chances": 0, &"tells": 0, &"honest_tells": 0,
}

var _rng: RandomNumberGenerator


func _init(p_profile: RivalProfile, p_rng: RandomNumberGenerator) -> void:
	profile = p_profile
	_rng = p_rng


func choose(hand: TrucoHand, me: int) -> TrucoAction:
	var legal := hand.legal_actions()
	stats[&"decisions"] += 1
	last_tell = null
	var action: TrucoAction
	match hand.phase:
		TrucoHand.Phase.PLAYING:
			action = _decide_playing(hand, me, legal)
		TrucoHand.Phase.ENVIDO_RESPONSE:
			action = _decide_envido_response(hand, me, legal)
		TrucoHand.Phase.TANTO_DECLARATION:
			action = _decide_declaration(hand, me, legal)
		TrucoHand.Phase.TRUCO_RESPONSE:
			action = _decide_truco_response(hand, me, legal)
		TrucoHand.Phase.SHOW_DECISION:
			action = _decide_show(hand, me)
	return _legalize(action, legal)


## Llamar al empezar cada partido: el humor arranca de cero, la memoria del jugador sigue.
func start_match() -> void:
	mood = DealerMood.new()


func observe(events: Array[GameEvent], me: int) -> void:
	for e in events:
		match e.type:
			&"hand_over":
				var env: Array = e.data["envido"]
				var tru: Array = e.data["truco"]
				mood.on_hand_result(env[me] + tru[me] > env[1 - me] + tru[1 - me])
				model.hands_seen += 1
			&"lie_caught":
				if e.data["player"] == me:
					mood.on_caught_lying()
				else:
					mood.on_caught_player_lying()
					model.lies_caught += 1
			&"show_demanded":
				if e.data["player"] == me:
					model.shows_seen += 1
			&"show_wrong":
				if e.data["player"] == me:
					mood.on_wrong_show()
			&"call_made":
				if e.data["player"] != me and e.data["call"] in TRUCO_TYPES:
					model.truco_calls += 1


## Índice de la carta a jugar: la más baja que gana si responde, la más alta o
## la del medio si abre la baza.
func pick_card(hand: TrucoHand, me: int) -> int:
	var mine: Array = hand.cards[me]
	var order: Array[int] = []
	for i in mine.size():
		order.append(i)
	order.sort_custom(func(a: int, b: int) -> bool: return mine[a].truco_rank() < mine[b].truco_rank())
	var opp := 1 - me
	if hand.played[opp].size() > hand.played[me].size():
		var to_beat: Card = hand.played[opp].back()
		for i in order:
			if mine[i].truco_rank() > to_beat.truco_rank():
				return i
		return order[0]
	if _aggr() >= LEAD_HIGH_AGGR:
		return order.back()
	return order[order.size() / 2]


# --- Decisiones por fase ---

func _decide_playing(hand: TrucoHand, me: int, legal: Array[TrucoAction]) -> TrucoAction:
	var envido_call := _maybe_call_envido(hand, me, legal)
	if envido_call != null:
		return envido_call
	var pt := _perceived(_truco_strength(hand, me))
	var truco_call := _find(legal, TRUCO_TYPES)
	if truco_call != null:
		stats[&"truco_chances"] += 1
	if truco_call != null and (pt >= TRUCO_CALL - _aggr() * TRUCO_CALL_AGGR or _chance(_lie() * TRUCO_BLUFF)):
		stats[&"truco_calls"] += 1
		_emit_tell(pt)
		return truco_call
	var lost_a_baza := hand.baza_results.has(1 - me)
	if pt < MAZO_STRENGTH and lost_a_baza and hand.truco_level() >= MAZO_MIN_LEVEL:
		return TrucoAction.make(T.MAZO, me)
	return TrucoAction.make(T.PLAY_CARD, me, pick_card(hand, me))


func _decide_envido_response(hand: TrucoHand, me: int, legal: Array[TrucoAction]) -> TrucoAction:
	var pe := _perceived(HandStrength.envido(hand.own_tanto(me)))
	_emit_tell(pe)
	if pe >= ENVIDO_RAISE:
		var raise := _envido_raise(legal, pe)
		if raise != null:
			stats[&"envido_calls"] += 1
			return raise
	var accept_at := ENVIDO_ACCEPT - _aggr() * ENVIDO_ACCEPT_AGGR - model.lie_rate() * ENVIDO_ACCEPT_LIES
	return TrucoAction.make(T.QUIERO if pe >= accept_at else T.NO_QUIERO, me)


func _decide_declaration(hand: TrucoHand, me: int, legal: Array[TrucoAction]) -> TrucoAction:
	var real := hand.own_tanto(me)
	_emit_tell(_perceived(HandStrength.envido(real)))
	var value := real
	if me == hand.mano:
		if _chance(_lie() * (1.0 - HandStrength.envido(real))):
			value = mini(maxi(real + 1, _rng.randi_range(LIE_MIN, LIE_MAX)), TrucoHand.MAX_TANTO)
	else:
		var theirs := hand.declared_tanto(1 - me)
		if theirs >= TrucoHand.MAX_TANTO:
			return TrucoAction.make(T.SON_BUENAS, me)
		if real <= theirs:
			if not _chance(_lie() * SECOND_LIE):
				return TrucoAction.make(T.SON_BUENAS, me)
			value = _rng.randi_range(theirs + 1, mini(TrucoHand.MAX_TANTO, theirs + SECOND_LIE_SPREAD))
	stats[&"declarations"] += 1
	if value != real:
		stats[&"lies"] += 1
	return TrucoAction.make(T.DECLARE_TANTO, me, -1, value)


func _decide_truco_response(hand: TrucoHand, me: int, legal: Array[TrucoAction]) -> TrucoAction:
	var envido_call := _maybe_call_envido(hand, me, legal)
	if envido_call != null:
		return envido_call
	var pt := _perceived(_truco_strength(hand, me))
	_emit_tell(pt)
	var raise := _find(legal, TRUCO_TYPES)
	if raise != null:
		stats[&"truco_chances"] += 1
	if raise != null and pt >= TRUCO_RAISE - _aggr() * TRUCO_RAISE_AGGR:
		stats[&"truco_calls"] += 1
		return raise
	var accept_at := TRUCO_ACCEPT - _aggr() * TRUCO_ACCEPT_AGGR \
		- profile.stubbornness * TRUCO_ACCEPT_STUBBORN - model.truco_call_rate() * TRUCO_ACCEPT_CALLS
	if pt >= accept_at:
		return TrucoAction.make(T.QUIERO, me)
	if pt < TRUCO_FOLD and profile.stubbornness < FOLD_MAX_STUBBORN:
		return TrucoAction.make(T.MAZO, me)
	return TrucoAction.make(T.NO_QUIERO, me)


func _decide_show(hand: TrucoHand, me: int) -> TrucoAction:
	var claim := hand.declared_tanto(1 - me)
	var p := SHOW_BASE + model.lie_rate() * SHOW_LIES
	if claim >= SHOW_HIGH_CLAIM:
		p += SHOW_HIGH_BONUS
	if claim - hand.own_tanto(me) >= SHOW_GAP:
		p += SHOW_GAP_BONUS
	return TrucoAction.make(T.DEMAND_SHOW if _chance(minf(p, SHOW_MAX)) else T.ACCEPT_TANTO, me)


func _maybe_call_envido(hand: TrucoHand, me: int, legal: Array[TrucoAction]) -> TrucoAction:
	if _find(legal, ENVIDO_TYPES) == null:
		return null
	var pe := _perceived(HandStrength.envido(hand.own_tanto(me)))
	if pe < ENVIDO_CALL - _aggr() * ENVIDO_CALL_AGGR and not _chance(_lie() * ENVIDO_BLUFF):
		return null
	stats[&"envido_calls"] += 1
	_emit_tell(pe)
	if pe >= FALTA_STRENGTH and _aggr() >= FALTA_AGGR:
		return TrucoAction.make(T.FALTA_ENVIDO, me)
	if pe >= REAL_STRENGTH:
		return TrucoAction.make(T.REAL_ENVIDO, me)
	return TrucoAction.make(T.ENVIDO, me)


func _envido_raise(legal: Array[TrucoAction], pe: float) -> TrucoAction:
	if pe >= FALTA_STRENGTH and _aggr() >= FALTA_AGGR:
		var falta := _find(legal, [T.FALTA_ENVIDO])
		if falta != null:
			return falta
	return _find(legal, [T.REAL_ENVIDO, T.ENVIDO, T.FALTA_ENVIDO])


# --- Pistas ---

func _emit_tell(perceived: float) -> void:
	var truth := &"strong" if perceived >= TELL_STRONG else &"weak"
	var t := Tell.new()
	t.honest = _chance(profile.tell_reliability)
	if t.honest:
		t.category = truth
	else:
		t.category = &"weak" if truth == &"strong" else &"strong"
	var prefix := "TELL_STRONG_" if t.category == &"strong" else "TELL_WEAK_"
	t.text_key = StringName(prefix + str(_rng.randi_range(1, TELL_VARIANTS)))
	if mood.tilt >= TELL_ANGRY_TILT:
		t.icon = &"angry"
	elif mood.confidence >= TELL_SMUG_CONFIDENCE:
		t.icon = &"smug"
	elif t.category == &"weak":
		t.icon = &"nervous"
	else:
		t.icon = &"calm"
	stats[&"tells"] += 1
	if t.honest:
		stats[&"honest_tells"] += 1
	last_tell = t


# --- Utilidades ---

func _aggr() -> float:
	return clampf(profile.aggression + mood.tilt * TILT_AGGRESSION, 0.0, 1.0)


func _lie() -> float:
	return clampf(profile.lying + mood.tilt * TILT_LYING, 0.0, 1.0)


func _perceived(real: float) -> float:
	var bias := (mood.confidence - 0.5) * CONFIDENCE_BIAS
	return clampf(real + bias + _rng.randf_range(-NOISE, NOISE), 0.0, 1.0)


func _chance(p: float) -> bool:
	return _rng.randf() < p


func _truco_strength(hand: TrucoHand, me: int) -> float:
	var mine: Array[Card] = []
	mine.assign(hand.cards[me])
	return HandStrength.truco(mine, hand.baza_results, me)


func _find(legal: Array[TrucoAction], types: Array) -> TrucoAction:
	for type in types:
		for a in legal:
			if a.type == type:
				return a
	return null


## Si la regla eligió algo ilegal, cae a una legal del mismo tipo o a la primera.
func _legalize(action: TrucoAction, legal: Array[TrucoAction]) -> TrucoAction:
	if action != null:
		for a in legal:
			if a.equals(action):
				return a
		var same := _find(legal, [action.type])
		if same != null:
			return same
	return legal[0]
