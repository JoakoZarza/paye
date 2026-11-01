class_name TrucoHand
extends RefCounted
## Máquina de estados de una mano de truco 1 contra 1, sin flor. Recibe
## acciones, devuelve eventos. Ver DISENO §3 y Plan 1, Tarea 6.

enum Phase { PLAYING, ENVIDO_RESPONSE, TANTO_DECLARATION, TRUCO_RESPONSE, SHOW_DECISION, OVER }

const LIE_PENALTY := 1
const WRONG_SHOW_PENALTY := 1
const MAX_TANTO := 33
const MAX_BAZAS := 3

const T := TrucoAction.Type
const ENVIDO_CALLS := {
	T.ENVIDO: EnvidoBet.Call.ENVIDO,
	T.REAL_ENVIDO: EnvidoBet.Call.REAL_ENVIDO,
	T.FALTA_ENVIDO: EnvidoBet.Call.FALTA_ENVIDO,
}
const TRUCO_CALLS: Array[TrucoAction.Type] = [T.TRUCO, T.RETRUCO, T.VALE_CUATRO]

var phase: Phase = Phase.PLAYING
var mano: int
## Cartas que cada jugador todavía tiene en la mano.
var cards: Array = [[], []]
## Cartas jugadas por cada jugador, en orden.
var played: Array = [[], []]
var baza_results: Array[int] = []
var envido_points: Array[int] = [0, 0]
var truco_points: Array[int] = [0, 0]

var _falta_points: int
var _turn: int
var _truco := TrucoBet.new()
var _envido := EnvidoBet.new()
var _envido_done := false
var _envido_caller := -1
var _envido_value := 0
var _envido_accepted := false
var _resume_phase: Phase = Phase.PLAYING
var _declared: Array[int] = [-1, -1]
var _real_tanto: Array[int] = [0, 0]
var _envido_winner := -1
## Fotos del estado antes de cada canto de la cadena en curso (para el Rosario).
var _call_snapshots: Array[Dictionary] = []
## Cantos que el Rosario le prohibió a cada jugador por el resto de la mano.
var _call_veto: Array[Dictionary] = [{}, {}]


func _init(p_cards: Array, p_mano: int, p_falta_points: int) -> void:
	cards = [p_cards[0].duplicate(), p_cards[1].duplicate()]
	mano = p_mano
	_turn = p_mano
	_falta_points = p_falta_points


func is_over() -> bool:
	return phase == Phase.OVER


## Rosario: si el último canto lo hizo el rival de y y espera su respuesta,
## la mano vuelve al estado de antes de ese canto.
func undo_last_call(by: int) -> bool:
	if not can_undo_last_call(by):
		return false
	var snap: Dictionary = _call_snapshots.pop_back()
	# El rival no puede repetir el canto anulado en esta mano: si no, el Rosario no sirve.
	_call_veto[1 - by][snap["kind"]] = true
	phase = snap["phase"]
	_turn = snap["turn"]
	_truco.level = snap["truco_level"]
	_truco.pending = snap["truco_pending"]
	_truco.quiero_owner = snap["quiero_owner"]
	_truco.last_caller = snap["truco_last_caller"]
	_envido.calls.assign(snap["envido_calls"])
	_envido_caller = snap["envido_caller"]
	_resume_phase = snap["resume_phase"]
	return true


## Si el envido se resolvió en medio de la cadena de truco, la foto ya no sirve:
## el truco del rival queda sin poder anularse.
func can_undo_last_call(by: int) -> bool:
	if phase != Phase.ENVIDO_RESPONSE and phase != Phase.TRUCO_RESPONSE:
		return false
	if _call_snapshots.is_empty() or current_player() != by:
		return false
	return _call_snapshots.back()["caller"] == 1 - by


