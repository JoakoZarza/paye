class_name AmuletSystem
extends RefCounted
## Aplica los amuletos del jugador sobre la mesa. Los activos se usan con use();
## los pasivos actúan solos (al empezar la mano o a través de TableRules).
## Ver DISENO §8 y las decisiones de interpretación del Plan 4.

const GLASS_SUSPICION := 0.2
const T := TrucoAction.Type

var table: CheatTable
var loadout: Loadout

var _rng: RandomNumberGenerator


func _init(p_table: CheatTable, p_loadout: Loadout, p_rng: RandomNumberGenerator) -> void:
	table = p_table
	loadout = p_loadout
	_rng = p_rng


func start_match() -> void:
	loadout.reset_charges()
	table.rules.force_accept_next_call = false
	table.rules.skip_next_show = false
	table.rules.cigarette = loadout.has(&"cigarette")
	table.start_match()


func start_hand(forced_kind: int = CheatTable.NO_FORCED, p_cards: Array = [], p_mano: int = -1) -> Array[GameEvent]:
	var events := table.start_hand(forced_kind, p_cards, p_mano)
	if loadout.has(&"glasses"):
		var dealer_cards: Array = _hand().cards[table.dealer]
		var card: Card = dealer_cards[_rng.randi_range(0, dealer_cards.size() - 1)]
		events.append(GameEvent.make(&"amulet_info", {"id": &"glasses", "numbers": [card.effective_number()]}))
	return events


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
			if not hand.can_mark(me, idx, number):
				return [_illegal()]
			var m := CardModifier.new()
			m.new_number = number
			m.scope = CardModifier.Scope.HAND
			m.source = &"marker"
			hand.cards[me][idx].add_modifier(m)
			events.append(_used(id, {"card_index": idx, "number": number}))
		&"spare_deck":
			var idx: int = args.get("card_index", -1)
			if idx < 0 or idx >= hand.cards[me].size():
				return [_illegal()]
			var card := _draw_spare(hand)
			hand.replace_card(me, idx, card)
			events.append(_used(id, {"card_index": idx, "card": card}))
		&"cana_glass":
			table.rules.skip_next_show = true
			table.brain.mood.suspicion = clampf(table.brain.mood.suspicion + GLASS_SUSPICION, 0.0, 1.0)
			events.append(_used(id))
		&"rosary":
			if not hand.undo_last_call(me):
				return [_illegal()]
			events.append(_used(id))
		&"facon":
			table.rules.force_accept_next_call = true
			events.append(_used(id))
		&"hat":
			var numbers: Array = []
			for c in hand.cards[table.dealer]:
				numbers.append(c.effective_number())
			events.append(GameEvent.make(&"amulet_info", {"id": id, "numbers": numbers}))
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
func _draw_spare(hand: TrucoHand) -> Card:
	var reserve := Deck.new(_rng)
	reserve.shuffle()
	var used: Array = []
	for p in 2:
		for c in hand.cards[p] + hand.played[p]:
			used.append(c.key())
			used.append("%d_%s" % [c.effective_number(), Card.Suit.keys()[c.effective_suit()]])
	reserve.remove_keys(used)
	return reserve.draw(1)[0]


func _hand() -> TrucoHand:
	return table.truco_match.hand


func _hand_running() -> bool:
	return _hand() != null and not _hand().is_over() and table.truco_match.winner() == -1


func _used(id: StringName, data: Dictionary = {}) -> GameEvent:
	data["id"] = id
	return GameEvent.make(&"amulet_used", data)


func _illegal() -> GameEvent:
	return GameEvent.make(&"illegal_action", {"player": table.player, "type": -1})
