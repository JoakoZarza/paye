extends GutTest

const H := preload("res://tests/cheats/cheat_test_helpers.gd")

var _defs: Dictionary


func before_all() -> void:
	_defs = AmuletDef.load_all()


func _system(ids: Array, s := 3) -> AmuletSystem:
	var loadout := Loadout.new()
	for id in ids:
		loadout.equip(_defs[StringName(id)])
	var rng := RandomNumberGenerator.new()
	rng.seed = s + 7
	var sys := AmuletSystem.new(H.table(H.profile(0.0, 0, 0.0), s), loadout, rng)
	sys.start_match()
	return sys


func _cards() -> Array:
	return [H.cards([[H.O, 7], [H.O, 6], [H.C, 4]]), H.cards([[H.E, 1], [H.E, 5], [H.B, 6]])]


func _types(events: Array[GameEvent]) -> Array:
	return events.map(func(e: GameEvent) -> StringName: return e.type)


func test_marcador_cambia_el_numero_y_gasta_carga() -> void:
	var sys := _system(["marker"])
	sys.start_hand(-1, _cards(), 0)
	assert_has(_types(sys.use(&"marker", {"card_index": 2, "number": 5})), &"amulet_used")
	assert_eq(sys.table.truco_match.hand.cards[0][2].effective_number(), 5)
	assert_eq(sys.loadout.charges_left(&"marker"), 0)


func test_marcador_invalido_no_gasta() -> void:
	var sys := _system(["marker"])
	sys.start_hand(-1, _cards(), 0)
	assert_eq(sys.use(&"marker", {"card_index": 1, "number": 7})[0].type, &"illegal_action")
	assert_eq(sys.loadout.charges_left(&"marker"), 1)


func test_mazo_aparte_cambia_una_carta() -> void:
	var sys := _system(["spare_deck"])
	sys.start_hand(-1, _cards(), 0)
	var events := sys.use(&"spare_deck", {"card_index": 0})
	var card: Card = events[0].data["card"]
	var keys := ["7_ORO", "6_ORO", "4_COPA", "1_ESPADA", "5_ESPADA", "6_BASTO"]
	assert_false(card.key() in keys, "la carta nueva no puede estar en la mesa")
	assert_eq(sys.table.truco_match.hand.cards[0][0].key(), card.key())
	assert_eq(sys.loadout.charges_left(&"spare_deck"), 1)


func test_vaso_prende_la_bandera_y_sube_la_sospecha() -> void:
	var sys := _system(["cana_glass"])
	sys.start_hand(-1, _cards(), 0)
	sys.use(&"cana_glass")
	assert_true(sys.table.rules.skip_next_show)
	assert_almost_eq(sys.table.brain.mood.suspicion, AmuletSystem.GLASS_SUSPICION, 0.0001)


func test_rosario_anula_el_canto_del_dealer() -> void:
	for s in 60:
		var sys := _system(["rosary"], s)
		sys.start_hand(-1, _cards(), 0)
		sys.table.player_action(TrucoAction.make(H.T.PLAY_CARD, 0, 2))
		sys.table.dealer_step()
		var hand := sys.table.truco_match.hand
		if hand.phase != TrucoHand.Phase.TRUCO_RESPONSE and hand.phase != TrucoHand.Phase.ENVIDO_RESPONSE:
			assert_false(sys.can_use(&"rosary"))
			continue
		assert_has(_types(sys.use(&"rosary")), &"amulet_used")
		assert_eq(hand.phase, TrucoHand.Phase.PLAYING)
		assert_eq(hand.current_player(), 1)
		return
	fail_test("el dealer nunca cantó en 60 manos")


func test_facon_prende_la_bandera_una_vez() -> void:
	var sys := _system(["facon"])
	sys.start_hand(-1, _cards(), 0)
	sys.use(&"facon")
	assert_true(sys.table.rules.force_accept_next_call)
	assert_false(sys.can_use(&"facon"))


func test_facon_y_rosario_no_se_pisan() -> void:
	var sys := _system(["facon", "rosary"])
	sys.start_hand(-1, _cards(), 0)
	sys.use(&"facon")
	assert_false(sys.can_use(&"rosary"))
	assert_true(sys.table.rules.force_accept_next_call)
	sys.table.player_action(TrucoAction.make(H.T.TRUCO, 0))
	assert_eq(sys.table.dealer_step()[0].type, &"call_accepted")


func test_sombrero_revela_solo_numeros() -> void:
	var sys := _system(["hat"])
	sys.start_hand(-1, _cards(), 0)
	var e: GameEvent = sys.use(&"hat")[0]
	assert_eq(e.type, &"amulet_info")
	assert_eq(e.data["numbers"], [1, 5, 6])
	assert_false(e.data.has("cards"))


func test_lentes_revelan_un_numero_por_mano() -> void:
	var sys := _system(["glasses"])
	var events := sys.start_hand(-1, _cards(), 0)
	var info: Array = events.filter(func(e: GameEvent) -> bool: return e.type == &"amulet_info")
	assert_eq(info.size(), 1)
	assert_eq(info[0].data["numbers"].size(), 1)
	assert_true(info[0].data["numbers"][0] in [1, 5, 6])


func test_espejo_pasa_por_la_trampa_del_jugador() -> void:
	var sys := _system(["mirror"])
	sys.start_hand(-1, _cards(), 0)
	var types := _types(sys.use(&"mirror"))
	assert_true(&"player_cheat_info" in types or &"player_caught" in types)
	assert_eq(sys.loadout.charges_left(&"mirror"), 1)


func test_cartas_marcadas_pasan_por_la_trampa_del_jugador() -> void:
	var sys := _system(["marked_cards"])
	sys.start_hand(-1, _cards(), 0)
	var types := _types(sys.use(&"marked_cards"))
	assert_true(&"player_cheat_info" in types or &"player_caught" in types)


func test_cigarrillo_prende_la_regla() -> void:
	assert_true(_system(["cigarette"]).table.rules.cigarette)
	assert_false(_system(["glasses"]).table.rules.cigarette)


func test_sin_cargas_es_ilegal_y_no_gasta() -> void:
	var sys := _system(["hat"])
	sys.start_hand(-1, _cards(), 0)
	sys.use(&"hat")
	assert_eq(sys.use(&"hat")[0].type, &"illegal_action")
	assert_eq(sys.loadout.charges_left(&"hat"), 0)


func test_amuleto_no_equipado_es_ilegal() -> void:
	var sys := _system(["hat"])
	sys.start_hand(-1, _cards(), 0)
	assert_eq(sys.use(&"mirror")[0].type, &"illegal_action")


func test_pasivo_no_se_usa() -> void:
	var sys := _system(["glasses"])
	sys.start_hand(-1, _cards(), 0)
	assert_eq(sys.use(&"glasses")[0].type, &"illegal_action")


func test_mano_terminada_es_ilegal() -> void:
	var sys := _system(["hat"])
	sys.start_hand(-1, _cards(), 0)
	sys.table.player_action(TrucoAction.make(H.T.MAZO, 0))
	assert_eq(sys.use(&"hat")[0].type, &"illegal_action")
	assert_eq(sys.loadout.charges_left(&"hat"), 1)


func test_cargas_se_reponen_por_partido() -> void:
	var sys := _system(["hat"])
	sys.start_hand(-1, _cards(), 0)
	sys.use(&"hat")
	sys.start_match()
	assert_eq(sys.loadout.charges_left(&"hat"), 1)
