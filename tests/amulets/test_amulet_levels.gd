extends GutTest
## Efectos de los amuletos mejorados (DISENO §8.1).

const H := preload("res://tests/cheats/cheat_test_helpers.gd")
const T := TrucoAction.Type

var _defs: Dictionary


func before_all() -> void:
	_defs = AmuletDef.load_all()


## levels: {id: nivel}; los que no están quedan en nivel I.
func _system(ids: Array, levels: Dictionary = {}, s := 3) -> AmuletSystem:
	var loadout := Loadout.new()
	for id in ids:
		loadout.equip(_defs[StringName(id)])
		for i in int(levels.get(id, 1)) - 1:
			loadout.upgrade(StringName(id))
	var rng := RandomNumberGenerator.new()
	rng.seed = s + 7
	var sys := AmuletSystem.new(H.table(H.profile(0.0, 0, 0.0), s), loadout, rng)
	sys.start_match()
	return sys


func _cards() -> Array:
	return [H.cards([[H.O, 7], [H.O, 6], [H.C, 4]]), H.cards([[H.E, 1], [H.E, 5], [H.B, 6]])]


func _info(events: Array[GameEvent]) -> GameEvent:
	for e in events:
		if e.type == &"amulet_info":
			return e
	return null


func test_cargas_por_nivel() -> void:
	var sys := _system(["rosary", "marker"], {"rosary": 3, "marker": 2})
	assert_eq(sys.loadout.charges_left(&"rosary"), 3)
	assert_eq(sys.loadout.charges_left(&"marker"), 2)


func test_marcador_iii_cambia_el_palo() -> void:
	var sys := _system(["marker"], {"marker": 3})
	sys.start_hand(-1, _cards(), 0)
	assert_eq(sys.use(&"marker", {"card_index": 2, "number": 7, "suit": H.O})[0].type, &"illegal_action",
		"no puede copiar su propio 7 de oro")
	assert_true(sys.table.truco_match.hand.can_mark(0, 2, 5, H.E), "no delata el 5 de espada escondido del rival")
	assert_eq(sys.use(&"marker", {"card_index": 2, "number": 5, "suit": H.B})[0].type, &"amulet_used")
	var card: Card = sys.table.truco_match.hand.cards[0][2]
	assert_eq(card.effective_number(), 5)
	assert_eq(card.effective_suit(), H.B)


func test_marcador_i_no_cambia_el_palo() -> void:
	var sys := _system(["marker"])
	sys.start_hand(-1, _cards(), 0)
	assert_eq(sys.use(&"marker", {"card_index": 2, "number": 5, "suit": H.B})[0].type, &"illegal_action")
	assert_eq(sys.loadout.charges_left(&"marker"), 1)


func test_mazo_aparte_iii_elige_entre_dos() -> void:
	var sys := _system(["spare_deck"], {"spare_deck": 3})
	sys.start_hand(-1, _cards(), 0)
	var options := sys.preview_spare()
	assert_eq(options.size(), 2)
	assert_ne(options[0].key(), options[1].key())
	assert_eq(sys.preview_spare()[1].key(), options[1].key(), "las opciones no cambian antes de usarlo")
	var events := sys.use(&"spare_deck", {"card_index": 0, "choice": 1})
	assert_eq(events[0].data["card"].key(), options[1].key())
	assert_eq(sys.table.truco_match.hand.cards[0][0].key(), options[1].key())
	assert_eq(sys.use(&"spare_deck", {"card_index": 0, "choice": 5})[0].type, &"illegal_action")


func test_mazo_aparte_i_no_ofrece_elegir() -> void:
	var sys := _system(["spare_deck"])
	sys.start_hand(-1, _cards(), 0)
	assert_eq(sys.preview_spare().size(), 0)
	assert_eq(sys.use(&"spare_deck", {"card_index": 0})[0].type, &"amulet_used")


func _forced_answers(level: int) -> Array:
	var sys := _system(["facon"], {"facon": level})
	var t := sys.table
	sys.start_hand(-1, _cards(), 0)
	sys.use(&"facon")
	t.player_action(TrucoAction.make(T.TRUCO, 0))
	var out := []
	for i in 3:
		out.append(t._apply_rules(TrucoAction.make(T.NO_QUIERO, 1)).type)
	return out


func test_facon_iii_obliga_tambien_la_subida() -> void:
	assert_eq(_forced_answers(3), [T.QUIERO, T.QUIERO, T.NO_QUIERO])
	assert_eq(_forced_answers(1), [T.QUIERO, T.NO_QUIERO, T.NO_QUIERO])