## Marcador: el número es válido y la carta no queda igual a otra de la mano.
## new_suit -1 deja el palo. Si cambia el palo, tampoco puede copiar una carta que el
## rival ya jugó; las de su mano no se miran, para que el Marcador no las delate.
func can_mark(p: int, idx: int, new_number: int, new_suit: int = -1) -> bool:
	if idx < 0 or idx >= cards[p].size() or not Card.is_valid_number(new_number):
		return false
	if new_suit != -1 and (new_suit < 0 or new_suit >= Card.Suit.size()):
		return false
	var target: Card = cards[p][idx]
	var suit: int = target.effective_suit() if new_suit == -1 else new_suit
	var others: Array = cards[p] + played[p]
	if new_suit != -1:
		others += played[1 - p]
	for other in others:
		if other != target and other.effective_number() == new_number and other.effective_suit() == suit:
			return false
	return true


## Misma regla que al pedir que muestre: declaró más que su tanto real y además
## pierde la comparación real (en empate gana el mano).
func declaration_is_lie(p: int) -> bool:
	return _declared[p] > _real_tanto[p] and _real_winner() != p


func _snapshot(caller: int, kind: StringName) -> Dictionary:
	return {
		"caller": caller, "kind": kind, "phase": phase, "turn": _turn,
		"truco_level": _truco.level, "truco_pending": _truco.pending,
		"quiero_owner": _truco.quiero_owner, "truco_last_caller": _truco.last_caller,
		"envido_calls": _envido.calls.duplicate(), "envido_caller": _envido_caller,
		"resume_phase": _resume_phase,
	}


## Trampa de la manga: el jugador recibe una carta extra.
func add_card(p: int, card: Card) -> void:
	cards[p].append(card)


## Carta duplicada: cambia una carta en mano por otra.
func replace_card(p: int, idx: int, card: Card) -> void:
	cards[p][idx] = card


func total_cards(p: int) -> int:
	return cards[p].size() + played[p].size()


## Termina la mano por una trampa descubierta (DISENO §4.2 y §4.3). El ganador
## suma lo que vale el truco en este momento; el tramposo pierde el envido de la
## mano; si el ganador ganaba el envido, lo cobra solo si no mintió.
func force_end(winner: int, cheater: int) -> Array[GameEvent]:
	if phase == Phase.OVER:
		return [GameEvent.make(&"illegal_action", {"player": winner, "type": -1})]
	var value := _truco.rejected_value() if _truco.pending else _truco.accepted_value()
	truco_points = [0, 0]
	truco_points[winner] = maxi(value, 1)
	envido_points[cheater] = 0
	# El envido del acusador se cobra con una verificación implícita: si mintió, no cobra.
	if _envido_accepted and _envido_winner == winner:
		var lied := _declared[winner] > _real_tanto[winner] and _real_winner() != winner
		if not lied:
			envido_points[winner] += _envido_value
	phase = Phase.OVER
	return [GameEvent.make(&"hand_over", {"envido": envido_points.duplicate(), "truco": truco_points.duplicate()})]


## -1 si el jugador no declaró tanto en esta mano.
func declared_tanto(p: int) -> int:
	return _declared[p]


func truco_level() -> int:
	return _truco.level


func truco_pending() -> bool:
	return _truco.pending


func envido_called() -> bool:
	return not _envido.calls.is_empty()


## -1 si no hubo envido querido o la declaración no terminó.
func envido_winner() -> int:
	return _envido_winner


## Tanto de las cartas en mano y jugadas de p. La IA solo debe pedir el suyo.
func own_tanto(p: int) -> int:
	var all: Array[Card] = []
	all.assign(cards[p] + played[p])
	return Envido.tanto(all)


func current_player() -> int:
	match phase:
		Phase.PLAYING:
			return _turn
		Phase.ENVIDO_RESPONSE:
			return 1 - _envido_caller
		Phase.TRUCO_RESPONSE:
			return 1 - _truco.last_caller
		Phase.TANTO_DECLARATION:
			return mano if _declared[mano] == -1 else 1 - mano
		Phase.SHOW_DECISION:
			return 1 - _envido_winner
		_:
			return -1


