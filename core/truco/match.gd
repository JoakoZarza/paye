class_name TrucoMatch
extends RefCounted
## Partido a 15 o 30 puntos. Reparte, alterna el mano y suma primero el envido
## y después el truco. Ver DISENO §3.8.

const CARDS_PER_PLAYER := 3

var target: int
var scores: Array[int] = [0, 0]
var hand: TrucoHand
var mano: int = -1

var _rng: RandomNumberGenerator


func _init(p_target: int, p_rng: RandomNumberGenerator) -> void:
	target = p_target
	_rng = p_rng


func falta_points() -> int:
	return target - maxi(scores[0], scores[1])


func winner() -> int:
	for p in 2:
		if scores[p] >= target:
			return p
	return -1


func start_hand() -> Array[GameEvent]:
	var deck := Deck.new(_rng)
	deck.shuffle()
	var dealt := [deck.draw(CARDS_PER_PLAYER), deck.draw(CARDS_PER_PLAYER)]
	return start_hand_with(dealt, _next_mano())


## Arranca una mano con cartas y mano elegidos. La usan start_hand y los tests.
func start_hand_with(p_cards: Array, p_mano: int) -> Array[GameEvent]:
	assert(winner() == -1, "El partido ya terminó")
	mano = p_mano
	hand = TrucoHand.new(p_cards, mano, falta_points())
	return [GameEvent.make(&"hand_started", {"mano": mano})]


func apply(a: TrucoAction) -> Array[GameEvent]:
	if hand == null or winner() != -1:
		return [GameEvent.make(&"illegal_action", {"player": a.player, "type": a.type})]
	var events := hand.apply(a)
	if hand.is_over():
		_add_points(hand.envido_points)
		if winner() == -1:
			_add_points(hand.truco_points)
		if winner() != -1:
			events.append(GameEvent.make(&"match_over", {"winner": winner(), "scores": scores.duplicate()}))
	return events


func _next_mano() -> int:
	if mano == -1:
		return _rng.randi_range(0, 1)
	return 1 - mano


func _add_points(points: Array[int]) -> void:
	for p in 2:
		scores[p] = mini(scores[p] + points[p], target)
