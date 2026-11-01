class_name HandView
extends RefCounted
## Lo que un jugador puede ver de una mano: sus cartas, lo jugado y lo cantado.
## Nunca las cartas en mano del rival ni su tanto real, salvo lo que una trampa
## deje en known_opponent_cards.

var me: int
## Cartas del rival conocidas por una trampa (cómplice). Vacía si no hay.
var known_opponent_cards: Array[Card] = []

var _hand: TrucoHand


func _init(p_hand: TrucoHand, p_me: int) -> void:
	_hand = p_hand
	me = p_me


func my_cards() -> Array[Card]:
	var out: Array[Card] = []
	out.assign(_hand.cards[me])
	return out


func played(p: int) -> Array[Card]:
	var out: Array[Card] = []
	out.assign(_hand.played[p])
	return out


func baza_results() -> Array[int]:
	return _hand.baza_results.duplicate()


func phase() -> TrucoHand.Phase:
	return _hand.phase


func mano() -> int:
	return _hand.mano


func current_player() -> int:
	return _hand.current_player()


func legal_actions() -> Array[TrucoAction]:
	return _hand.legal_actions()


func truco_level() -> int:
	return _hand.truco_level()


func declared_tanto(p: int) -> int:
	return _hand.declared_tanto(p)


func my_tanto() -> int:
	return _hand.own_tanto(me)


func opponent_card_count() -> int:
	return _hand.cards[1 - me].size()


## Quién ganó el envido (provisorio, antes de mostrar); -1 si nadie.
func envido_winner() -> int:
	return _hand.envido_winner()