func legal_actions() -> Array[TrucoAction]:
	var p := current_player()
	var out: Array[TrucoAction] = []
	match phase:
		Phase.PLAYING:
			for i in cards[p].size():
				out.append(TrucoAction.make(T.PLAY_CARD, p, i))
			_add_envido_calls(out, p)
			if _truco.can_raise(p) and not _call_veto[p].has(&"truco"):
				out.append(TrucoAction.make(TRUCO_CALLS[_truco.level], p))
			out.append(TrucoAction.make(T.MAZO, p))
		Phase.ENVIDO_RESPONSE:
			out.append(TrucoAction.make(T.QUIERO, p))
			out.append(TrucoAction.make(T.NO_QUIERO, p))
			for type in ENVIDO_CALLS:
				if _envido.can_add(ENVIDO_CALLS[type]) and not _call_veto[p].has(&"envido"):
					out.append(TrucoAction.make(type, p))
		Phase.TRUCO_RESPONSE:
			out.append(TrucoAction.make(T.QUIERO, p))
			out.append(TrucoAction.make(T.NO_QUIERO, p))
			if _truco.can_raise(p) and not _call_veto[p].has(&"truco"):
				out.append(TrucoAction.make(TRUCO_CALLS[_truco.level], p))
			_add_envido_calls(out, p)
			out.append(TrucoAction.make(T.MAZO, p))
		Phase.TANTO_DECLARATION:
			var floor_value := 0 if p == mano else _declared[mano] + 1
			if p != mano:
				out.append(TrucoAction.make(T.SON_BUENAS, p))
			for v in range(floor_value, MAX_TANTO + 1):
				out.append(TrucoAction.make(T.DECLARE_TANTO, p, -1, v))
		Phase.SHOW_DECISION:
			out.append(TrucoAction.make(T.DEMAND_SHOW, p))
			out.append(TrucoAction.make(T.ACCEPT_TANTO, p))
	return out


func apply(a: TrucoAction) -> Array[GameEvent]:
	if not _is_legal(a):
		return [GameEvent.make(&"illegal_action", {"player": a.player, "type": a.type})]
	var events: Array[GameEvent] = []
	var p := a.player
	if a.type in ENVIDO_CALLS or a.type in TRUCO_CALLS:
		_call_snapshots.append(_snapshot(p, &"envido" if a.type in ENVIDO_CALLS else &"truco"))
	else:
		_call_snapshots.clear()
	match a.type:
		T.PLAY_CARD:
			_play_card(p, a.card_index, events)
		T.ENVIDO, T.REAL_ENVIDO, T.FALTA_ENVIDO:
			if phase != Phase.ENVIDO_RESPONSE:
				_resume_phase = phase
			_envido.add(ENVIDO_CALLS[a.type])
			_envido_caller = p
			phase = Phase.ENVIDO_RESPONSE
			events.append(GameEvent.make(&"call_made", {"player": p, "call": a.type}))
		T.TRUCO, T.RETRUCO, T.VALE_CUATRO:
			_truco.raise(p)
			phase = Phase.TRUCO_RESPONSE
			events.append(GameEvent.make(&"call_made", {"player": p, "call": a.type}))
		T.QUIERO:
			events.append(GameEvent.make(&"call_accepted", {"player": p}))
			if phase == Phase.ENVIDO_RESPONSE:
				_accept_envido()
			else:
				_truco.accept()
				phase = Phase.PLAYING
		T.NO_QUIERO:
			events.append(GameEvent.make(&"call_rejected", {"player": p}))
			if phase == Phase.ENVIDO_RESPONSE:
				envido_points[_envido_caller] += _envido.points_if_rejected()
				_envido_done = true
				phase = _resume_phase
			else:
				truco_points[_truco.last_caller] = _truco.rejected_value()
				_finish(events)
		T.DECLARE_TANTO:
			_declared[p] = a.value
			events.append(GameEvent.make(&"tanto_declared", {"player": p, "value": a.value}))
			if p != mano:
				_close_declaration(p, events)
		T.SON_BUENAS:
			events.append(GameEvent.make(&"son_buenas", {"player": p}))
			_close_declaration(mano, events)
		T.MAZO:
			var points := _truco.rejected_value() if _truco.pending else _truco.accepted_value()
			truco_points[1 - p] = points
			events.append(GameEvent.make(&"mazo", {"player": p}))
			# Irse al mazo sin mostrar el tanto ganado: el envido lo cobra el rival.
			if _envido_accepted and _envido_winner == p:
				envido_points[1 - p] += _envido_value
				_envido_winner = -1
				events.append(GameEvent.make(&"envido_forfeit", {"player": p, "points": _envido_value}))
			_finish(events)
		T.DEMAND_SHOW, T.ACCEPT_TANTO:
			_resolve_show(p, a.type == T.DEMAND_SHOW, events)
	return events