func test_lentes_ii_muestran_dos_numeros() -> void:
	var sys := _system(["glasses"], {"glasses": 2})
	var e := _info(sys.start_hand(-1, _cards(), 0))
	assert_eq(e.data["numbers"].size(), 2)
	assert_false(e.data.has("suits"))


func test_lentes_iii_muestran_numero_y_palo() -> void:
	var sys := _system(["glasses"], {"glasses": 3})
	var e := _info(sys.start_hand(-1, _cards(), 0))
	assert_eq(e.data["numbers"].size(), 1)
	assert_eq(e.data["suits"].size(), 1)
	var dealer: Array = sys.table.truco_match.hand.cards[1]
	var found: bool = dealer.any(func(c: Card) -> bool:
		return c.effective_number() == e.data["numbers"][0] and c.effective_suit() == e.data["suits"][0])
	assert_true(found)


func test_sombrero_iii_muestra_el_palo_de_la_mas_alta() -> void:
	var sys := _system(["hat"], {"hat": 3})
	sys.start_hand(-1, _cards(), 0)
	var e := _info(sys.use(&"hat"))
	assert_eq(e.data["best_suit"], H.E)
	var plain := _system(["hat"])
	plain.start_hand(-1, _cards(), 0)
	assert_false(_info(plain.use(&"hat")).data.has("best_suit"))


func test_vaso_iii_no_sube_la_sospecha() -> void:
	var sys := _system(["cana_glass"], {"cana_glass": 3})
	sys.start_hand(-1, _cards(), 0)
	sys.use(&"cana_glass")
	assert_true(sys.table.rules.skip_next_show)
	assert_eq(sys.table.brain.mood.suspicion, 0.0)


func test_reglas_de_la_mesa_siguen_el_nivel() -> void:
	var sys := _system(["cigarette", "mirror"], {"cigarette": 3, "mirror": 2})
	assert_almost_eq(sys.table.rules.cigarette_chance, 0.2, 0.0001)
	assert_almost_eq(sys.table.rules.mirror_risk_multiplier, 0.7, 0.0001)
	var marked := _system(["marked_cards"], {"marked_cards": 2})
	assert_almost_eq(marked.table.rules.marked_step_multiplier, 0.5, 0.0001)
	var plain := _system(["cigarette"])
	assert_almost_eq(plain.table.rules.cigarette_chance, 0.5, 0.0001)


## Veces que el dealer igual pide mostrar un tanto mentido, sobre 400 manos.
func _shows_demanded(level: int) -> int:
	var sys := _system(["cigarette"], {"cigarette": level})
	var t := sys.table
	var shows := 0
	for i in 400:
		sys.start_hand(-1, [H.cards([[H.O, 7], [H.C, 6], [H.B, 4]]), H.cards([[H.E, 1], [H.E, 5], [H.B, 6]])], 0)
		var m := t.truco_match
		m.apply(TrucoAction.make(T.ENVIDO, 0))
		m.apply(TrucoAction.make(T.QUIERO, 1))
		m.apply(TrucoAction.make(T.DECLARE_TANTO, 0, -1, 33))
		m.apply(TrucoAction.make(T.SON_BUENAS, 1))
		# La verificación del tanto llega al terminar la mano.
		m.apply(TrucoAction.make(T.MAZO, m.hand.current_player()))
		assert_eq(m.hand.phase, TrucoHand.Phase.SHOW_DECISION)
		if t._apply_rules(TrucoAction.make(T.DEMAND_SHOW, 1)).type == T.DEMAND_SHOW:
			shows += 1
	return shows


func test_cigarrillo_mejorado_frena_mas_pedidos() -> void:
	var level_1 := _shows_demanded(1)
	var level_3 := _shows_demanded(3)
	assert_almost_eq(float(level_1), 200.0, 40.0, "nivel I: pide mostrar la mitad de las veces")
	assert_almost_eq(float(level_3), 80.0, 30.0, "nivel III: pide mostrar el 20% de las veces")

func test_facon_iii_no_pasa_a_la_mano_siguiente() -> void:
	var sys := _system(["facon"], {"facon": 3})
	var t := sys.table
	sys.start_hand(-1, _cards(), 0)
	sys.use(&"facon")
	t.player_action(TrucoAction.make(T.TRUCO, 0))
	assert_eq(t._apply_rules(TrucoAction.make(T.NO_QUIERO, 1)).type, T.QUIERO)
	sys.start_hand(-1, _cards(), 1)
	assert_false(t.rules.force_accept_next_call)
	assert_eq(t.rules.force_accept_extra, 0)