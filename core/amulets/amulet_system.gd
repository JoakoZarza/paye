class_name AmuletSystem
extends RefCounted
## Aplica los amuletos del jugador sobre la mesa. Los activos se usan con use();
## los pasivos actúan solos (al empezar la mano o a través de TableRules).
## Ver DISENO §8 y §8.1 (niveles), y las decisiones de los Planes 4 y 5c.

const GLASS_SUSPICION := 0.2
const T := TrucoAction.Type

var table: CheatTable
var loadout: Loadout

var _rng: RandomNumberGenerator
## Mazo aparte III: las cartas que se ofrecieron para elegir en esta mano.
var _spare_preview: Array[Card] = []


func _init(p_table: CheatTable, p_loadout: Loadout, p_rng: RandomNumberGenerator) -> void:
	table = p_table
	loadout = p_loadout
	_rng = p_rng


func start_match() -> void:
	loadout.reset_charges()
	table.rules.force_accept_next_call = false
	table.rules.skip_next_show = false
	table.rules.cigarette = loadout.has(&"cigarette")
	table.rules.cigarette_chance = float(_value(&"cigarette", "show_chance", 0.5))
	table.rules.mirror_risk_multiplier = float(_value(&"mirror", "risk_multiplier", 1.0))
	table.rules.marked_step_multiplier = float(_value(&"marked_cards", "risk_step_multiplier", 1.0))
	table.rules.force_accept_extra = 0
	table.start_match()


func start_hand(forced_kind: int = CheatTable.NO_FORCED, p_cards: Array = [], p_mano: int = -1) -> Array[GameEvent]:
	var events := table.start_hand(forced_kind, p_cards, p_mano)
	_spare_preview = []
	if loadout.has(&"glasses"):
		var dealer_cards: Array = _hand().cards[table.dealer].duplicate()
		var count := mini(int(_value(&"glasses", "reveal_count", 1)), dealer_cards.size())
		var numbers: Array = []
		var suits: Array = []
		for i in count:
			var card: Card = dealer_cards.pop_at(_rng.randi_range(0, dealer_cards.size() - 1))
			numbers.append(card.effective_number())
			suits.append(card.effective_suit())
		var data := {"id": &"glasses", "numbers": numbers}
		if _value(&"glasses", "reveal_suit", false):
			data["suits"] = suits
		events.append(GameEvent.make(&"amulet_info", data))
	return events


## Mazo aparte III: muestra las cartas entre las que vas a elegir. Siempre las
## mismas dentro de la mano hasta que uses el amuleto.
func preview_spare() -> Array[Card]:
	if not can_use(&"spare_deck") or int(_value(&"spare_deck", "choose_from", 1)) < 2:
		return []
	if _spare_preview.is_empty():
		_spare_preview = _draw_spare(_hand(), int(_value(&"spare_deck", "choose_from", 1)))
	return _spare_preview.duplicate()


func can_use(id: StringName) -> bool:
	if not loadout.has(id) or loadout.charges_left(id) <= 0 or not _hand_running():
		return false
	match id:
		&"rosary":
			return _hand().can_undo_last_call(table.player)
		&"facon":
			return not table.rules.force_accept_next_call
		&"spare_deck":
			# Sin cartas en la mano no hay nada que cambiar.
			return not _hand().cards[table.player].is_empty()
	return true


func use(id: StringName, args: Dictionary = {}) -> Array[GameEvent]:
	if not can_use(id):
		return [_illegal()]
	var events: Array[GameEvent] = []
	var hand := _hand()
	var me := table.player
	match id:
		&"marker":
			var idx: int = args.get("card_index", -1)
			var number: int = args.get("number", -1)
			var suit: int = args.get("suit", -1)
			if suit != -1 and not _value(&"marker", "change_suit", false):
				return [_illegal()]
			if not hand.can_mark(me, idx, number, suit):
				return [_illegal()]
			var m := CardModifier.new()
			m.new_number = number
			m.new_suit = suit
			m.scope = CardModifier.Scope.HAND
			m.source = &"marker"
			hand.cards[me][idx].add_modifier(m)
			events.append(_used(id, {"card_index": idx, "number": number, "suit": suit}))
		&"spare_deck":
			var idx: int = args.get("card_index", -1)
			if idx < 0 or idx >= hand.cards[me].size():
				return [_illegal()]
			var card: Card
			var options := preview_spare()
			if options.is_empty():
				card = _draw_spare(hand, 1)[0]
			else:
				var choice: int = args.get("choice", 0)
				if choice < 0 or choice >= options.size():
					return [_illegal()]
				card = options[choice]
				_spare_preview = []
			hand.replace_card(me, idx, card)
			events.append(_used(id, {"card_index": idx, "card": card}))
		&"cana_glass":
			table.rules.skip_next_show = true
			if not _value(&"cana_glass", "no_suspicion", false):
				table.brain.mood.suspicion = clampf(table.brain.mood.suspicion + GLASS_SUSPICION, 0.0, 1.0)
			events.append(_used(id))
		&"rosary":
			if not hand.undo_last_call(me):
				return [_illegal()]
			events.append(_used(id))
		&"facon":
			table.rules.force_accept_next_call = true
			table.rules.force_accept_extra = 1 if _value(&"facon", "raise_too", false) else 0
			events.append(_used(id))
		&"hat":
			var numbers: Array = []
			var best: Card = null
			for c in hand.cards[table.dealer]:
				numbers.append(c.effective_number())
				if best == null or c.truco_rank() > best.truco_rank():
					best = c
			var data := {"id": id, "numbers": numbers}
			if _value(&"hat", "reveal_suit", false) and best != null:
				data["best_suit"] = best.effective_suit()
			events.append(GameEvent.make(&"amulet_info", data))
		&"mirror":
			events.append(_used(id))
			events.append_array(table.use_player_cheat(CheatTable.PlayerCheat.MIRROR))
		&"marked_cards":
			events.append(_used(id))
			events.append_array(table.use_player_cheat(CheatTable.PlayerCheat.MARKED))
		_:
			return [_illegal()]
	loadout.spend(id)
	return events


## Carta al azar de un mazo de reserva, distinta de toda carta de la mesa,
## tanto por su identidad base como por la efectiva (cartas marcadas).
func _draw_spare(hand: TrucoHand, count: int) -> Array[Card]:
	var reserve := Deck.new(_rng)
	reserve.shuffle()
	var used: Array = []
	for p in 2:
		for c in hand.cards[p] + hand.played[p]:
			used.append(c.key())
			used.append("%d_%s" % [c.effective_number(), Card.Suit.keys()[c.effective_suit()]])
	reserve.remove_keys(used)
	return reserve.draw(count)


## Valor del nivel actual del amuleto equipado, o default si no lo tenés.
func _value(id: StringName, key: String, default: Variant) -> Variant:
	if not loadout.has(id):
		return default
	for def in loadout.equipped():
		if def.id == id:
			return def.value(key, loadout.level(id), default)
	return default


func _hand() -> TrucoHand:
	return table.truco_match.hand


func _hand_running() -> bool:
	return _hand() != null and not _hand().is_over() and table.truco_match.winner() == -1


func _used(id: StringName, data: Dictionary = {}) -> GameEvent:
	data["id"] = id
	return GameEvent.make(&"amulet_used", data)


func _illegal() -> GameEvent:
	return GameEvent.make(&"illegal_action", {"player": table.player, "type": -1})
