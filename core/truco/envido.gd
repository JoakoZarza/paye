class_name Envido
extends RefCounted
## Calcula el mejor tanto posible de una mano.


static func tanto(cards: Array[Card]) -> int:
	var best := 0
	var by_suit: Array[Array] = [[], [], [], []]
	for card in cards:
		var value := card.envido_value()
		best = maxi(best, value)
		by_suit[card.effective_suit()].append(value)

	for values: Array in by_suit:
		if values.size() < 2:
			continue
		values.sort()
		var count := values.size()
		best = maxi(best, 20 + int(values[count - 1]) + int(values[count - 2]))
	return best