func _is_legal(a: TrucoAction) -> bool:
	if phase == Phase.OVER or a.player != current_player():
		return false
	for legal in legal_actions():
		if legal.equals(a):
			return true
	return false


## El envido se canta solo en la primera baza, antes de jugar tu carta, una vez
## por mano, y nunca después de un truco ya querido.
func _add_envido_calls(out: Array[TrucoAction], p: int) -> void:
	if _envido_done or not baza_results.is_empty() or not played[p].is_empty() or _call_veto[p].has(&"envido"):
		return
	# "El envido está primero" solo responde al primer truco, no al retruco.
	if _truco.level > 1 or (_truco.level == 1 and not _truco.pending):
		return
	for type in ENVIDO_CALLS:
		out.append(TrucoAction.make(type, p))


func _accept_envido() -> void:
	_envido_accepted = true
	_envido_value = _envido.points_if_accepted(_falta_points)
	for i in 2:
		var all: Array[Card] = []
		all.assign(cards[i] + played[i])
		_real_tanto[i] = Envido.tanto(all)
	phase = Phase.TANTO_DECLARATION


func _close_declaration(winner: int, events: Array[GameEvent]) -> void:
	_envido_winner = winner
	_envido_done = true
	phase = _resume_phase
	events.append(GameEvent.make(&"envido_won", {"player": winner, "provisional": true}))


func _play_card(p: int, idx: int, events: Array[GameEvent]) -> void:
	var card: Card = cards[p].pop_at(idx)
	played[p].append(card)
	events.append(GameEvent.make(&"card_played", {"player": p, "card": card}))
	if played[0].size() != played[1].size():
		_turn = 1 - p
		return
	var cmp := BazaResolver.compare(played[0].back(), played[1].back())
	var result := BazaResolver.PARDA if cmp == 0 else (0 if cmp > 0 else 1)
	baza_results.append(result)
	events.append(GameEvent.make(&"baza_won", {"result": result}))
	var winner := BazaResolver.hand_winner(baza_results, mano)
	if winner == BazaResolver.UNDECIDED and baza_results.size() < MAX_BAZAS:
		_turn = mano if result == BazaResolver.PARDA else result
		return
	if winner == BazaResolver.UNDECIDED:
		winner = mano
	truco_points[winner] = _truco.accepted_value()
	_finish(events)


func _finish(events: Array[GameEvent]) -> void:
	if _envido_accepted and _envido_winner != -1:
		phase = Phase.SHOW_DECISION
		return
	phase = Phase.OVER
	events.append(GameEvent.make(&"hand_over", {"envido": envido_points, "truco": truco_points}))


## Mintió quien declaró más que su tanto real y además pierde la comparación
## real (en empate gana el mano).
func _resolve_show(demander: int, demanded: bool, events: Array[GameEvent]) -> void:
	var w := _envido_winner
	if not demanded:
		envido_points[w] += _envido_value
	else:
		events.append(GameEvent.make(&"show_demanded", {"player": demander}))
		var real_winner := _real_winner()
		var lied := _declared[w] > _real_tanto[w] and real_winner != w
		if lied:
			envido_points[demander] += _envido_value + LIE_PENALTY
			events.append(GameEvent.make(&"lie_caught", {"player": w}))
		else:
			envido_points[w] += _envido_value + WRONG_SHOW_PENALTY
			events.append(GameEvent.make(&"show_wrong", {"player": demander}))
	phase = Phase.OVER
	events.append(GameEvent.make(&"hand_over", {"envido": envido_points, "truco": truco_points}))


func _real_winner() -> int:
	if _real_tanto[0] == _real_tanto[1]:
		return mano
	return 0 if _real_tanto[0] > _real_tanto[1] else 1
