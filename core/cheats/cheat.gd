class_name Cheat extends RefCounted
## Trampa activa del dealer y su evidencia.

enum Kind { SLEEVE, DUPLICATE, ACCOMPLICE }

var kind: Kind
var card_key: String = ""
var evidence_visible: bool = false


static func make(p_kind: Kind, p_card_key: String = "") -> Cheat:
	var cheat := Cheat.new()
	cheat.kind = p_kind
	cheat.card_key = p_card_key
	return cheat
