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
const SECOND_LIE := 0.8
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

const MEMORY_BLUFF_DAMP := 0.5

const CHEAT_RATE := 0.35
const SUSPICION_DETER := 0.8
const KNOWN_WIN := 0.9
const KNOWN_LOSE := 0.2

const TELL_STRONG := 0.6
const TELL_ANGRY_TILT := 0.5
const TELL_SMUG_CONFIDENCE := 0.7
const TELL_VARIANTS := 4

# Reglas especiales de algunas versiones (DISENO §5.5).
const RENCOR: StringName = &"rencor"
const INSACIABLE: StringName = &"insaciable"
const SIESTA: StringName = &"siesta"
const RESENTIDA: StringName = &"resentida"
const ENCANTADORA: StringName = &"encantadora"
const SIESTA_WAKE := 0.6
const SIESTA_PENALTY := 0.3
const RESENTIDA_BONUS := 0.3
const ENCANTADORA_TURN := 0.5
const ENCANTADORA_BETRAYAL := 0.1

var profile: RivalProfile
var mood := DealerMood.new()
var model := PlayerModel.new()
var last_tell: Tell = null
var cheat_budget: int = 0
var stats := {
	&"decisions": 0, &"declarations": 0, &"lies": 0, &"envido_calls": 0,
	&"truco_calls": 0, &"truco_chances": 0, &"tells": 0, &"honest_tells": 0,
}

var _rng: RandomNumberGenerator
var _last_call_kind: StringName = &""
var _my_score: int = 0
var _their_score: int = 0
var _target: int = 0


func _init(p_profile: RivalProfile, p_rng: RandomNumberGenerator) -> void:
	profile = p_profile
	_rng = p_rng
	mood = _new_mood()


## La mesa lo llama antes de cada decisión: algunas reglas especiales miran el marcador.
func set_match_context(my_score: int, their_score: int, target: int) -> void:
	_my_score = my_score
	_their_score = their_score
	_target = target


func choose(view: HandView) -> TrucoAction:
	var me := view.me
	var legal := view.legal_actions()
	stats[&"decisions"] += 1
	last_tell = null
	var action: TrucoAction
	match view.phase():
		TrucoHand.Phase.PLAYING:
			action = _decide_playing(view, me, legal)
		TrucoHand.Phase.ENVIDO_RESPONSE:
			action = _decide_envido_response(view, me, legal)
			# Insaciable: nunca rechaza un envido; si no sube, quiere.
			if profile.special == INSACIABLE and action.type == T.NO_QUIERO:
				action = TrucoAction.make(T.QUIERO, me)
		TrucoHand.Phase.TANTO_DECLARATION:
			action = _decide_declaration(view, me, legal)
		TrucoHand.Phase.TRUCO_RESPONSE:
			action = _decide_truco_response(view, me, legal)
		TrucoHand.Phase.SHOW_DECISION:
			action = _decide_show(view, me)
	return _legalize(action, legal)


## Llamar al empezar cada partido: el humor arranca de cero, la memoria del jugador sigue.
func start_match() -> void:
	mood = _new_mood()
	cheat_budget = profile.cheat_budget
	_my_score = 0
	_their_score = 0
	_target = 0


func _new_mood() -> DealerMood:
	var m := DealerMood.new()
	m.tilt_multiplier = profile.tilt_multiplier
	m.tilt_never_decays = profile.special == RENCOR
	return m


## Devuelve un Cheat.Kind de available, o -1 si no hace trampa en esta mano.
## Elige según profile.cheat_weights; un perfil sin pesos elige parejo entre todas.
func decide_cheat(available: Array[Cheat.Kind]) -> int:
	if cheat_budget <= 0 or available.is_empty():
		return -1
	var weighted: Array[Cheat.Kind] = []
	var weights: Array[float] = []
	for kind in available:
		var w: float = 1.0 if profile.cheat_weights.is_empty() \
			else float(profile.cheat_weights.get(Cheat.Kind.keys()[kind], 0.0))
		if w > 0.0:
			weighted.append(kind)
			weights.append(w)
	if weighted.is_empty():
		return -1
	var p := profile.cheating * CHEAT_RATE * (1.0 - mood.suspicion * SUSPICION_DETER)
	if profile.special == RENCOR:
		p *= 1.0 + mood.tilt
	if not _chance(p):
		return -1
	cheat_budget -= 1
	if profile.cheat_weights.is_empty():
		return weighted[_rng.randi_range(0, weighted.size() - 1)]
	return weighted[_rng.rand_weighted(PackedFloat32Array(weights))]


## Con el cómplice: ¿su tanto le gana al del rival? En empate gana el mano.
func _wins_known_envido(view: HandView) -> bool:
	var mine := view.my_tanto()
	var theirs := Envido.tanto(view.known_opponent_cards)
	return mine > theirs or (mine == theirs and view.mano() == view.me)


