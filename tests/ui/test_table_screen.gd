extends GutTest
## La mesa se juega apretando botones, nunca llamando al núcleo (Plan 6, Tarea 3).

const META_PATH := "user://test_meta_table_ui.json"
const SCENE := preload("res://ui/screens/table_screen.tscn")
const MAX_PRESSES := 3000

var _economy: Economy


func before_all() -> void:
	_economy = Economy.load_from()


func after_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(META_PATH))


func _screen(seed := 4) -> Array:
	var rc := RunController.new(_economy, MetaState.new(), seed, META_PATH)
	rc.start_run(&"normal")
	rc.enter_match()
	var screen: Control = SCENE.instantiate()
	add_child_autofree(screen)
	screen.setup(rc)
	return [rc, screen]


func _buttons(node: Node) -> Array[Button]:
	var out: Array[Button] = []
	for c in node.get_children():
		if c is Button:
			out.append(c)
		out.append_array(_buttons(c))
	return out


func _enabled(screen: Node) -> Array[Button]:
	var out: Array[Button] = []
	for b in _buttons(screen):
		if not b.disabled and b.is_visible_in_tree() and not b.name.begins_with("Acc") \
				and not b.name.begins_with("Amulet") and not b.name.begins_with("Accuse"):
			out.append(b)
	return out


func test_se_juega_un_partido_entero_con_botones() -> void:
	var pair := _screen()
	var rc: RunController = pair[0]
	var screen: Control = pair[1]
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var presses := 0
	while rc.phase == RunController.Phase.MATCH and presses < MAX_PRESSES:
		presses += 1
		if rc.table().is_dealer_turn() and not screen._hand_finished():
			screen._on_dealer_timer()
			continue
		var options := _enabled(screen)
		assert_false(options.is_empty(), "sin botones para seguir")
		if options.is_empty():
			return
		options[rng.randi_range(0, options.size() - 1)].pressed.emit()
	assert_lt(presses, MAX_PRESSES, "el partido no terminó")
	assert_ne(rc.phase, RunController.Phase.MATCH)


func test_en_el_turno_del_dealer_no_hay_botones_del_jugador() -> void:
	for seed in 20:
		var pair := _screen(seed)
		var rc: RunController = pair[0]
		var screen: Control = pair[1]
		if not rc.table().is_dealer_turn():
			continue
		for b in _buttons(screen):
			if b.name.begins_with("Card") or b.name.begins_with("Act_") or b.name.begins_with("Amulet"):
				assert_true(b.disabled, "%s prendido en el turno del dealer" % b.name)
		return
	fail_test("ninguna semilla empezó con el dealer")


func test_las_cartas_del_rival_no_se_ven() -> void:
	var pair := _screen()
	var rc: RunController = pair[0]
	var screen: Control = pair[1]
	var dealer_cards: Array = rc.table().truco_match.hand.cards[1]
	for c: Card in dealer_cards:
		var text: String = screen.card_text(c)
		for l in screen._dealer_row.get_children():
			assert_ne((l as Label).text, text)
	assert_eq(screen._dealer_row.get_child_count(), dealer_cards.size())

func test_al_irse_el_rival_sin_mostrar_no_se_pregunta_nada() -> void:
	var pair := _screen()
	var rc: RunController = pair[0]
	var screen: Control = pair[1]
	var m := rc.table().truco_match
	var cards := [[Card.new(Card.Suit.ESPADA, 4), Card.new(Card.Suit.BASTO, 5), Card.new(Card.Suit.COPA, 6)],
		[Card.new(Card.Suit.ORO, 7), Card.new(Card.Suit.ORO, 6), Card.new(Card.Suit.COPA, 4)]]
	m.start_hand_with(cards, 0)
	m.apply(TrucoAction.make(TrucoAction.Type.ENVIDO, 0))
	m.apply(TrucoAction.make(TrucoAction.Type.QUIERO, 1))
	m.apply(TrucoAction.make(TrucoAction.Type.DECLARE_TANTO, 0, -1, 20))
	m.apply(TrucoAction.make(TrucoAction.Type.DECLARE_TANTO, 1, -1, 33))
	m.apply(TrucoAction.make(TrucoAction.Type.PLAY_CARD, 0, 0))
	m.apply(TrucoAction.make(TrucoAction.Type.MAZO, 1))
	screen.refresh()
	var names: Array = _enabled(screen).map(func(b: Button) -> String: return b.name)
	assert_has(names, "Act_DEMAND_SHOW")
	assert_has(names, "Continue")
	assert_does_not_have(names, "Act_ACCEPT_TANTO")
	screen.find_child("Continue", true, false).pressed.emit()
	assert_eq(m.scores, [1, 2], "seguir de largo es olvidarse: el rival cobra su envido")
