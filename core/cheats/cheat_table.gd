class_name CheatTable
extends RefCounted
## La mesa: envuelve un partido y al dealer. Reparte, aplica las trampas del
## dealer, lo hace jugar y recibe las acciones, acusaciones y trampas del
## jugador. Toda trampa del dealer deja evidencia (DISENO §4).

enum PlayerCheat { MIRROR, MARKED }

const NO_FORCED := -2
const SLEEVE_TELL_CHANCE := 0.6
const DUPLICATE_MIN_RANK := 10
const WRONG_ACCUSATION_POINTS := 3
const MIRROR_RISK := 0.25
const MARKED_RISK := 0.10
const MARKED_RISK_PER_USE := 0.10
const MAX_RISK := 0.95
const ENVIDO_CALL_TYPES: Array[TrucoAction.Type] = [TrucoAction.Type.ENVIDO, TrucoAction.Type.REAL_ENVIDO, TrucoAction.Type.FALTA_ENVIDO]

var truco_match: TrucoMatch
var brain: DealerBrain
var dealer: int
var player: int
## Trampa del dealer en esta mano; null si juega limpio. Queda hasta la mano siguiente.
var active_cheat: Cheat = null
## Trampas del dealer que de verdad se aplicaron en este partido.
var cheats_applied := 0
## Banderas que prenden los amuletos y el mazo de la run.
var rules := TableRules.new()
## Si el jugador cantó algún envido en este partido (Moneda aplastada).
var player_called_envido := false
## El Vaso de caña se aplicó a la declaración del jugador en esta mano.
var _declaration_protected := false
## Trampas del jugador en este partido (premio por trampa no detectada).
var player_cheats_used := 0
var player_cheats_caught := 0

var _rng: RandomNumberGenerator
var _accused := false
var _duplicate_planned := false
var _duplicate_from_brain := false
var _known: Array[Card] = []
var _marked_uses := 0


func _init(p_match: TrucoMatch, p_brain: DealerBrain, p_dealer: int, p_rng: RandomNumberGenerator) -> void:
	truco_match = p_match
	brain = p_brain
	dealer = p_dealer
	player = 1 - p_dealer
	_rng = p_rng


func start_match() -> void:
	brain.start_match()
	brain.cheat_budget *= rules.dealer_budget_multiplier
	_marked_uses = 0
	cheats_applied = 0
	player_called_envido = false
	player_cheats_used = 0
	player_cheats_caught = 0


## forced_kind: NO_FORCED deja decidir al dealer; -1 o un Cheat.Kind fuerzan
## (tests). p_cards / p_mano reparten cartas fijas (tests).
func start_hand(forced_kind: int = NO_FORCED, p_cards: Array = [], p_mano: int = -1) -> Array[GameEvent]:
	var events: Array[GameEvent]
	if p_cards.is_empty():
		events = truco_match.start_hand()
	else:
		events = truco_match.start_hand_with(p_cards, p_mano)
		truco_match.deck = Deck.new(_rng)
		truco_match.deck.shuffle()
		var dealt: Array = []
		for hand_cards in p_cards:
			for card in hand_cards:
				dealt.append(card.key())
		truco_match.deck.remove_keys(dealt)
	active_cheat = null
	_declaration_protected = false
	_accused = false
	# Una duplicada que el dealer decidió y nunca pudo jugar le devuelve el presupuesto.
	if _duplicate_planned and _duplicate_from_brain:
		brain.cheat_budget += 1
	_duplicate_planned = false
	_duplicate_from_brain = forced_kind == NO_FORCED
	_known = []
	var available := available_cheats()
	_sync_context()
	var kind := brain.decide_cheat(available) if forced_kind == NO_FORCED else forced_kind
	if kind != -1 and kind in available:
		events.append_array(_start_cheat(kind))
	brain.observe(events, dealer)
	return events


## El cerebro necesita el marcador para las reglas especiales que dependen de él.
func _sync_context() -> void:
	brain.set_match_context(truco_match.scores[dealer], truco_match.scores[1 - dealer], truco_match.target)


