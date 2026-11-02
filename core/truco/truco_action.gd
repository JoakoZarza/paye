class_name TrucoAction
extends RefCounted
## Acción de un jugador enviada a la lógica de una mano.

enum Type { PLAY_CARD, ENVIDO, REAL_ENVIDO, FALTA_ENVIDO, TRUCO, RETRUCO, VALE_CUATRO, QUIERO, NO_QUIERO, DECLARE_TANTO, SON_BUENAS, DEMAND_SHOW, ACCEPT_TANTO, MAZO, SHOW_TANTO }

var type: Type
var player: int
var card_index: int = -1
var value: int = -1


static func make(p_type: Type, p_player: int, p_card_index: int = -1, p_value: int = -1) -> TrucoAction:
	var action := TrucoAction.new()
	action.type = p_type
	action.player = p_player
	action.card_index = p_card_index
	action.value = p_value
	return action


func equals(o: TrucoAction) -> bool:
	return type == o.type and player == o.player and card_index == o.card_index and value == o.value
