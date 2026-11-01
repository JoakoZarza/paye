extends RefCounted
## Ayudas compartidas por los tests de trampas. El jugador es 0 y el dealer 1.

const E := Card.Suit.ESPADA
const B := Card.Suit.BASTO
const O := Card.Suit.ORO
const C := Card.Suit.COPA
const T := TrucoAction.Type


static func cards(spec: Array) -> Array[Card]:
	var out: Array[Card] = []
	for pair in spec:
		out.append(Card.new(pair[0], pair[1]))
	return out


static func profile(cheating: float, budget: int, aggression := 0.3) -> RivalProfile:
	return RivalProfile.from_dict({
		"id": "test", "aggression": aggression, "lying": 0.0, "cheating": cheating,
		"stubbornness": 0.5, "tell_reliability": 0.5, "cheat_budget": budget,
	})


static func table(p: RivalProfile, s := 3, target := 30) -> CheatTable:
	var rng := RandomNumberGenerator.new()
	rng.seed = s
	var brain_rng := RandomNumberGenerator.new()
	brain_rng.seed = s + 100
	var t := CheatTable.new(TrucoMatch.new(target, rng), DealerBrain.new(p, brain_rng), 1, rng)
	t.start_match()
	return t


## Respuesta simple del jugador: quiere todo, dice son buenas, acepta el tanto y
## juega la primera carta.
static func player_move(t: CheatTable) -> TrucoAction:
	var legal := t.truco_match.hand.legal_actions()
	for type in [T.QUIERO, T.SON_BUENAS, T.ACCEPT_TANTO, T.PLAY_CARD, T.DECLARE_TANTO]:
		for a in legal:
			if a.type == type:
				return a
	return legal[0]


## Avanza la mano (dealer y jugador) hasta que `stop` devuelva true o la mano termine.
static func advance(t: CheatTable, stop: Callable) -> void:
	var steps := 0
	while t.truco_match.hand.is_over() == false and not stop.call() and steps < 80:
		if t.is_dealer_turn():
			t.dealer_step()
		else:
			t.player_action(player_move(t))
		steps += 1
