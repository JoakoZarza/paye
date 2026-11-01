class_name Accusation extends RefCounted
## Evidencia a la que apunta una acusación.

enum Target { DEALER_HAND, HISTORY_CARD, ACCOMPLICE }

var target: Target
var card_key: String = ""


static func make(p_target: Target, p_card_key: String = "") -> Accusation:
	var accusation := Accusation.new()
	accusation.target = p_target
	accusation.card_key = p_card_key
	return accusation


func matches(c: Cheat) -> bool:
	if c == null:
		return false
	match target:
		Target.DEALER_HAND:
			return c.kind == Cheat.Kind.SLEEVE
		Target.HISTORY_CARD:
			return c.kind == Cheat.Kind.DUPLICATE and card_key == c.card_key and c.evidence_visible
		Target.ACCOMPLICE:
			return c.kind == Cheat.Kind.ACCOMPLICE
	return false
