extends GutTest


func test_cada_acusacion_matchea_su_trampa() -> void:
	var sleeve := Cheat.make(Cheat.Kind.SLEEVE)
	var duplicate := Cheat.make(Cheat.Kind.DUPLICATE, "card-1")
	duplicate.evidence_visible = true
	var accomplice := Cheat.make(Cheat.Kind.ACCOMPLICE)

	assert_true(Accusation.make(Accusation.Target.DEALER_HAND).matches(sleeve))
	assert_true(Accusation.make(Accusation.Target.HISTORY_CARD, "card-1").matches(duplicate))
	assert_true(Accusation.make(Accusation.Target.ACCOMPLICE).matches(accomplice))


func test_duplicada_sin_evidencia_no_matchea() -> void:
	var duplicate := Cheat.make(Cheat.Kind.DUPLICATE, "card-1")
	assert_false(Accusation.make(Accusation.Target.HISTORY_CARD, "card-1").matches(duplicate))


func test_carta_equivocada_no_matchea() -> void:
	var duplicate := Cheat.make(Cheat.Kind.DUPLICATE, "card-1")
	duplicate.evidence_visible = true
	assert_false(Accusation.make(Accusation.Target.HISTORY_CARD, "card-2").matches(duplicate))


func test_trampa_nula_no_matchea() -> void:
	assert_false(Accusation.make(Accusation.Target.DEALER_HAND).matches(null))
