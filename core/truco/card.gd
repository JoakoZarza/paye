class_name Card
extends RefCounted
## Carta del mazo español. Los valores base nunca cambian; los modificadores
## definen el número y palo efectivos que usan el truco y el tanto.

enum Suit { ESPADA, BASTO, ORO, COPA }

const VALID_NUMBERS: Array[int] = [1, 2, 3, 4, 5, 6, 7, 10, 11, 12]

var suit: Suit
var number: int
var modifiers: Array[CardModifier] = []


func _init(p_suit: Suit, p_number: int) -> void:
	assert(is_valid_number(p_number), "Número de carta inválido: %d" % p_number)
	suit = p_suit
	number = p_number


static func is_valid_number(n: int) -> bool:
	return n in VALID_NUMBERS


func add_modifier(m: CardModifier) -> bool:
	if m.new_number != -1 and not is_valid_number(m.new_number):
		return false
	if m.new_suit != -1 and (m.new_suit < 0 or m.new_suit >= Suit.size()):
		return false
	modifiers.append(m)
	return true


func clear_modifiers(scope: CardModifier.Scope) -> void:
	modifiers = modifiers.filter(func(m: CardModifier) -> bool: return m.scope != scope)


## Gana el último modificador agregado que cambie el número.
func effective_number() -> int:
	for i in range(modifiers.size() - 1, -1, -1):
		if modifiers[i].new_number != -1:
			return modifiers[i].new_number
	return number


func effective_suit() -> Suit:
	for i in range(modifiers.size() - 1, -1, -1):
		if modifiers[i].new_suit != -1:
			return modifiers[i].new_suit as Suit
	return suit


## Rango para las bazas, de 14 (1 de espada) a 1 (los 4). Ver DISENO §3.1.
func truco_rank() -> int:
	var n := effective_number()
	var s := effective_suit()
	match n:
		1:
			if s == Suit.ESPADA:
				return 14
			if s == Suit.BASTO:
				return 13
			return 8
		7:
			if s == Suit.ESPADA:
				return 12
			if s == Suit.ORO:
				return 11
			return 4
		3:
			return 10
		2:
			return 9
		12:
			return 7
		11:
			return 6
		10:
			return 5
		6:
			return 3
		5:
			return 2
		_:
			return 1


func envido_value() -> int:
	var n := effective_number()
	return 0 if n >= 10 else n


func key() -> String:
	return "%d_%s" % [number, Suit.keys()[suit]]