func _observe_call(player: int, call: int, me: int) -> void:
	var kind := &"truco" if call in TRUCO_TYPES else &"envido"
	if player == me:
		_last_call_kind = kind
		if kind == &"truco":
			model.truco_offers += 1
		else:
			model.envido_offers += 1
	elif call == T.TRUCO:
		# Solo el primer canto: los retrucos no inflan la tasa por mano.
		model.truco_calls += 1


func _observe_answer(accepted: bool) -> void:
	if accepted and _last_call_kind == &"truco":
		model.truco_accepts += 1
	elif accepted and _last_call_kind == &"envido":
		model.envido_accepts += 1
	_last_call_kind = &""


## Si el jugador suele querer, farolear rinde menos.
func _bluff_damp(accept_rate: float) -> float:
	return 1.0 - accept_rate * MEMORY_BLUFF_DAMP


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
				# Pidió mostrar en falso el dealer, o lo acusaron en falso a él: tilt en los dos casos.
				mood.on_wrong_show()
			&"call_made":
				_observe_call(e.data["player"], e.data["call"], me)
			&"call_accepted", &"call_rejected":
				if e.data["player"] != me:
					_observe_answer(e.type == &"call_accepted")


## Índice de la carta a jugar: la más baja que gana si responde, la más alta o
## la del medio si abre la baza.
func pick_card(view: HandView) -> int:
	var me := view.me
	var mine: Array = view.my_cards()
	# Sin torpeza no se tira el dado: los perfiles viejos juegan igual que antes.
	if profile.blunder > 0.0 and _chance(profile.blunder):
		return _rng.randi_range(0, mine.size() - 1)
	var order: Array[int] = []
	for i in mine.size():
		order.append(i)
	order.sort_custom(func(a: int, b: int) -> bool: return mine[a].truco_rank() < mine[b].truco_rank())
	var opp := 1 - me
	if view.played(opp).size() > view.played(me).size():
		var to_beat: Card = view.played(opp).back()
		for i in order:
			if mine[i].truco_rank() > to_beat.truco_rank():
				return i
		return order[0]
	if _aggr() >= LEAD_HIGH_AGGR:
		return order.back()
	return order[order.size() / 2]


# --- Decisiones por fase ---

func _decide_playing(view: HandView, me: int, legal: Array[TrucoAction]) -> TrucoAction:
	var envido_call := _maybe_call_envido(view, me, legal)
	if envido_call != null:
		return envido_call
	var st := _truco_strength(view, me)
	var pt := _perceived(st)
	var truco_call := _find(legal, TRUCO_TYPES)
	if truco_call != null:
		stats[&"truco_chances"] += 1
	if truco_call != null and (pt >= TRUCO_CALL - _aggr() * TRUCO_CALL_AGGR or _chance(_lie() * TRUCO_BLUFF * _bluff_damp(model.truco_accept_rate()))):
		stats[&"truco_calls"] += 1
		_emit_tell(st)
		return truco_call
	var lost_a_baza := view.baza_results().has(1 - me)
	if pt < MAZO_STRENGTH and lost_a_baza and view.truco_level() >= MAZO_MIN_LEVEL:
		var fold := _fold(view, me, legal)
		if fold != null:
			return fold
	return TrucoAction.make(T.PLAY_CARD, me, pick_card(view))


## Irse al mazo. Con el envido ganado, primero lo muestra si no mintió; si mintió,
## no se va: perdería esos puntos (null).
func _fold(view: HandView, me: int, legal: Array[TrucoAction]) -> TrucoAction:
	if view.envido_winner() != me or view.tanto_shown():
		return TrucoAction.make(T.MAZO, me)
	var show := _find(legal, [T.SHOW_TANTO])
	if show != null and view.declared_tanto(me) <= view.my_tanto():
		return show
	return null


func _decide_envido_response(view: HandView, me: int, legal: Array[TrucoAction]) -> TrucoAction:
	var re := HandStrength.envido(view.my_tanto())
	var pe := _perceived(re)
	_emit_tell(re)
	if not view.known_opponent_cards.is_empty():
		return TrucoAction.make(T.QUIERO if _wins_known_envido(view) else T.NO_QUIERO, me)
	if pe >= ENVIDO_RAISE:
		var raise := _envido_raise(legal, pe)
		if raise != null:
			stats[&"envido_calls"] += 1
			return raise
	var accept_at := ENVIDO_ACCEPT - _aggr() * ENVIDO_ACCEPT_AGGR - model.lie_rate() * ENVIDO_ACCEPT_LIES
	return TrucoAction.make(T.QUIERO if pe >= accept_at else T.NO_QUIERO, me)