func available_cheats() -> Array[Cheat.Kind]:
	var out: Array[Cheat.Kind] = [Cheat.Kind.DUPLICATE, Cheat.Kind.ACCOMPLICE]
	if truco_match.deck != null and truco_match.deck.remaining() > 0:
		out.push_front(Cheat.Kind.SLEEVE)
	return out


func is_dealer_turn() -> bool:
	return _hand_running() and truco_match.hand.current_player() == dealer


func dealer_step() -> Array[GameEvent]:
	if not is_dealer_turn():
		return [_illegal(dealer)]
	var view := HandView.new(truco_match.hand, dealer)
	view.known_opponent_cards = _known.duplicate()
	_sync_context()
	var a := _apply_rules(brain.choose(view))
	var events: Array[GameEvent]
	if a.type == TrucoAction.Type.PLAY_CARD and _duplicate_ready():
		events = _play_duplicate()
	else:
		events = truco_match.apply(a)
	brain.observe(events, dealer)
	return events


func player_action(a: TrucoAction) -> Array[GameEvent]:
	if a.player != player or not _hand_running():
		return [_illegal(player)]
	var events := truco_match.apply(a)
	var legal := events.is_empty() or events[0].type != &"illegal_action"
	if legal and a.type in ENVIDO_CALL_TYPES:
		player_called_envido = true
	if legal and a.type == TrucoAction.Type.DECLARE_TANTO and rules.skip_next_show:
		rules.skip_next_show = false
		_declaration_protected = true
	brain.observe(events, dealer)
	return events


## Facón, Vaso de caña y Cigarrillo cambian la respuesta del dealer.
func _apply_rules(a: TrucoAction) -> TrucoAction:
	var hand := truco_match.hand
	var responding := hand.phase == TrucoHand.Phase.ENVIDO_RESPONSE or hand.phase == TrucoHand.Phase.TRUCO_RESPONSE
	if responding and rules.force_accept_next_call:
		if rules.force_accept_extra > 0:
			rules.force_accept_extra -= 1
			rules.force_accept_raise_pending = true
		else:
			rules.force_accept_next_call = false
			rules.force_accept_raise_pending = false
		return TrucoAction.make(TrucoAction.Type.QUIERO, dealer)
	if a.type != TrucoAction.Type.DEMAND_SHOW:
		return a
	if _declaration_protected:
		return TrucoAction.make(TrucoAction.Type.ACCEPT_TANTO, dealer)
	if rules.cigarette and hand.declaration_is_lie(player) and _rng.randf() >= rules.cigarette_chance:
		return TrucoAction.make(TrucoAction.Type.ACCEPT_TANTO, dealer)
	return a


func evidence() -> Array[Cheat]:
	var out: Array[Cheat] = []
	if active_cheat != null and active_cheat.evidence_visible:
		out.append(active_cheat)
	return out


## Cartas del jugador que el dealer conoce por el cómplice.
func dealer_known_cards() -> Array[Card]:
	return _known.duplicate()


# --- Acusaciones (DISENO §4.2) ---

func can_accuse() -> bool:
	return _hand_running() and not _accused


func accuse(acc: Accusation) -> Array[GameEvent]:
	if not can_accuse():
		return [_illegal(player)]
	_accused = true
	var events: Array[GameEvent] = []
	if acc.matches(active_cheat) and active_cheat.evidence_visible:
		events.append(GameEvent.make(&"accusation_right", {"kind": active_cheat.kind}))
		events.append_array(truco_match.hand.force_end(player, dealer))
		events.append_array(truco_match.finish_forced_hand())
		brain.mood.on_caught_cheating()
		brain.mood.on_accused()
	else:
		events.append(GameEvent.make(&"accusation_wrong", {"target": acc.target}))
		events.append_array(truco_match.award(dealer, WRONG_ACCUSATION_POINTS))
		brain.mood.on_accused()
		# Lo acusaron en falso: le sube el tilt como a una verificación fallida.
		brain.observe([GameEvent.make(&"show_wrong", {"player": player})], dealer)
	brain.observe(events, dealer)
	return events


# --- Trampas del jugador (DISENO §4.3) ---

