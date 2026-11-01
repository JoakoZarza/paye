class_name Deck
extends RefCounted
## Mazo de 40 cartas. Todo el azar sale del RandomNumberGenerator recibido.

var _rng: RandomNumberGenerator
var _cards: Array[Card] = []


func _init(rng: RandomNumberGenerator) -> void:
	_rng = rng
	_cards = full_deck()


static func full_deck() -> Array[Card]:
	var out: Array[Card] = []
	for s in Card.Suit.values():
		for n in Card.VALID_NUMBERS:
			out.append(Card.new(s, n))
	return out


## Fisher-Yates con el rng propio (nunca Array.shuffle, que usa el azar global).
func shuffle() -> void:
	for i in range(_cards.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp := _cards[i]
		_cards[i] = _cards[j]
		_cards[j] = tmp


func draw(n: int) -> Array[Card]:
	var out: Array[Card] = []
	for i in mini(n, _cards.size()):
		out.append(_cards.pop_back())
	return out


## Saca del mazo las cartas con estas claves (cartas repartidas a mano en los tests).
func remove_keys(keys: Array) -> void:
	_cards = _cards.filter(func(c: Card) -> bool: return not (c.key() in keys))


func remaining() -> int:
	return _cards.size()
