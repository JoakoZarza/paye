class_name GameEvent
extends RefCounted
## Evento producido por la lógica del juego.

var type: StringName
var data: Dictionary


static func make(p_type: StringName, p_data: Dictionary = {}) -> GameEvent:
	var event := GameEvent.new()
	event.type = p_type
	event.data = p_data
	return event