func use_player_cheat(kind: PlayerCheat) -> Array[GameEvent]:
	if not _hand_running():
		return [_illegal(player)]
	var risk := MIRROR_RISK * rules.mirror_risk_multiplier
	if kind == PlayerCheat.MARKED:
		risk = MARKED_RISK + MARKED_RISK_PER_USE * rules.marked_step_multiplier * _marked_uses
		_marked_uses += 1
	risk = minf(risk * (1.0 + brain.mood.suspicion), MAX_RISK)
	player_cheats_used += 1
	if _rng.randf() < risk:
		player_cheats_caught += 1
		var events: Array[GameEvent] = [GameEvent.make(&"player_caught", {"kind": kind})]
		events.append_array(truco_match.hand.force_end(dealer, player))
		events.append_array(truco_match.finish_forced_hand())
		brain.mood.on_caught_player_cheating()
		brain.observe(events, dealer)
		return events
	var dealer_cards: Array[Card] = []
	dealer_cards.assign(truco_match.hand.cards[dealer])
	if kind == PlayerCheat.MIRROR:
		return [GameEvent.make(&"player_cheat_info", {"kind": kind, "cards": dealer_cards})]
	var best := 0
	for c in dealer_cards:
		best = maxi(best, c.truco_rank())
	return [GameEvent.make(&"player_cheat_info", {"kind": kind, "best_rank": best})]


# --- Internos ---

func _start_cheat(kind: int) -> Array[GameEvent]:
	var events: Array[GameEvent] = []
	active_cheat = Cheat.make(kind)
	match kind:
		Cheat.Kind.SLEEVE:
			truco_match.hand.add_card(dealer, truco_match.deck.draw(1)[0])
			active_cheat.evidence_visible = true
			cheats_applied += 1
			if _rng.randf() < SLEEVE_TELL_CHANCE:
				events.append(GameEvent.make(&"cheat_tell", {"kind": kind}))
		Cheat.Kind.ACCOMPLICE:
			_known.assign(truco_match.hand.cards[player])
			active_cheat.evidence_visible = true
			cheats_applied += 1
			events.append(GameEvent.make(&"cheat_tell", {"kind": kind}))
		Cheat.Kind.DUPLICATE:
			_duplicate_planned = true
	return events


## Carta duplicada: solo cuando el dealer abre una baza y ya salió una carta
## alta en la mano. Cambia su carta más baja por una copia de la más alta jugada
## y la juega en el mismo paso: antes no influye en nada, y como abrir una baza
## nunca termina la mano, el jugador siempre tiene su turno para acusar.
func _duplicate_ready() -> bool:
	var hand := truco_match.hand
	return _duplicate_planned and hand.phase == TrucoHand.Phase.PLAYING \
		and hand.played[dealer].size() == hand.played[player].size() \
		and not hand.cards[dealer].is_empty() and _best_played() != null


func _best_played() -> Card:
	var best: Card = null
	for p in 2:
		for c in truco_match.hand.played[p]:
			if best == null or c.truco_rank() > best.truco_rank():
				best = c
	if best == null or best.truco_rank() < DUPLICATE_MIN_RANK:
		return null
	return best


func _play_duplicate() -> Array[GameEvent]:
	var hand := truco_match.hand
	var best := _best_played()
	var lowest := 0
	for i in hand.cards[dealer].size():
		if hand.cards[dealer][i].truco_rank() < hand.cards[dealer][lowest].truco_rank():
			lowest = i
	var copy := Card.new(best.suit, best.number)
	for m in best.modifiers:
		copy.add_modifier(m)
	hand.replace_card(dealer, lowest, copy)
	active_cheat.card_key = best.key()
	active_cheat.evidence_visible = true
	_duplicate_planned = false
	cheats_applied += 1
	return truco_match.apply(TrucoAction.make(TrucoAction.Type.PLAY_CARD, dealer, lowest))

func _hand_running() -> bool:
	return truco_match.hand != null and not truco_match.hand.is_over() and truco_match.winner() == -1


func _illegal(p: int) -> GameEvent:
	return GameEvent.make(&"illegal_action", {"player": p, "type": -1})