func _decide_declaration(view: HandView, me: int, legal: Array[TrucoAction]) -> TrucoAction:
	var real := view.my_tanto()
	_emit_tell(HandStrength.envido(real))
	var value := real
	if me == view.mano():
		if _chance(_lie() * (1.0 - HandStrength.envido(real))):
			value = mini(maxi(real + 1, _rng.randi_range(LIE_MIN, LIE_MAX)), TrucoHand.MAX_TANTO)
	else:
		var theirs := view.declared_tanto(1 - me)
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


func _decide_truco_response(view: HandView, me: int, legal: Array[TrucoAction]) -> TrucoAction:
	var envido_call := _maybe_call_envido(view, me, legal)
	if envido_call != null:
		return envido_call
	var st := _truco_strength(view, me)
	var pt := _perceived(st)
	_emit_tell(st)
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
		var fold := _fold(view, me, legal)
		if fold != null:
			return fold
	return TrucoAction.make(T.NO_QUIERO, me)


func _decide_show(view: HandView, me: int) -> TrucoAction:
	var claim := view.declared_tanto(1 - me)
	var p := SHOW_BASE + model.lie_rate() * SHOW_LIES
	if claim >= SHOW_HIGH_CLAIM:
		p += SHOW_HIGH_BONUS
	if claim - view.my_tanto() >= SHOW_GAP:
		p += SHOW_GAP_BONUS
	return TrucoAction.make(T.DEMAND_SHOW if _chance(minf(p, SHOW_MAX)) else T.ACCEPT_TANTO, me)


func _maybe_call_envido(view: HandView, me: int, legal: Array[TrucoAction]) -> TrucoAction:
	if _find(legal, ENVIDO_TYPES) == null:
		return null
	var re := HandStrength.envido(view.my_tanto())
	var pe := _perceived(re)
	if not view.known_opponent_cards.is_empty():
		if not _wins_known_envido(view):
			return null
		pe = 1.0
	if pe < ENVIDO_CALL - _aggr() * ENVIDO_CALL_AGGR and not _chance(_lie() * ENVIDO_BLUFF * _bluff_damp(model.envido_accept_rate())):
		return null
	stats[&"envido_calls"] += 1
	_emit_tell(re)
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
	return _find(legal, [T.REAL_ENVIDO, T.ENVIDO])


# --- Pistas ---

## La categoría verdadera sale de la fuerza real, no de la percibida (DISENO §5.3).
func _emit_tell(real_strength: float) -> void:
	var truth := &"strong" if real_strength >= TELL_STRONG else &"weak"
	var t := Tell.new()
	t.honest = _chance(_tell_reliability())
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
	var base := profile.aggression
	if profile.special == RESENTIDA and _their_score > _my_score:
		base += RESENTIDA_BONUS
	return clampf(base + mood.tilt * TILT_AGGRESSION, 0.0, 1.0)


## Encantadora: pistas confiables hasta la mitad del partido, después traiciona.
func _tell_reliability() -> float:
	if profile.special == ENCANTADORA and _target > 0 \
			and maxi(_my_score, _their_score) >= _target * ENCANTADORA_TURN:
		return ENCANTADORA_BETRAYAL
	return profile.tell_reliability


## Siesta: juega dormido hasta que alguien se acerca al objetivo.
func _asleep() -> bool:
	return profile.special == SIESTA and maxi(_my_score, _their_score) < _target * SIESTA_WAKE


func _lie() -> float:
	return clampf(profile.lying + mood.tilt * TILT_LYING, 0.0, 1.0)


func _perceived(real: float) -> float:
	var bias := (mood.confidence - 0.5) * CONFIDENCE_BIAS
	if _asleep():
		bias -= SIESTA_PENALTY
	return clampf(real + bias + _rng.randf_range(-profile.noise, profile.noise), 0.0, 1.0)


func _chance(p: float) -> bool:
	return p >= 1.0 or _rng.randf() < p


func _truco_strength(view: HandView, me: int) -> float:
	var mine: Array[Card] = []
	mine.assign(view.my_cards())
	# La carta propia tirada en la baza en curso todavía cuenta.
	if view.played(me).size() > view.played(1 - me).size():
		mine.append(view.played(me).back())
	if not view.known_opponent_cards.is_empty():
		return _known_truco_strength(view, mine)
	return HandStrength.truco(mine, view.baza_results(), me)


## Con el cómplice: compara su mejor carta con la mejor que le queda al rival.
func _known_truco_strength(view: HandView, mine: Array[Card]) -> float:
	var gone := {}
	for c in view.played(1 - view.me):
		gone[c.key()] = true
	var best_theirs := 0
	for c in view.known_opponent_cards:
		if not gone.has(c.key()):
			best_theirs = maxi(best_theirs, c.truco_rank())
	var best_mine := 0
	for c in mine:
		best_mine = maxi(best_mine, c.truco_rank())
	return KNOWN_WIN if best_mine > best_theirs else KNOWN_LOSE


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
